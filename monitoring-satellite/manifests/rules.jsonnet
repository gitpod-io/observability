// This file is used to generate all Prometheus recording and alerting rules from kube-prometheus.
// It is then imported to our CLI installer using a YAML Importer.
// This strategy is not supposed to last long, our long term vision is that we'll slowly delete unnecessary
// alerts and we'll create and maintain our alerting rules ourselves.
local monitoringSatellite = (import '../monitoring-satellite.libsonnet');

local rules = {
  prometheusRule: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'PrometheusRule',
    metadata: {
      name: 'kube-prometheus-rules',
      namespace: 'monitoring-satellite',
    },
    spec: {
      groups: monitoringSatellite.kubePrometheus.prometheusRule.spec.groups +
              monitoringSatellite.alertmanager.prometheusRule.spec.groups +
              monitoringSatellite.kubeStateMetrics.prometheusRule.spec.groups +
              monitoringSatellite.kubernetesControlPlane.prometheusRule.spec.groups +
              monitoringSatellite.nodeExporter.prometheusRule.spec.groups +
              monitoringSatellite.prometheus.prometheusRule.spec.groups +
              monitoringSatellite.prometheusOperator.prometheusRule.spec.groups +
              monitoringSatellite.certmanager.prometheusRule.spec.groups,
    },
  } + (import '../lib/alert-severity-mapper.libsonnet') + (import '../lib/alert-filter.libsonnet') + (import '../lib/alert-duration-mapper.libsonnet'),
};

{ 'kube-prometheus-rules/rules': rules.prometheusRule }
