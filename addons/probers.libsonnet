local probers = import '../components/probers/probers.libsonnet';

function(config) {

  values+:: {
    probeParams: {
      namespace: config.namespace,
    },
  },

  probers: probers($.values.probeParams),
}
