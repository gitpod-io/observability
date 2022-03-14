local kubescape = (import 'kubescape/kubescape.libsonnet');

function(config) {
  values+:: {
    kubescapeParams: {
      namespace: config.namespace,
    },
  },
  
  kubescape: kubescape($.values.kubescapeParams),
}
