local certmanager = import '../components/certmanager/certmanager.libsonnet';
local gitpod = import '../components/gitpod/gitpod.libsonnet';
local victoriaMetrics = import '../components/victoriametrics/victoriametrics.libsonnet';

local kubePrometheus =
  (import 'kube-prometheus/main.libsonnet') +
  (import 'kube-prometheus/platforms/gke.libsonnet') +
  (import 'kube-prometheus/addons/podsecuritypolicies.libsonnet') +
  (import '../addons/disable-grafana-auth.libsonnet') +
  (import '../addons/grafana-on-gcp-oauth.libsonnet') +
  {
    values+:: {
      common+: {
        namespace: 'monitoring-central',
      },
      gitpodParams: {
        namespace: std.extVar('namespace'),
      },
      certmanagerParams: {
        mixin+: {},
      },
      victoriametricsParams: {
        name: 'victoriametrics',
        namespace: 'monitoring-central',
        port: 8428,
        internalLoadBalancerIP: '10.32.0.25',
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
    grafana+: {
      // Disabling serviceMonitor for monitoring-central since there is no prometheus running there.
      serviceMonitor:: {},
    },
  } +
  
  // We add this addon at the end because Jsonnet cares about order of execution.
  // $.values.grafana.datasources is being completely overriden above to remove the prometheus datasource
  // provided by kube-prometheus. If we add this addon before that, stackdriver datasource will also get erased.
  (if std.extVar('stackdriver_datasource_enabled') == 'true' then (import '../addons/grafana-stackdriver-datasource.libsonnet') else {});


kubePrometheus
