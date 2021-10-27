// This file is used to update monitoring-satellites with ArgoCD
local monitoringSatellite = (import './monitoring-satellite.libsonnet');

[
  monitoringSatellite.kubePrometheus.namespace,
  monitoringSatellite.kubePrometheus.prometheusRule,
  monitoringSatellite.restrictedPodSecurityPolicy,
] +
[monitoringSatellite.kubeStateMetrics[name] for name in std.objectFields(monitoringSatellite.kubeStateMetrics)] +
[monitoringSatellite.grafana[name] for name in std.objectFields(monitoringSatellite.grafana)] +
[monitoringSatellite.prometheus[name] for name in std.objectFields(monitoringSatellite.prometheus)] +
[monitoringSatellite.gitpod[name] for name in std.objectFields(monitoringSatellite.gitpod)] +
[monitoringSatellite.alertmanager[name] for name in std.objectFields(monitoringSatellite.alertmanager)] +
[monitoringSatellite.kubernetesControlPlane[name] for name in std.objectFields(monitoringSatellite.kubernetesControlPlane)] +
[monitoringSatellite.nodeExporter[name] for name in std.objectFields(monitoringSatellite.nodeExporter)] +
[monitoringSatellite.prometheusOperator[name] for name in std.objectFields(monitoringSatellite.prometheusOperator)] +
[monitoringSatellite.certmanager[name] for name in std.objectFields(monitoringSatellite.certmanager)] +
[monitoringSatellite.werft[name] for name in std.objectFields(monitoringSatellite.werft)]
