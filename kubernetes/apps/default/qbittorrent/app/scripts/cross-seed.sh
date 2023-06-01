#!/bin/bash

/usr/bin/curl -X POST \
    --data-urlencode "infoHash=$1" \
    http://cross-seed.default.svc.cluster.local:2468/api/webhook
