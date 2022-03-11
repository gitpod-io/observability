#!/bin/bash

kubectl apply -f monitoring-satellite/manifests/namespace.yaml
kubectl apply -f monitoring-satellite/manifests/podsecuritypolicy-restricted.yaml

for CRD in $(find monitoring-satellite/manifests/prometheusOperator/ -type f -name "*CustomResourceDefinition.yaml"); 
do 
  kubectl replace -f $CRD || kubectl create -f $CRD
done

until kubectl get servicemonitors.monitoring.coreos.com --all-namespaces ; do date; sleep 1; echo ""; done
until kubectl get prometheusrules.monitoring.coreos.com --all-namespaces ; do date; sleep 1; echo ""; done


for operatorManifest in $(find monitoring-satellite/manifests/prometheusOperator/ -type f ! -name "*CustomResourceDefinition.yaml"); 
do 
  kubectl apply -f $operatorManifest
done

kubectl apply -f monitoring-satellite/manifests/prometheus/
kubectl apply -f monitoring-satellite/manifests/nodeExporter/
kubectl apply -f monitoring-satellite/manifests/kubernetesControlPlane/
kubectl apply -f monitoring-satellite/manifests/kubeStateMetrics/
kubectl apply -f monitoring-satellite/manifests/kubescape/
kubectl apply -f monitoring-satellite/manifests/grafana/
kubectl apply -f monitoring-satellite/manifests/alertmanager/
kubectl apply -f monitoring-satellite/manifests/otelCollector/