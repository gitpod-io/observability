local werft = import '../components/werft/werft.libsonnet';
local defaults = {
  namespace: 'werft',

};

function(config) {
  local werftConfig = defaults + config.werft,

  values+:: {
    prometheus+: {
      namespaces+: [werftConfig.namespace],
    },
  },

  werft: werft({
    namespace: config.namespace,
    werftNamespace: werftConfig.namespace,
    prometheusLabels: $.prometheus.prometheus.metadata.labels,
  },),
}
