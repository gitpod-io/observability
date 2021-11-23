// This file is used to update monitoring-satellites with ArgoCD
local monitoringSatellite = (import './monitoring-satellite.libsonnet');
local excludedComponents = [
  'blackboxExporter',
  'kubePrometheus',
  'restrictedPodSecurityPolicy',
];

[
  monitoringSatellite.kubePrometheus.namespace,
  monitoringSatellite.kubePrometheus.prometheusRule,
  monitoringSatellite.restrictedPodSecurityPolicy,
] +
[
  monitoringSatellite[component][resource]
  for component in std.filter(function(component) !std.member(excludedComponents, component), std.objectFields(monitoringSatellite))
  for resource in std.objectFields(monitoringSatellite[component],)
]
