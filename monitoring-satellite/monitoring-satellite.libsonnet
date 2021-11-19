local certmanager = import '../components/certmanager/certmanager.libsonnet';
local gitpod = import '../components/gitpod/gitpod.libsonnet';
local werft = import '../components/werft/werft.libsonnet';

(import 'kube-prometheus/main.libsonnet') +
(import 'kube-prometheus/platforms/gke.libsonnet') +
(import 'kube-prometheus/addons/podsecuritypolicies.libsonnet') +
(import 'kube-prometheus/addons/strip-limits.libsonnet') +
(import '../addons/disable-grafana-auth.libsonnet') +
(import '../addons/ksm-extra-labels.libsonnet') +
(import '../addons/metrics-relabeling.libsonnet') +
(import '../addons/cluster-monitoring.libsonnet') +
(if std.extVar('remote_write_enabled') == 'true' then (import '../addons/remote-write.libsonnet') else {}) +
(if std.extVar('alerting_enabled') == 'true' then (import '../addons/alerting.libsonnet') else {}) +
(if std.extVar('tracing_enabled') == 'true' then (import '../addons/tracing.libsonnet') else {}) +
{
  values+:: {
    common+: {
      namespace: std.extVar('namespace'),
    },

    gitpodParams: {
      namespace: std.extVar('namespace'),
      gitpodNamespace: 'default',
      prometheusLabels: $.prometheus.prometheus.metadata.labels,
      mixin+: { ruleLabels: $.values.common.ruleLabels },
    },

    certmanagerParams: {
      namespace: std.extVar('namespace'),
      certmanagerNamespace: 'certmanager',
      prometheusLabels: $.prometheus.prometheus.metadata.labels,
      mixin+: { ruleLabels: $.values.common.ruleLabels },
    },

    werftParams: {
      namespace: std.extVar('namespace'),
      werftNamespace: 'werft',
      prometheusLabels: $.prometheus.prometheus.metadata.labels,
    },

    prometheus+: {
      replicas: 1,
      namespaces+: [$.values.certmanagerParams.certmanagerNamespace, $.values.werftParams.werftNamespace],
      externalLabels: {
        cluster: std.extVar('cluster_name'),
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
        'Team Meta': $.gitpod.metaMixin.grafanaDashboards,
        'Team Workspace': $.gitpod.workspaceMixin.grafanaDashboards,
      },
    },

  },

  gitpod: gitpod($.values.gitpodParams),
  certmanager: certmanager($.values.certmanagerParams),
  werft: werft($.values.werftParams),
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
          namespace: std.extVar('namespace'),
        },
      },
    },
    prometheusRule+: (import '../lib/alert-severity-mapper.libsonnet') + (import '../lib/alert-filter.libsonnet') + (import '../lib/alert-duration-mapper.libsonnet'),
  },
}
+
(import '../addons/gitpod-runbooks.libsonnet') +
(if std.extVar('is_preview') == 'true' then (import '../addons/preview-env.libsonnet') else {})
