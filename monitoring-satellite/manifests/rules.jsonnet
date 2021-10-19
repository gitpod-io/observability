// This file is used to generate YAMLs for testing purposes.
local monitoringSatellite = (import '../monitoring-satellite.libsonnet');

local rules = {
  groups+: monitoringSatellite.kubePrometheus.prometheusRule.spec.groups +
           monitoringSatellite.alertmanager.prometheusRule.spec.groups +
           monitoringSatellite.gitpod.prometheusRule.spec.groups +
           monitoringSatellite.kubeStateMetrics.prometheusRule.spec.groups +
           monitoringSatellite.kubernetesControlPlane.prometheusRule.spec.groups +
           monitoringSatellite.nodeExporter.prometheusRule.spec.groups +
           monitoringSatellite.prometheus.prometheusRule.spec.groups +
           monitoringSatellite.prometheusOperator.prometheusRule.spec.groups +
           monitoringSatellite.certmanager.prometheusRule.spec.groups,
}
;

{ ci_prometheus_rules: rules }
