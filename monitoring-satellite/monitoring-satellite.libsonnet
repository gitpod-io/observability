local config = (import 'load-config.libsonnet')(std.extVar('config'));
local certmanager = import '../components/certmanager/certmanager.libsonnet';
local gitpod = import '../components/gitpod/gitpod.libsonnet';

(import 'kube-prometheus/main.libsonnet') +
(import 'kube-prometheus/platforms/gke.libsonnet') +
(import 'kube-prometheus/addons/podsecuritypolicies.libsonnet') +
(import 'kube-prometheus/addons/strip-limits.libsonnet') +
(import '../addons/disable-grafana-auth.libsonnet') +
(import '../addons/argocd-crd-replace.libsonnet') +
(import '../addons/networkpolicies-disabled.libsonnet') +
(if std.objectHas(config, 'pyrra') then (import '../addons/pyrra.libsonnet')(config) else {}) +
(if std.objectHas(config, 'probe') then (import '../addons/probers.libsonnet')(config) else {}) +
{
  values+:: {
    common+: {
      namespace: config.namespace,
    },

    nodeExporter+: {
      mixin+: {
        _config+: {
          fsSelector: 'fstype!="shiftfs"',
        },
      },
    },

    alertmanager+: {
      mixin+: {
        _config+: {
          alertmanagerClusterLabels: 'cluster',
          alertmanagerNameLabels: 'namespace,pod',
          alertmanagerCriticalIntegrationsRegEx: 'slack|pagerduty|webhook',
        },
      },
    },

    grafana+: {
      dashboards:: {},
      folderDashboards+:: {
        'Team Platform'+: $.kubernetesControlPlane.mixin.grafanaDashboards + $.prometheus.mixin.grafanaDashboards + $.alertmanager.mixin.grafanaDashboards + $.certmanager.mixin.grafanaDashboards + $.nodeExporter.mixin.grafanaDashboards,
        'Cross Teams'+: $.gitpod.crossTeamsMixin.grafanaDashboards,
        'Team IDE'+: $.gitpod.ideMixin.grafanaDashboards,
        'Team WebApp'+: $.gitpod.webappMixin.grafanaDashboards,
        'Team Workspace'+: $.gitpod.workspaceMixin.grafanaDashboards,
        'Self-hosted examples'+: $.gitpod.selfhostedMixin.grafanaDashboards,
      },
    },

  },

  gitpod: gitpod(),
  certmanager: certmanager(),
}
+
// Jsonnet cares about order of execution.
// At the botton we add configuration that is overriden by other above.
(if std.objectHas(config, 'nodeAffinity') then (import '../addons/node-affinity.libsonnet') else {})
