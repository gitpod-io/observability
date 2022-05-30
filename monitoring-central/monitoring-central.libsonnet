local config = (import 'load-config.libsonnet')(std.extVar('config'));
local certmanager = import '../components/certmanager/certmanager.libsonnet';
local gitpod = import '../components/gitpod/gitpod.libsonnet';
local victoriaMetrics = import '../components/victoriametrics/victoriametrics.libsonnet';
local kubescape = (import 'kubescape/kubescape.libsonnet');

local kubePrometheus =
  (import 'kube-prometheus/main.libsonnet') +
  (import 'kube-prometheus/platforms/gke.libsonnet') +
  (import 'kube-prometheus/addons/podsecuritypolicies.libsonnet') +
  (import '../addons/networkpolicies-disabled.libsonnet') +
  (import '../addons/disable-grafana-auth.libsonnet') +
  (import '../addons/grafana-on-gcp-oauth.libsonnet')(config) +
  {
    values+:: {
      common+: {
        namespace: 'monitoring-central',
      },
      gitpodParams: {
        namespace: config.namespace,
      },
      certmanagerParams: {
        mixin+: {},
      },
      kubescapeParams: {
        namespace: config.namespace,
      },
      victoriametricsParams: {
        name: 'victoriametrics',
        namespace: 'monitoring-central',
        port: 8428,
        internalLoadBalancerIP: '10.32.0.25',
      },
      grafana+: {
        resources: {
          requests: { 
            memory: if std.objectHas(config, 'grafana') &&
                     std.objectHas(config.grafana, 'resources') &&
                     std.objectHas(config.grafana.resources, 'requests') &&
                     std.objectHas(config.grafana.resources.requests, 'memory')
            then config.grafana.resources.requests.memory
            else '1000Mi',
            cpu: if std.objectHas(config, 'grafana') &&
                    std.objectHas(config.grafana, 'resources') &&
                    std.objectHas(config.grafana.resources, 'requests') &&
                    std.objectHas(config.grafana.resources.requests, 'cpu')
            then config.grafana.resources.requests.cpu
            else '1',
            },
          limits: {
            memory: if std.objectHas(config, 'grafana') &&
                    std.objectHas(config.grafana, 'resources') &&
                    std.objectHas(config.grafana.resources, 'limits') &&
                    std.objectHas(config.grafana.resources.limits, 'memory')
            then config.grafana.resources.limits.memory
            else '1000Mi',
            cpu: if std.objectHas(config, 'grafana') &&
                    std.objectHas(config.grafana, 'resources') &&
                    std.objectHas(config.grafana.resources, 'limits') &&
                    std.objectHas(config.grafana.resources.limits, 'cpu')
            then config.grafana.resources.limits.cpu
            else '1',
            },
        },
        dashboards:: {},
        folderDashboards+:: {
          'Team Platform': $.kubernetesControlPlane.mixin.grafanaDashboards + $.prometheus.mixin.grafanaDashboards + $.alertmanager.mixin.grafanaDashboards + $.certmanager.mixin.grafanaDashboards + $.nodeExporter.mixin.grafanaDashboards + $.kubescape.mixin.grafanaDashboards,
          'Cross Teams': $.gitpod.crossTeamsMixin.grafanaDashboards,
          'Team IDE': $.gitpod.ideMixin.grafanaDashboards,
          'Team WebApp': $.gitpod.webappMixin.grafanaDashboards,
          'Team Workspace': $.gitpod.workspaceMixin.grafanaDashboards,
          'Self-hosted examples'+: $.gitpod.selfhostedMixin.grafanaDashboards,
        },
        datasources: [
          {
            name: 'VictoriaMetrics',
            type: 'prometheus',
            access: 'proxy',
            orgId: 1,
            url: 'http://' + $.values.victoriametricsParams.name + '.' + $.values.victoriametricsParams.namespace + '.svc:' + $.values.victoriametricsParams.port,
            version: 1,
            editable: false,
          },
        ],
        config: {
          sections: {
            dashboards: {
              default_home_dashboard_path: '/grafana-dashboard-definitions/Cross Teams/gitpod-overview/gitpod-overview.json',
            },
          },
        },
      },

      nodeExporter+: {
        mixin+: {
          _config+: {
            showMultiCluster: true,
            fsSelector: 'fstype!="shiftfs"',
          },
        },
      },

      alertmanager+: {
        mixin+: {
          _config+: {
            alertmanagerClusterLabels: 'cluster',
            alertmanagerNameLabels: 'namespace,pod',
            alertmanagerCriticalIntegrationsRegEx: 'slack|pagerduty',
          },
        },
      },

      kubernetesControlPlane+: {
        mixin+: {
          _config+: {
            showMultiCluster: true,
            SLOs+: {
              apiserver+: {
                target: 0.99,
              },
            },
          },
        },
      },
    },

    // Included just to generate gitpod dashboards. No need to generate any YAML.
    gitpod: gitpod($.values.gitpodParams),
    certmanager: certmanager($.values.certmanagerParams),
    victoriametrics: victoriaMetrics($.values.victoriametricsParams),
    kubescape: kubescape($.values.kubescapeParams),
    grafana+: {
      // Disabling serviceMonitor for monitoring-central since there is no prometheus running there.
      serviceMonitor:: {},
    },
  } +
  // This addon is being added at the bottom because Jsonnet is concious about code ordering.
  // Above we override all datasources with victoriametrics.
  // If this addon is kept above, it will be overriden as well.
  (if std.objectHas(config, 'stackdriver') then (import '../addons/grafana-stackdriver-datasource.libsonnet')(config) else {});


kubePrometheus
