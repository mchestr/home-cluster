#!/bin/sh

if [[ -z "${HEARTBEAT_URL}" ]]; then
    printf "%s - Error - Missing HEARTBEAT_URL environment variable" "$(date -u)"
    exit 0
fi

wget -qS -T 10 -O /dev/null  "${HEARTBEAT_URL}"
