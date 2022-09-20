#!/bin/bash

curl -s https://api.github.com/repos/gitpod-io/observability/releases/latest \
| grep "browser_download_url.*linux_amd64.tar.gz" \
| cut -d : -f 2,3 \
| tr -d \" \
| xargs curl -LO

tar -xvf obs-installer*.tar.gz
