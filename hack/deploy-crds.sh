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

kubectl $KUBECONFIG_FLAG apply -f monitoring-satellite/manifests/crds/ --server-side

until kubectl $KUBECONFIG_FLAG get servicemonitors.monitoring.coreos.com --all-namespaces ; do date; sleep 1; echo ""; done
until kubectl $KUBECONFIG_FLAG get prometheusrules.monitoring.coreos.com --all-namespaces ; do date; sleep 1; echo ""; done
