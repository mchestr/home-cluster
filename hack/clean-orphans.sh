#!/bin/bash
#./clean-orphans.sh <namespace>
# Fixes error "unable to fetch certificate that owns the secret" in cert-manager
set -e
NAMESPACE=$1

# If no namespace specified, set it to default
if [[ $# -lt 1 ]] ; then
    NAMESPACE="default"
fi

# TODO: whitelist certs that should never be removed? i.e. default le-cert? For now we'll just prompt before deleting to be safe

SECRETS=($(kubectl --namespace $NAMESPACE get secrets | grep tls | awk '{print $1}'))  # Array of all secrets in the namespace
CERTS=($(kubectl --namespace $NAMESPACE get certs | grep True | awk '{print $1}'))  # Array of all certs in the namespace

echo "Listing (cert-manager) certs:"
for i in ${CERTS[@]}; do
        echo $i
done
echo

echo "Listing TLS secrets:"
for i in ${SECRETS[@]}; do
        echo $i
done
echo

# Check if any orphaned secrets were detected
ORPHANS=($(comm -23 <(for x in "${SECRETS[@]}"; do echo "$x"; done | sort) <(for x in "${CERTS[@]}"; do echo "$x"; done | sort)))

if [ ${#ORPHANS[@]} -eq 0 ]; then
    echo "No orphaned secrets detected."
    exit 0
fi

echo "Detected orphaned secrets:"
for i in ${ORPHANS[@]}; do
        echo $i
done
# comm -23 \
#     <(for x in "${SECRETS[@]}"; do echo "$x"; done | sort) \
#     <(for x in "${CERTS[@]}"; do echo "$x"; done | sort)
echo

# Prompt to cleanup
read -p "Would you like to delete the orphaned secrets listed above?" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi
echo

for i in ${ORPHANS[@]}; do
        echo "Deleting orphaned secret $i"
        kubectl -n $NAMESPACE delete secret $i
done
