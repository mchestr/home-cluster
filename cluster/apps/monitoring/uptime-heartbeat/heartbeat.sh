#!/usr/bin/env sh

if [[ -z "${HEARTBEAT_URL}" ]]; then
    printf "%s - Error - Missing HEARTBEAT_URL environment variable" "$(date -u)"
    exit 0
fi

status_code=$(curl --connect-timeout 10 --max-time 30 -I -s -o /dev/null -w '%{http_code}' "${HEARTBEAT_URL}")
if [[ ! ${status_code} =~ ^[2|3][0-9]{2}$ ]]; then
    printf "%s - Error - Heartbeat request failed, http code: %s" "$(date -u)" "${status_code}"
    exit 0
fi

printf "%s - Ok - Heartbeat request received and processed successfully" "$(date -u)"
exit 0
