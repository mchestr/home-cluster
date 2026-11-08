#!/usr/bin/env bash
# Prints a fingerprint of what the risk assessment of HEAD depends on: the
# change itself, the apps and files it touches as they stand on HEAD, its
# rendered diff, the flate test result, and the review instructions and
# model. A rebase onto main that leaves all of these as they were leaves the
# fingerprint as it was, so the assessment the change got still holds.
# Prints nothing and fails when any of them can't be read.
#
# Usage: fingerprint.sh <flate results directory> <flate test result>
set -euo pipefail
shopt -s inherit_errexit

flate_dir="$1"
flate_result="$2"
base=$(git merge-base origin/main HEAD)

inputs=$(
    echo "flate test: ${flate_result}"
    echo "model: ${CLAUDE_MODEL:-}"
    # The review instructions, prompt additions, output schema and report
    for path in .claude/skills/renovate-review .github/renovate-risk; do
        echo "${path} $(git rev-parse --verify "HEAD:${path}")"
    done
    # The change, whichever commit of main it sits on
    git diff "${base}" HEAD | git patch-id --stable | cut -d' ' -f1
    # Every app the change touches, whole, and every other file it touches,
    # so a change on main to the same app or file counts
    git diff --name-only "${base}" HEAD \
        | sed -E 's#^(kubernetes/apps/[^/]+/[^/]+)/.*#\1#' \
        | sort -u \
        | while read -r path; do
            echo "${path} $(git rev-parse --verify --quiet "HEAD:${path}" || echo deleted)"
        done
    # What the change does to the rendered cluster. Without the rendered diff
    # there's no telling whether that changed.
    for name in diff-helmrelease.patch diff-kustomization.patch; do
        if [[ ! -f "${flate_dir}/${name}" ]]; then
            echo "fingerprint: no ${name} in ${flate_dir}" >&2
            exit 1
        fi
        echo "${name} $(sha256sum < "${flate_dir}/${name}" | cut -d' ' -f1)"
    done
)
sha256sum <<< "${inputs}" | cut -d' ' -f1
