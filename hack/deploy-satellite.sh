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
kubectl $KUBECONFIG_FLAG apply -f monitoring-satellite/manifests/podsecuritypolicy-restricted.yaml

for CRD in $(find monitoring-satellite/manifests/prometheusOperator/ -type f -name "*CustomResourceDefinition.yaml"); 
do 
  kubectl $KUBECONFIG_FLAG replace -f $CRD || kubectl $KUBECONFIG_FLAG create -f $CRD
done

until kubectl $KUBECONFIG_FLAG get servicemonitors.monitoring.coreos.com --all-namespaces ; do date; sleep 1; echo ""; done
until kubectl $KUBECONFIG_FLAG get prometheusrules.monitoring.coreos.com --all-namespaces ; do date; sleep 1; echo ""; done

kubectl $KUBECONFIG_FLAG apply -f monitoring-satellite/manifests/pyrra/crd.yaml

for operatorManifest in $(find monitoring-satellite/manifests/prometheusOperator/ -type f ! -name "*CustomResourceDefinition.yaml"); 
do 
  kubectl $KUBECONFIG_FLAG apply -f $operatorManifest
done

kubectl $KUBECONFIG_FLAG apply -f monitoring-satellite/manifests/prometheus/
kubectl $KUBECONFIG_FLAG apply -f monitoring-satellite/manifests/nodeExporter/
kubectl $KUBECONFIG_FLAG apply -f monitoring-satellite/manifests/kubernetesControlPlane/
kubectl $KUBECONFIG_FLAG apply -f monitoring-satellite/manifests/kubeStateMetrics/
kubectl $KUBECONFIG_FLAG apply -f monitoring-satellite/manifests/kubescape/
kubectl $KUBECONFIG_FLAG apply -f monitoring-satellite/manifests/grafana/
kubectl $KUBECONFIG_FLAG apply -f monitoring-satellite/manifests/alertmanager/
kubectl $KUBECONFIG_FLAG apply -f monitoring-satellite/manifests/otelCollector/
kubectl $KUBECONFIG_FLAG apply -f monitoring-satellite/manifests/pyrra/
kubectl $KUBECONFIG_FLAG apply -f monitoring-satellite/manifests/blackboxExporter/
kubectl $KUBECONFIG_FLAG apply -f monitoring-satellite/manifests/probers/