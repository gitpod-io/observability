// This file is used to update monitoring-centrals with ArgoCD
local monitoringCentral = (import './monitoring-central.libsonnet');
local excludedComponents = [
  'kubePrometheus',
  'restrictedPodSecurityPolicy',
];
[
  monitoringCentral.kubePrometheus.namespace,
] +
[
  monitoringCentral[component][resource]
  for component in std.filter(function(component) !std.member(excludedComponents, component), std.objectFields(monitoringCentral))
  for resource in std.objectFields(monitoringCentral[component],)
]
