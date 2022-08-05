#!/bin/bash

which kind
if [[ $? != 0 ]]; then
    echo 'kind not available in $PATH, installing latest kind'
    # Install latest kind
    curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest \
    | grep "browser_download_url.*kind-linux-amd64" \
    | cut -d : -f 2,3 \
    | tr -d \" \
    | wget -qi -
    mv kind-linux-amd64 tmp/bin/kind && chmod +x tmp/bin/kind
    export PATH=$PATH:$(pwd)/tmp/bin
fi

cluster_created=$(kind get clusters 2>&1)
if [[ "$cluster_created" == "No kind clusters found." ]]; then 
    kind create cluster --config $PWD/.github/workflows/kind/config.yml
else
    echo "Cluster '$cluster_created' already present" 
fi 