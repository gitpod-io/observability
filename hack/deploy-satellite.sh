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

kubectl $KUBECONFIG_FLAG apply -f monitoring-satellite/manifests/namespace.yaml

./hack/deploy-crds.sh --kubeconfig "${KUBECONFIG}"

# shellcheck disable=SC2044
for operatorManifest in $(find monitoring-satellite/manifests/prometheusOperator/ -type f ! -name "*CustomResourceDefinition.yaml");
do
  kubectl $KUBECONFIG_FLAG apply -f "${operatorManifest}"
done

kubectl $KUBECONFIG_FLAG apply -f monitoring-satellite/manifests/prometheus/
kubectl $KUBECONFIG_FLAG apply -f monitoring-satellite/manifests/nodeExporter/
kubectl $KUBECONFIG_FLAG apply -f monitoring-satellite/manifests/kubernetesControlPlane/
kubectl $KUBECONFIG_FLAG apply -f monitoring-satellite/manifests/kubeStateMetrics/
kubectl $KUBECONFIG_FLAG apply -f monitoring-satellite/manifests/grafana/
kubectl $KUBECONFIG_FLAG apply -f monitoring-satellite/manifests/alertmanager/
kubectl $KUBECONFIG_FLAG apply -f monitoring-satellite/manifests/otelCollector/
kubectl $KUBECONFIG_FLAG apply -f monitoring-satellite/manifests/pyrra/
kubectl $KUBECONFIG_FLAG apply -f monitoring-satellite/manifests/blackboxExporter/
kubectl $KUBECONFIG_FLAG apply -f monitoring-satellite/manifests/probers/
