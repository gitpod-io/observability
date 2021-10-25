// This file is used to update monitoring-satellites with ArgoCD
local monitoringSatellite = (import '../monitoring-satellite.libsonnet') + (import '../../addons/continuous_integration.libsonnet');

{ namespace: monitoringSatellite.kubePrometheus.namespace } +
{ 'podsecuritypolicy-restricted': monitoringSatellite.restrictedPodSecurityPolicy } +
{ 'prometheus/kube-prometheus-prometheusRule': monitoringSatellite.kubePrometheus.prometheusRule } +
{ ['grafana/' + name]: monitoringSatellite.grafana[name] for name in std.objectFields(monitoringSatellite.grafana) } +
{ ['prometheus/' + name]: monitoringSatellite.prometheus[name] for name in std.objectFields(monitoringSatellite.prometheus) } +
{ ['gitpod/' + name]: monitoringSatellite.gitpod[name] for name in std.objectFields(monitoringSatellite.gitpod) } +
{ ['alertmanager/' + name]: monitoringSatellite.alertmanager[name] for name in std.objectFields(monitoringSatellite.alertmanager) } +
{ ['kube-state-metrics/' + name]: monitoringSatellite.kubeStateMetrics[name] for name in std.objectFields(monitoringSatellite.kubeStateMetrics) } +
{ ['kubernetes/' + name]: monitoringSatellite.kubernetesControlPlane[name] for name in std.objectFields(monitoringSatellite.kubernetesControlPlane) }
{ ['node-exporter/' + name]: monitoringSatellite.nodeExporter[name] for name in std.objectFields(monitoringSatellite.nodeExporter) } +
{ ['prometheus-operator/' + name]: monitoringSatellite.prometheusOperator[name] for name in std.objectFields(monitoringSatellite.prometheusOperator) } +
{ ['certmanager/' + name]: monitoringSatellite.certmanager[name] for name in std.objectFields(monitoringSatellite.certmanager) } +
{ ['otelCollector/' + name]: monitoringSatellite.otelCollector[name] for name in std.objectFields(monitoringSatellite.otelCollector) }
