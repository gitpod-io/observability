// This file is used to update monitoring-satellites with ArgoCD
local monitoringSatellite = (import 'monitoring-satellite/monitoring-satellite.libsonnet');

{ 'setup/0namespace': monitoringSatellite.kubePrometheus.namespace } +
{ 'setup/kubePrometheus-prometheusRule': monitoringSatellite.kubePrometheus.prometheusRule } +
{ 'setup/restrictedPodSecurityPolicy': monitoringSatellite.restrictedPodSecurityPolicy } +
{
  ['setup/prometheus-operator-' + name]: monitoringSatellite.prometheusOperator[name]
  for name in std.filter((function(name) name != 'serviceMonitor' && name != 'prometheusRule'), std.objectFields(monitoringSatellite.prometheusOperator))
} +
// serviceMonitor and prometheusRule are separated so that they can be created after the CRDs are ready
{ 'prometheus-operator-serviceMonitor': monitoringSatellite.prometheusOperator.serviceMonitor } +
{ 'prometheus-operator-prometheusRule': monitoringSatellite.prometheusOperator.prometheusRule } +
{ ['kube-state-metrics-' + name]: monitoringSatellite.kubeStateMetrics[name] for name in std.objectFields(monitoringSatellite.kubeStateMetrics) } +
{ ['grafana-' + name]: monitoringSatellite.grafana[name] for name in std.objectFields(monitoringSatellite.grafana) } +
{ ['prometheus-' + name]: monitoringSatellite.prometheus[name] for name in std.objectFields(monitoringSatellite.prometheus) } +
{ ['gitpod-' + name]: monitoringSatellite.gitpod[name] for name in std.objectFields(monitoringSatellite.gitpod) } +
{ ['alertmanager-' + name]: monitoringSatellite.alertmanager[name] for name in std.objectFields(monitoringSatellite.alertmanager) } +
{ ['kubernetes-' + name]: monitoringSatellite.kubernetesControlPlane[name] for name in std.objectFields(monitoringSatellite.kubernetesControlPlane) } +
{ ['node-exporter-' + name]: monitoringSatellite.nodeExporter[name] for name in std.objectFields(monitoringSatellite.nodeExporter) }
