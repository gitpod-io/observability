local config = (import 'load-config.libsonnet')(std.extVar('config'));
local certmanager = import '../components/certmanager/certmanager.libsonnet';
local gitpod = import '../components/gitpod/gitpod.libsonnet';

(import 'kube-prometheus/main.libsonnet') +
(import 'kube-prometheus/platforms/gke.libsonnet') +
(import 'kube-prometheus/addons/podsecuritypolicies.libsonnet') +
(import 'kube-prometheus/addons/strip-limits.libsonnet') +
(import '../addons/disable-grafana-auth.libsonnet') +
(import '../addons/ksm-extra-labels.libsonnet') +
(import '../addons/metrics-relabeling.libsonnet') +
(import '../addons/argocd-crd-replace.libsonnet') +
(if std.objectHas(config, 'alerting') then (import '../addons/alerting.libsonnet')(config) else {}) +
(if std.objectHas(config, 'remoteWrite') then (import '../addons/remote-write.libsonnet')(config) else {}) +
(if std.objectHas(config, 'tracing') then (import '../addons/tracing.libsonnet')(config) else {}) +
(if std.objectHas(config, 'werft') then (import '../addons/monitor-werft.libsonnet')(config) else {}) +
{
  values+:: {
    common+: {
      namespace: config.namespace,
    },

    gitpodParams: {
      namespace: config.namespace,
      gitpodNamespace: 'default',
      prometheusLabels: $.prometheus.prometheus.metadata.labels,
      mixin+: { ruleLabels: $.values.common.ruleLabels },
    },

    certmanagerParams: {
      namespace: config.namespace,
      certmanagerNamespace: 'certmanager',
      prometheusLabels: $.prometheus.prometheus.metadata.labels,
      mixin+: {
        ruleLabels: $.values.common.ruleLabels,
        _config+: {
          certManagerCertExpiryDays: 7,
        },
      },
    },

    prometheus+: {
      replicas: 1,
      namespaces+: [$.values.certmanagerParams.certmanagerNamespace],
      externalLabels: {
        cluster: config.clusterName,
      },
      resources: {
        requests: { memory: '2Gi', cpu: '1000m' },
        limits: { memory: '10Gi', cpu: '3000m' },
      },
    },

    kubernetesControlPlane+: {
      mixin+: {
        _config+: {
          SLOs+: {
            apiserver+: {
              target: 0.99,
            },
          },
        },
      },
    },

    nodeExporter+: {
      mixin+: {
        _config+: {
          fsSelector: 'fstype!="shiftfs"',
        },
      },
    },

    alertmanager+: {
      replicas: 1,
      mixin+: {
        _config+: {
          alertmanagerClusterLabels: 'cluster',
          alertmanagerNameLabels: 'namespace,pod',
          alertmanagerCriticalIntegrationsRegEx: 'slack|pagerduty',
        },
      },
    },

    grafana+: {
      dashboards:: {},
      folderDashboards+:: {
        'Team Platform': $.kubernetesControlPlane.mixin.grafanaDashboards + $.prometheus.mixin.grafanaDashboards + $.alertmanager.mixin.grafanaDashboards + $.certmanager.mixin.grafanaDashboards + $.nodeExporter.mixin.grafanaDashboards,
        'Cross Teams': $.gitpod.crossTeamsMixin.grafanaDashboards,
        'Team IDE': $.gitpod.ideMixin.grafanaDashboards,
        'Team WebApp': $.gitpod.webappMixin.grafanaDashboards,
        'Team Workspace': $.gitpod.workspaceMixin.grafanaDashboards,
      },
    },

  },

  gitpod: gitpod($.values.gitpodParams),
  certmanager: certmanager($.values.certmanagerParams),
  alertmanager+: {
    prometheusRule+: (import '../lib/alert-severity-mapper.libsonnet') + (import '../lib/alert-filter.libsonnet') + (import '../lib/alert-duration-mapper.libsonnet'),
  },
  kubeStateMetrics+: {
    prometheusRule+: (import '../lib/alert-severity-mapper.libsonnet') + (import '../lib/alert-filter.libsonnet') + (import '../lib/alert-duration-mapper.libsonnet'),
  },
  kubernetesControlPlane+: {
    prometheusRule+: (import '../lib/alert-severity-mapper.libsonnet') + (import '../lib/alert-filter.libsonnet') + (import '../lib/alert-duration-mapper.libsonnet'),
  },
  nodeExporter+: {
    prometheusRule+: (import '../lib/alert-severity-mapper.libsonnet') + (import '../lib/alert-filter.libsonnet') + (import '../lib/alert-duration-mapper.libsonnet'),
  },
  prometheus+: {
    prometheusRule+: (import '../lib/alert-severity-mapper.libsonnet') + (import '../lib/alert-filter.libsonnet') + (import '../lib/alert-duration-mapper.libsonnet'),
  },
  prometheusOperator+: {
    prometheusRule+: (import '../lib/alert-severity-mapper.libsonnet') + (import '../lib/alert-filter.libsonnet') + (import '../lib/alert-duration-mapper.libsonnet'),
  },
  kubePrometheus+: {
    namespace+: {
      metadata+: {
        labels+: {
          namespace: config.namespace,
        },
      },
    },
    prometheusRule+: (import '../lib/alert-severity-mapper.libsonnet') + (import '../lib/alert-filter.libsonnet') + (import '../lib/alert-duration-mapper.libsonnet'),
  },
}
+
// Jsonnet cares about order of execution.
// At the botton we add configuration that is overriden by other above.
(import '../addons/gitpod-runbooks.libsonnet') +
(if std.objectHas(config, 'previewEnvironment') then (import '../addons/preview-env.libsonnet')(config) else {}) +
(if std.objectHas(config, 'continuousIntegration') then (import '../addons/continuous_integration.libsonnet') else {}) +
(if std.objectHas(config, 'nodeAffinity') then (import '../addons/node-affinity.libsonnet') else {})
