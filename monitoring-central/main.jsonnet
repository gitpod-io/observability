// This file is used to update monitoring-centrals with ArgoCD
local monitoringCentral = (import './monitoring-central.libsonnet');

[
  monitoringCentral.kubePrometheus.namespace,
] +
[monitoringCentral.grafana[name] for name in std.objectFields(monitoringCentral.grafana)] +
[monitoringCentral.victoriametrics[name] for name in std.objectFields(monitoringCentral.victoriametrics)] +
[monitoringCentral.pyrra[name] for name in std.objectFields(monitoringCentral.pyrra)]
