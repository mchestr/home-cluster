#!/usr/bin/env bash

set -o errexit
set -o pipefail

# shellcheck disable=SC2155
export PROJECT_DIR=$(git rev-parse --show-toplevel)

# shellcheck disable=SC2155
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt

# shellcheck disable=SC1091
source "${PROJECT_DIR}/.config.env"

show_help() {
cat << EOF
Usage: $(basename "$0") <options>
    -h, --help                      Display help
    --verify                        Verify .config.env settings
EOF
}

main() {
    local verify=

    parse_command_line "$@"

    verify_binaries

    if [[ "${verify}" == 1 ]]; then
        verify_ansible_hosts
        verify_metallb
        verify_kubevip
        verify_addressing
        verify_age
        verify_git_repository
        verify_cloudflare
        verify_success
    else
        # generate sops configuration file
        envsubst < "${PROJECT_DIR}/tmpl/.sops.yaml" \
            > "${PROJECT_DIR}/.sops.yaml"
        # generate cluster settings
        envsubst < "${PROJECT_DIR}/tmpl/cluster/cluster-settings.yaml" \
            > "${PROJECT_DIR}/cluster/base/cluster-settings.yaml"
        envsubst < "${PROJECT_DIR}/tmpl/cluster/gotk-sync.yaml" \
            > "${PROJECT_DIR}/cluster/base/flux-system/gotk-sync.yaml"
        envsubst < "${PROJECT_DIR}/tmpl/cluster/kube-vip-daemonset.yaml" \
            > "${PROJECT_DIR}/cluster/core/kube-system/kube-vip/daemon-set.yaml"
        # generate cluster secrets
        envsubst < "${PROJECT_DIR}/tmpl/cluster/cluster-secrets.sops.yaml" \
            > "${PROJECT_DIR}/cluster/base/cluster-secrets.sops.yaml"
        envsubst < "${PROJECT_DIR}/tmpl/cluster/cert-manager-secret.sops.yaml" \
            > "${PROJECT_DIR}/cluster/core/cert-manager/secret.sops.yaml"
        envsubst < "${PROJECT_DIR}/tmpl/cluster/cloudflare-ddns-secret.sops.yaml" \
            > "${PROJECT_DIR}/cluster/apps/networking/cloudflare-ddns/secret.sops.yaml"
        envsubst < "${PROJECT_DIR}/tmpl/cluster/external-dns-secret.sops.yaml" \
            > "${PROJECT_DIR}/cluster/apps/networking/external-dns/secret.sops.yaml"
        # encrypt cluster secrets
        sops --encrypt --in-place "${PROJECT_DIR}/cluster/base/cluster-secrets.sops.yaml"
        sops --encrypt --in-place "${PROJECT_DIR}/cluster/core/cert-manager/secret.sops.yaml"
        sops --encrypt --in-place "${PROJECT_DIR}/cluster/apps/networking/cloudflare-ddns/secret.sops.yaml"
        sops --encrypt --in-place "${PROJECT_DIR}/cluster/apps/networking/external-dns/secret.sops.yaml"
        # generate terraform secrets
        envsubst < "${PROJECT_DIR}/tmpl/terraform/secret.sops.yaml" \
            > "${PROJECT_DIR}/provision/terraform/cloudflare/secret.sops.yaml"
        # encrypt terraform secrets
        sops --encrypt --in-place "${PROJECT_DIR}/provision/terraform/cloudflare/secret.sops.yaml"
        # generate ansible settings
        envsubst < "${PROJECT_DIR}/tmpl/ansible/kube-vip.yml" \
            > "${PROJECT_DIR}/provision/ansible/inventory/group_vars/kubernetes/kube-vip.yml"
        # generate ansible hosts file and secrets
        generate_ansible_hosts
        generate_ansible_host_secrets
        setup_github_webhook
        success
    fi
}

parse_command_line() {
    while :; do
        case "${1:-}" in
            -h|--help)
                show_help
                exit
                ;;
            --verify)
                verify=1
                ;;
            *)
                break
                ;;
        esac

        shift
    done

    if [[ -z "$verify" ]]; then
        verify=0
    fi
}

_has_binary() {
    command -v "${1}" >/dev/null 2>&1 || {
        _log "ERROR" "${1} is not installed or not found in \$PATH"
        exit 1
    }
}

_has_optional_envar() {
    local option="${1}"
    # shellcheck disable=SC2015
    [[ "${!option}" == "" ]] && {
        _log "WARN" "Unset optional variable ${option}"
    } || {
        _log "INFO" "Found variable '${option}' with value '${!option}'"
    }
}

_has_envar() {
    local option="${1}"
    # shellcheck disable=SC2015
    [[ "${!option}" == "" ]] && {
        _log "ERROR" "Unset variable ${option}"
        exit 1
    } || {
        _log "INFO" "Found variable '${option}' with value '${!option}'"
    }
}

_has_valid_ip() {
    local ip="${1}"
    local variable_name="${2}"

    if ! ipcalc "${ip}" | awk 'BEGIN{FS=":"; is_invalid=0} /^INVALID/ {is_invalid=1; print $1} END{exit is_invalid}' >/dev/null 2>&1; then
        _log "INFO" "Variable '${variable_name}' has an invalid IP address '${ip}'"
        exit 1
    else
        _log "INFO" "Variable '${variable_name}' has a valid IP address '${ip}'"
    fi
}

verify_addressing() {
    local found_kube_vip="false"
    local found_k8s_gateway="false"
    local found_traefik="false"

    # Verify the metallb min and metallb ceiling are in the same network
    metallb_subnet_min=$(echo "${BOOTSTRAP_METALLB_LB_RANGE}" | cut -d- -f1 | cut -d. -f1,2,3)
    metallb_subnet_ceil=$(echo "${BOOTSTRAP_METALLB_LB_RANGE}" | cut -d- -f2 | cut -d. -f1,2,3)
    if [[ "${metallb_subnet_min}" != "${metallb_subnet_ceil}" ]]; then
        _log "ERROR" "The provided MetalLB IP range '${BOOTSTRAP_METALLB_LB_RANGE}' is not in the same subnet"
        exit 1
    fi

    # Verify the node IP addresses are on the same network as the metallb range
    for var in "${!BOOTSTRAP_ANSIBLE_HOST_ADDR_@}"; do
        node_subnet=$(echo "${!var}" | cut -d. -f1,2,3)
        if [[ "${node_subnet}" != "${metallb_subnet_min}" ]]; then
            _log "ERROR" "The subnet for node '${!var}' is not in the same subnet as the provided metallb range '${BOOTSTRAP_METALLB_LB_RANGE}'"
            exit 1
        fi
    done

    # Verify the kube-vip IP is in the same network as the metallb range
    kubevip_subnet=$(echo "${BOOTSTRAP_KUBE_VIP_ADDR}" | cut -d. -f1,2,3)
    if [[ "${kubevip_subnet}" != "${metallb_subnet_min}" ]]; then
        _log "ERROR" "The subnet for kupe-vip '${BOOTSTRAP_KUBE_VIP_ADDR}' is not the same subnet as the provided metallb range '${BOOTSTRAP_METALLB_LB_RANGE}'"
        exit 1
    fi

    # Depending on the IP address, verify if it should be in the metallb range or not
    metallb_octet_min=$(echo "${BOOTSTRAP_METALLB_LB_RANGE}" | cut -d- -f1 | cut -d. -f4)
    metallb_octet_ceil=$(echo "${BOOTSTRAP_METALLB_LB_RANGE}" | cut -d- -f2 | cut -d. -f4)
    for (( octet=metallb_octet_min; octet<=metallb_octet_ceil; octet++ )); do
        addr="${metallb_subnet_min}.${octet}"
        if [[ "${addr}" == "${BOOTSTRAP_KUBE_VIP_ADDR}" ]]; then
            found_kube_vip="true"
        fi
        if [[ "${addr}" == "${BOOTSTRAP_METALLB_K8S_GATEWAY_ADDR}" ]]; then
            found_k8s_gateway="true"
        fi
        if [[ "${addr}" == "${BOOTSTRAP_METALLB_TRAEFIK_ADDR}" ]]; then
            found_traefik="true"
        fi

        for var in "${!BOOTSTRAP_ANSIBLE_HOST_ADDR_@}"; do
            if [[ "${!var}" == "${addr}" ]]; then
                _log "ERROR" "The IP for node '${!var}' should NOT be in the provided metallb range '${BOOTSTRAP_METALLB_LB_RANGE}'"
                exit 1
            fi
        done
    done

    if [[ "${found_kube_vip}" == "true" ]]; then
        _log "ERROR" "The IP for kube-vip '${BOOTSTRAP_KUBE_VIP_ADDR}' should NOT be in the provided metallb range '${BOOTSTRAP_METALLB_LB_RANGE}'"
        exit 1
    fi

    if [[ "${found_k8s_gateway}" == "false" ]]; then
        _log "ERROR" "The IP for k8s_gateway '${BOOTSTRAP_METALLB_K8S_GATEWAY_ADDR}' should be in the provided metallb range '${BOOTSTRAP_METALLB_LB_RANGE}'"
        exit 1
    fi

    if [[ "${found_traefik}" == "false" ]]; then
        _log "ERROR" "The IP for traefik '${BOOTSTRAP_METALLB_TRAEFIK_ADDR}' should be in the provided metallb range '${BOOTSTRAP_METALLB_LB_RANGE}'"
        exit 1
    fi
}

verify_age() {
    _has_envar "BOOTSTRAP_AGE_PUBLIC_KEY"
    _has_envar "SOPS_AGE_KEY_FILE"

    if [[ ! "$BOOTSTRAP_AGE_PUBLIC_KEY" =~ ^age.* ]]; then
        _log "ERROR" "BOOTSTRAP_AGE_PUBLIC_KEY does not start with age"
        exit 1
    else
        _log "INFO" "Age public key is in the correct format"
    fi

    if [[ ! -f ~/.config/sops/age/keys.txt ]]; then
        _log "ERROR" "Unable to find Age file keys.txt in ~/.config/sops/age"
        exit 1
    else
        _log "INFO" "Found Age public key '${BOOTSTRAP_AGE_PUBLIC_KEY}'"
    fi
}

verify_binaries() {
    _has_binary "ansible"
    _has_binary "envsubst"
    _has_binary "flux"
    _has_binary "git"
    _has_binary "age"
    _has_binary "helm"
    _has_binary "ipcalc"
    _has_binary "jq"
    _has_binary "yq"
    _has_binary "sops"
    _has_binary "ssh"
    _has_binary "task"
    _has_binary "terraform"
}

verify_kubevip() {
    _has_envar "BOOTSTRAP_KUBE_VIP_ADDR"
    _has_valid_ip "${BOOTSTRAP_KUBE_VIP_ADDR}" "BOOTSTRAP_KUBE_VIP_ADDR"
}

verify_metallb() {
    local ip_floor=
    local ip_ceil=
    _has_envar "BOOTSTRAP_METALLB_LB_RANGE"
    _has_envar "BOOTSTRAP_METALLB_K8S_GATEWAY_ADDR"
    _has_envar "BOOTSTRAP_METALLB_TRAEFIK_ADDR"

    ip_floor=$(echo "${BOOTSTRAP_METALLB_LB_RANGE}" | cut -d- -f1)
    ip_ceil=$(echo "${BOOTSTRAP_METALLB_LB_RANGE}" | cut -d- -f2)

    _has_valid_ip "${ip_floor}" "BOOTSTRAP_METALLB_LB_RANGE"
    _has_valid_ip "${ip_ceil}" "BOOTSTRAP_METALLB_LB_RANGE"
    _has_valid_ip "${BOOTSTRAP_METALLB_K8S_GATEWAY_ADDR}" "BOOTSTRAP_METALLB_K8S_GATEWAY_ADDR"
    _has_valid_ip "${BOOTSTRAP_METALLB_TRAEFIK_ADDR}" "BOOTSTRAP_METALLB_TRAEFIK_ADDR"
}

verify_git_repository() {
    _has_envar "BOOTSTRAP_GIT_REPOSITORY"

    export GIT_TERMINAL_PROMPT=0
    pushd "$(mktemp -d)" >/dev/null 2>&1
    [ "$(git ls-remote "${BOOTSTRAP_GIT_REPOSITORY}" 2> /dev/null)" ] || {
        _log "ERROR" "Unable to find the remote Git repository '${BOOTSTRAP_GIT_REPOSITORY}'"
        exit 1
    }
    popd >/dev/null 2>&1
    export GIT_TERMINAL_PROMPT=1
}

setup_github_webhook() {
    WEBHOOK_SECRET="${BOOTSTRAP_FLUX_GITHUB_WEBHOOK_SECRET:-ignored}"

    if [[ "${WEBHOOK_SECRET}" != "ignored" ]]; then
        if [[ "${WEBHOOK_SECRET}" == "generated" ]]; then
            WEBHOOK_SECRET="$(openssl rand -base64 30)"
        fi

        export BOOTSTRAP_FLUX_GITHUB_WEBHOOK_SECRET="${WEBHOOK_SECRET}"
        _log "INFO" "Using GitHub Token '${WEBHOOK_SECRET}' for Flux"

        cp -rf  "${PROJECT_DIR}/tmpl/cluster/flux-system" "${PROJECT_DIR}/cluster/apps/"

        envsubst < "${PROJECT_DIR}/tmpl/cluster/flux-system/webhooks/github/secret.sops.yaml" \
            > "${PROJECT_DIR}/cluster/apps/flux-system/webhooks/github/secret.sops.yaml"

        sops --encrypt --in-place "${PROJECT_DIR}/cluster/apps/flux-system/webhooks/github/secret.sops.yaml"

        if [[ $(yq eval --no-doc 'contains({"resources": ["flux-system"]})' "${PROJECT_DIR}/cluster/apps/kustomization.yaml") == false ]]; then
            yq --inplace '.resources += [ "flux-system" ]' "${PROJECT_DIR}/cluster/apps/kustomization.yaml"
        fi
    fi
}

verify_cloudflare() {
    local account_zone=
    local errors=

    _has_envar "BOOTSTRAP_CLOUDFLARE_APIKEY"
    _has_envar "BOOTSTRAP_CLOUDFLARE_DOMAIN"
    _has_envar "BOOTSTRAP_CLOUDFLARE_EMAIL"

    # Try to retrieve zone information from Cloudflare's API
    account_zone=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${BOOTSTRAP_CLOUDFLARE_DOMAIN}&status=active" \
        -H "X-Auth-Email: ${BOOTSTRAP_CLOUDFLARE_EMAIL}" \
        -H "X-Auth-Key: ${BOOTSTRAP_CLOUDFLARE_APIKEY}" \
        -H "Content-Type: application/json"
    )

    if [[ "$(echo "${account_zone}" | jq ".success")" == "true" ]]; then
        _log "INFO" "Verified Cloudflare Account and Zone information"
    else
        errors=$(echo "${account_zone}" | jq -c ".errors")
        _log "ERROR" "Unable to get Cloudflare Account and Zone information ${errors}"
        exit 1
    fi
}

verify_ansible_hosts() {
    local node_id=
    local node_addr=
    local node_username=
    local node_password=
    local node_control=
    local node_hostname=
    local default_control_node_prefix=
    local default_worker_node_prefix=

    default_control_node_prefix="BOOTSTRAP_ANSIBLE_DEFAULT_CONTROL_NODE_HOSTNAME_PREFIX"
    default_worker_node_prefix="BOOTSTRAP_ANSIBLE_DEFAULT_NODE_HOSTNAME_PREFIX"
    _has_optional_envar "${default_control_node_prefix}"
    _has_optional_envar "${default_worker_node_prefix}"

    for var in "${!BOOTSTRAP_ANSIBLE_HOST_ADDR_@}"; do
        node_id=$(echo "${var}" | awk -F"_" '{print $5}')
        node_addr="BOOTSTRAP_ANSIBLE_HOST_ADDR_${node_id}"
        node_username="BOOTSTRAP_ANSIBLE_SSH_USERNAME_${node_id}"
        node_password="BOOTSTRAP_ANSIBLE_SUDO_PASSWORD_${node_id}"
        node_control="BOOTSTRAP_ANSIBLE_CONTROL_NODE_${node_id}"
        node_hostname="BOOTSTRAP_ANSIBLE_HOSTNAME_${node_id}"
        _has_envar "${node_addr}"
        _has_envar "${node_username}"
        _has_envar "${node_password}"
        _has_envar "${node_control}"
        _has_optional_envar "${node_hostname}"

        if [[ "${!node_addr}" == "${BOOTSTRAP_KUBE_VIP_ADDR}" ]]; then
            _log "ERROR" "The kube-vip IP '${BOOTSTRAP_KUBE_VIP_ADDR}' should not be the same as the IP for node '${!node_addr}'"
            exit 1
        fi

        if [[ "${!node_addr}" == "${BOOTSTRAP_METALLB_K8S_GATEWAY_ADDR}" ]]; then
            _log "ERROR" "The k8s-gateway load balancer IP '${BOOTSTRAP_METALLB_K8S_GATEWAY_ADDR}' should not be the same as the IP for node '${!node_addr}'"
            exit 1
        fi

        if [[ "${!node_addr}" == "${BOOTSTRAP_METALLB_TRAEFIK_ADDR}" ]]; then
            _log "ERROR" "The traefik load balancer IP '${BOOTSTRAP_METALLB_TRAEFIK_ADDR}' should not be the same as the IP for node '${!node_addr}'"
            exit 1
        fi

        if ssh -q -o BatchMode=yes -o ConnectTimeout=5 "${!node_username}"@"${!var}" "true"; then
            _log "INFO" "SSH into host '${!var}' with username '${!node_username}' was successfull"
        else
            _log "ERROR" "SSH into host '${!var}' with username '${!node_username}'was NOT successful, did you copy over your SSH key?"
            exit 1
        fi
    done
}

verify_success() {
    _log "INFO" "All checks passed!"
    _log "INFO" "Run the script without --verify to template all the files out"
    exit 0
}

generate_ansible_host_secrets() {
    local node_id=
    local node_username=
    local node_password=
    local node_hostname=
    default_control_node_prefix=${BOOTSTRAP_ANSIBLE_DEFAULT_CONTROL_NODE_HOSTNAME_PREFIX:-k8s-}
    default_worker_node_prefix=${BOOTSTRAP_ANSIBLE_DEFAULT_NODE_HOSTNAME_PREFIX:-k8s-}
    for var in "${!BOOTSTRAP_ANSIBLE_HOST_ADDR_@}"; do
        node_id=$(echo "${var}" | awk -F"_" '{print $5}')
        if [[ "${!node_control}" == "true" ]]; then
            node_hostname="BOOTSTRAP_ANSIBLE_HOSTNAME_${node_id}"
            host_key="${!node_hostname:-${default_control_node_prefix}}"
            if [ "${host_key}" == "${default_control_node_prefix}" ]; then
                node_hostname=${default_control_node_prefix}${node_id}
            else
                node_hostname=${!node_hostname}
            fi
        else
            node_hostname="BOOTSTRAP_ANSIBLE_HOSTNAME_${node_id}"
            host_key="${!node_hostname:-${default_worker_node_prefix}}"
            if [ "${host_key}" == "${default_worker_node_prefix}" ]; then
                node_hostname=${default_worker_node_prefix}${node_id}
            else
                node_hostname=${!node_hostname}
            fi
        fi
        {
            node_username="BOOTSTRAP_ANSIBLE_SSH_USERNAME_${node_id}"
            node_password="BOOTSTRAP_ANSIBLE_SUDO_PASSWORD_${node_id}"
            printf "kind: Secret\n"
            printf "ansible_user: %s\n" "${!node_username}"
            printf "ansible_become_pass: %s\n" "${!node_password}"
        } > "${PROJECT_DIR}/provision/ansible/inventory/host_vars/${node_hostname}.sops.yml"
        sops --encrypt --in-place "${PROJECT_DIR}/provision/ansible/inventory/host_vars/${node_hostname}.sops.yml"
    done
}

generate_ansible_hosts() {
    local worker_node_count=
    default_control_node_prefix=${BOOTSTRAP_ANSIBLE_DEFAULT_CONTROL_NODE_HOSTNAME_PREFIX:-k8s-}
    default_worker_node_prefix=${BOOTSTRAP_ANSIBLE_DEFAULT_NODE_HOSTNAME_PREFIX:-k8s-}
    {
        printf -- "---\n"
        printf "kubernetes:\n"
        printf "  children:\n"
        printf "    master:\n"
        printf "      hosts:\n"
        master_node_count=0
        worker_node_count=0
        for var in "${!BOOTSTRAP_ANSIBLE_HOST_ADDR_@}"; do
            node_id=$(echo "${var}" | awk -F"_" '{print $5}')
            node_control="BOOTSTRAP_ANSIBLE_CONTROL_NODE_${node_id}"
            if [[ "${!node_control}" == "true" ]]; then
                master_node_count=$((master_node_count+1))
                node_hostname="BOOTSTRAP_ANSIBLE_HOSTNAME_${node_id}"
                host_key="${!node_hostname:-${default_control_node_prefix}}"
                if [ "${host_key}" == "${default_control_node_prefix}" ]; then
                    node_hostname=${default_control_node_prefix}${node_id}
                else
                    node_hostname=${!node_hostname}
                fi
                printf "        %s:\n" "${node_hostname}"
                printf "          ansible_host: %s\n" "${!var}"
            else
                worker_node_count=$((worker_node_count+1))
            fi
        done
        if [[ ${worker_node_count} -gt 0 ]]; then
            printf "    worker:\n"
            printf "      hosts:\n"
            for var in "${!BOOTSTRAP_ANSIBLE_HOST_ADDR_@}"; do
                node_id=$(echo "${var}" | awk -F"_" '{print $5}')
                node_control="BOOTSTRAP_ANSIBLE_CONTROL_NODE_${node_id}"
                if [[ "${!node_control}" == "false" ]]; then
                    node_hostname="BOOTSTRAP_ANSIBLE_HOSTNAME_${node_id}"
                    host_key="${!node_hostname:-${default_worker_node_prefix}}"
                    if [ "${host_key}" == "${default_worker_node_prefix}" ]; then
                        node_hostname=${default_worker_node_prefix}${node_id}
                    else
                        node_hostname=${!node_hostname}
                    fi
                    printf "        %s:\n" "${node_hostname}"
                    printf "          ansible_host: %s\n" "${!var}"
                fi
            done
        fi
    } > "${PROJECT_DIR}/provision/ansible/inventory/hosts.yml"
}

success() {
    _log "INFO" "All files have been templated, proceed to the next steps outlined in the README"
    exit 0
}

_log() {
    local type="${1}"
    local msg="${2}"
    printf "[%s] [%s] %s\n" "$(date -u)" "${type}" "${msg}"
}

main "$@"
