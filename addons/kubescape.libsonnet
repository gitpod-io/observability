local kubescape = (import 'kubescape/kubescape.libsonnet');

function(config) {
  values+:: {
    kubescapeParams: {
      namespace: config.namespace,
    },

    grafana+: {
      folderDashboards+:: {
        'Team Platform'+: $.kubescape.mixin.grafanaDashboards,
      },
    },
  },

  kubescape: kubescape($.values.kubescapeParams),
}
