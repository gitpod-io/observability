// This file is used to generate YAMLs for testing purposes.
local monitoringSatellite = (import '../monitoring-satellite.libsonnet');
local excludedComponents = [
  'kubePrometheus',
  'restrictedPodSecurityPolicy',
  'prometheusOperator',
  'pyrra',
];

{ namespace: monitoringSatellite.kubePrometheus.namespace } +
{ 'podsecuritypolicy-restricted': monitoringSatellite.restrictedPodSecurityPolicy } +
{ 'prometheus/kube-prometheus-prometheusRule': monitoringSatellite.kubePrometheus.prometheusRule } +
{
  [component + '/' + resource]: monitoringSatellite[component][resource]
  for component in std.filter(function(component) !std.member(excludedComponents, component), std.objectFields(monitoringSatellite))
  for resource in std.objectFields(monitoringSatellite[component])
} +
{
  [component + '/' + resource]: monitoringSatellite[component][resource]
  for component in std.filter(function(component) std.member(['pyrra', 'prometheusOperator'], component), std.objectFields(monitoringSatellite))
  for resource in std.filter(function(resource) monitoringSatellite[component][resource].kind != 'CustomResourceDefinition', std.objectFields(monitoringSatellite[component]))
} +
{
  ['crds' + '/' + component + '-' + resource]: monitoringSatellite[component][resource]
  for component in std.filter(function(component) std.member(['pyrra', 'prometheusOperator'], component), std.objectFields(monitoringSatellite))
  for resource in std.filter(function(resource) monitoringSatellite[component][resource].kind == 'CustomResourceDefinition', std.objectFields(monitoringSatellite[component]))
}
