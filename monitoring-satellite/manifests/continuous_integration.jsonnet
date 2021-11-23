// This file is used to update monitoring-satellites with ArgoCD
local monitoringSatellite = (import '../monitoring-satellite.libsonnet') + (import '../../addons/continuous_integration.libsonnet');
local excludedComponents = [
  'blackboxExporter',
  'kubePrometheus',
  'restrictedPodSecurityPolicy',
];

{ namespace: monitoringSatellite.kubePrometheus.namespace } +
{ 'podsecuritypolicy-restricted': monitoringSatellite.restrictedPodSecurityPolicy } +
{ 'prometheus/kube-prometheus-prometheusRule': monitoringSatellite.kubePrometheus.prometheusRule } +
{
  [component + '/' + resource]: monitoringSatellite[component][resource]
  for component in std.filter(function(component) !std.member(excludedComponents, component), std.objectFields(monitoringSatellite))
  for resource in std.objectFields(monitoringSatellite[component],)
}
