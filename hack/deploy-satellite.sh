#!/bin/bash

kubectl apply -f monitoring-satellite/manifests/namespace.yaml
kubectl apply -f monitoring-satellite/manifests/podsecuritypolicy-restricted.yaml

kubectl create -f monitoring-satellite/manifests/prometheus-operator/0alertmanagerConfigCustomResourceDefinition.yaml
kubectl create -f monitoring-satellite/manifests/prometheus-operator/0alertmanagerCustomResourceDefinition.yaml
kubectl create -f monitoring-satellite/manifests/prometheus-operator/0podmonitorCustomResourceDefinition.yaml
kubectl create -f monitoring-satellite/manifests/prometheus-operator/0probeCustomResourceDefinition.yaml
kubectl create -f monitoring-satellite/manifests/prometheus-operator/0prometheusCustomResourceDefinition.yaml
kubectl create -f monitoring-satellite/manifests/prometheus-operator/0prometheusruleCustomResourceDefinition.yaml
kubectl create -f monitoring-satellite/manifests/prometheus-operator/0servicemonitorCustomResourceDefinition.yaml
kubectl create -f monitoring-satellite/manifests/prometheus-operator/0thanosrulerCustomResourceDefinition.yaml

until kubectl get servicemonitors.monitoring.coreos.com --all-namespaces ; do date; sleep 1; echo ""; done
until kubectl get prometheusrules.monitoring.coreos.com --all-namespaces ; do date; sleep 1; echo ""; done

kubectl apply -f monitoring-satellite/manifests/prometheus-operator/
kubectl apply -f monitoring-satellite/manifests/prometheus/
kubectl apply -f monitoring-satellite/manifests/node-exporter/
kubectl apply -f monitoring-satellite/manifests/kubernetes/
kubectl apply -f monitoring-satellite/manifests/kube-state-metrics/
kubectl apply -f monitoring-satellite/manifests/grafana/
kubectl apply -f monitoring-satellite/manifests/alertmanager/
