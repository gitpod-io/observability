#!/bin/bash

KUBECONFIG=""
KUBECONFIG_FLAG=""

opts=$(getopt \
  --longoptions "kubeconfig:" \
  --name "$(basename "$0")" \
  --options "" \
  -- "$@"
)

eval set -- "$opts"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --kubeconfig) KUBECONFIG=$2 ; shift 2 ;;
    *) break ;;
  esac
done

if [[ $KUBECONFIG != "" ]]; then
  KUBECONFIG_FLAG="--kubeconfig ${KUBECONFIG}"
fi

kubectl $KUBECONFIG_FLAG apply -f monitoring-satellite/manifests/pyrra/crd.yaml

kubectl $KUBECONFIG_FLAG apply -f monitoring-central/manifests/namespace.yaml
kubectl $KUBECONFIG_FLAG apply -f monitoring-satellite/manifests/podsecuritypolicy-restricted.yaml

kubectl $KUBECONFIG_FLAG apply -f monitoring-central/manifests/grafana/
kubectl $KUBECONFIG_FLAG apply -f monitoring-central/manifests/victoriametrics/
kubectl $KUBECONFIG_FLAG apply -f monitoring-central/manifests/pyrra/
