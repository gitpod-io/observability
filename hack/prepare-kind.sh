#!/bin/bash

# shellcheck disable=SC2230
which kind
if [[ ! $?  ]]; then
    # shellcheck disable=SC2016
    echo 'kind not available in $PATH, installing latest kind'
    # Install latest kind
    curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest \
    | grep "browser_download_url.*kind-linux-amd64" \
    | cut -d : -f 2,3 \
    | tr -d \" \
    | wget -qi -
    sudo mv kind-linux-amd64 /usr/bin/kind && sudo chmod +x /usr/bin/kind
    rm -f kind-linux-amd64*
    binpath=$PATH:$(pwd)/tmp/bin
    export PATH=$binpath
fi

cluster_created=$(kind get clusters 2>&1)
if [[ "$cluster_created" == "No kind clusters found." ]]; then
    kind create cluster --config "${PWD}"/.github/workflows/kind/config.yml
else
    echo "Cluster ${cluster_created} already present"
fi
