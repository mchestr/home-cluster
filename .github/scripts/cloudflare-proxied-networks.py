#!/usr/bin/env python3
import os

import requests
import yaml

IPV4_URL = "https://www.cloudflare.com/ips-v4"
IPV6_URL = "https://www.cloudflare.com/ips-v6"
TEMPLATE_PATH = os.environ["CLOUDFLARE_PROXIED_TRAEFIK_MIDDLEWARE_FILE"]
HEADERS = {
    'User-Agent': "https://github.com/mchestr/cluster-k3s",
}
LOCAL_IPS = [
    "192.168.0.0/16",
    "172.16.0.0/12",
    "10.0.0.0/8",
]


def fetch_ips(url: str):
    resp = requests.get(url, headers=HEADERS)
    resp.raise_for_status()

    return resp.text.split('\n')


def get_template(path: str):
    with open(path) as f:
        return [section for section in yaml.load_all(f, Loader=yaml.FullLoader)]


def main():
    template = get_template(TEMPLATE_PATH)

    ips = fetch_ips(IPV4_URL) + fetch_ips(IPV6_URL)
    ips.extend(LOCAL_IPS)


    if set(template[0]["spec"]["ipWhiteList"]["sourceRange"]) != set(ips):
        print("ips do not match, updating...")
        template[0]["spec"]["ipWhiteList"]["sourceRange"] = ips

    print(yaml.dump_all(template))


if __name__ == "__main__":
    main()
