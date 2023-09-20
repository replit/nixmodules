#!/usr/bin/env bash

set -eo pipefail

if [[ ! -f /usr/local/bin/pvnctl ]]; then
    curl -L -o pvnctl.tar.gz https://github.com/prodvana/pvnctl/releases/download/0.7.9/pvnctl_0.7.9_linux_amd64.tar.gz
    tar xf pvnctl.tar.gz
    sudo mv pvnctl /usr/local/bin/pvnctl
    sudo pvnctl self-update
fi
pvnctl auth context add replit "api.replit.prodvana.io:443"
pvnctl auth token "${PRODVANA_API_TOKEN}"
