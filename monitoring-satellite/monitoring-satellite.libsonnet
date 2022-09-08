local config = (import 'load-config.libsonnet')(std.extVar('config'));
local certmanager = import '../components/certmanager/certmanager.libsonnet';
local gitpod = import '../components/gitpod/gitpod.libsonnet';

(import 'kube-prometheus/main.libsonnet') +
(import 'kube-prometheus/platforms/gke.libsonnet') +
(import 'kube-prometheus/addons/podsecuritypolicies.libsonnet') +
(import 'kube-prometheus/addons/strip-limits.libsonnet') +
(import '../addons/ksm-extra-labels.libsonnet') +
(import '../addons/metrics-relabeling.libsonnet') +
(import '../addons/argocd-crd-replace.libsonnet') +
(import '../addons/strip-priority-class.libsonnet') +
(import '../addons/networkpolicies-disabled.libsonnet') +
(if std.objectHas(config, 'alerting') then (import '../addons/alerting.libsonnet')(config) else {}) +
(if std.objectHas(config, 'remoteWrite') then (import '../addons/remote-write.libsonnet')(config) else {}) +
(if (std.objectHas(config, 'prometheus')) && (std.objectHas(config.prometheus, 'DNS')) then (import '../addons/remote-write-ingress.libsonnet')(config) else {}) +
(if std.objectHas(config, 'tracing') then (import '../addons/tracing.libsonnet')(config) else {}) +
(if std.objectHas(config, 'werft') then (import '../addons/monitor-werft.libsonnet')(config) else {}) +
(if std.objectHas(config, 'stackdriver') then (import '../addons/grafana-stackdriver-datasource.libsonnet')(config) else {}) +
(if std.objectHas(config, 'kubescape') then (import '../addons/kubescape.libsonnet')(config) else {}) +
(if std.objectHas(config, 'pyrra') then (import '../addons/pyrra.libsonnet')(config) else {}) +
(if std.objectHas(config, 'probe') then (import '../addons/probers.libsonnet')(config) else {}) +
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
      enableFeatures: (if std.objectHas(config, 'prometheus') && std.objectHas(config.prometheus, 'enableFeatures') then config.prometheus.enableFeatures else []),
      externalLabels: (if std.objectHas(config, 'clusterName') then { cluster: config.clusterName } else {}) +
                      (if std.objectHas(config, 'prometheus') && std.objectHas(config.prometheus, 'externalLabels') then config.prometheus.externalLabels else {}),
      resources: {
        requests: {
          memory: if std.objectHas(config, 'prometheus') &&
                     std.objectHas(config.prometheus, 'resources') &&
                     std.objectHas(config.prometheus.resources, 'requests') &&
                     std.objectHas(config.prometheus.resources.requests, 'memory')
          then config.prometheus.resources.requests.memory
          else '2Gi',
          cpu: if std.objectHas(config, 'prometheus') &&
                  std.objectHas(config.prometheus, 'resources') &&
                  std.objectHas(config.prometheus.resources, 'requests') &&
                  std.objectHas(config.prometheus.resources.requests, 'cpu')
          then config.prometheus.resources.requests.cpu
          else '1000m',
        },
        limits: {
          memory: if std.objectHas(config, 'prometheus') &&
                     std.objectHas(config.prometheus, 'resources') &&
                     std.objectHas(config.prometheus.resources, 'limits') &&
                     std.objectHas(config.prometheus.resources.limits, 'memory')
          then config.prometheus.resources.limits.memory
          else '10Gi',
          cpu: if std.objectHas(config, 'prometheus') &&
                  std.objectHas(config.prometheus, 'resources') &&
                  std.objectHas(config.prometheus.resources, 'limits') &&
                  std.objectHas(config.prometheus.resources.limits, 'cpu')
          then config.prometheus.resources.limits.cpu
          else '3000m',
        },
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
        env: [
          {
            name: 'GF_AUTH_ANONYMOUS_ENABLED',
            value: 'true',
          },
          {
            name: 'GF_AUTH_ANONYMOUS_ORG_ROLE',
            value: 'Admin',
          },
          {
            name: 'GF_AUTH_DISABLE_LOGIN_FORM',
            value: 'true',
          },
        ],
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
