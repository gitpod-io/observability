// This file is used to generate YAMLs for testing purposes.
local monitoringCentral = (import '../monitoring-central.libsonnet');

{ namespace: monitoringCentral.kubePrometheus.namespace } +
{ ['grafana/' + name]: monitoringCentral.grafana[name] for name in std.objectFields(monitoringCentral.grafana) } +
{ ['victoriametrics/' + name]: monitoringCentral.victoriametrics[name] for name in std.objectFields(monitoringCentral.victoriametrics) }
