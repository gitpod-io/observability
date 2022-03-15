local kubescape = (import 'kubescape/kubescape.libsonnet');

function(config) {
  values+:: {
    kubescapeParams: {
      namespace: config.namespace,
      scrapeInterval:
        if std.objectHas(config.kubescape, 'scrapeInterval')
        then config.kubescape.scrapeInterval
        else '240s',
    },

    grafana+: {
      folderDashboards+:: {
        'Team Platform'+: $.kubescape.mixin.grafanaDashboards,
      },
    },
  },

  kubescape: kubescape($.values.kubescapeParams),
}
