#!/usr/bin/env python3
import os
import sys

import requests
import ruamel.yaml as yaml

YAML = yaml.YAML()
YAML.indent(sequence=4, offset=2)
IPV4_URL = "https://www.cloudflare.com/ips-v4"
IPV6_URL = "https://www.cloudflare.com/ips-v6"
TEMPLATE_PATH = os.environ["CLOUDFLARE_PROXIED_TRAEFIK_MIDDLEWARE_FILE"]
HEADERS = {
    'User-Agent': "https://github.com/mchestr/home-cluster",
}
LOCAL_IPS = [
    "192.168.0.0/16",
    "172.16.0.0/12",
    "10.0.0.0/8",
]
FILE_HEADER = """# DO NOT EDIT MANUALLY. File is managed via GitHub actions.
# Script: https://github.com/mchestr/home-cluster/.github/scripts/cloudflare-proxied-networks.py
# Action: https://github.com/mchestr/home-cluster/.github/workflows/schedule-cloudflare-proxied-networks-update.yaml
---"""


def fetch_ips(url: str):
    resp = requests.get(url, headers=HEADERS)
    resp.raise_for_status()

    return resp.text.split('\n')


def main():
    template = list(YAML.load_all(sys.stdin))

    ips = fetch_ips(IPV4_URL) + fetch_ips(IPV6_URL)
    ips.extend(LOCAL_IPS)

    if set(template[0]["spec"]["ipWhiteList"]["sourceRange"]) != set(ips):
        template[0]["spec"]["ipWhiteList"]["sourceRange"] = ips

    print(FILE_HEADER)
    YAML.dump_all(template, sys.stdout)


if __name__ == "__main__":
    main()
