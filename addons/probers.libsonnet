local probers = import '../components/probers/probers.libsonnet';

function(config) {

  assert std.objectHas(config.probe, 'targets') : (
    "If 'probe' is set, 'targets' should be declared"
  ),

  assert std.isArray(config.probe.targets) : (
    'remote-write targets should be an array'
  ),

  values+:: {
    probeParams: {
      namespace: config.namespace,
      blackboxExporterName: 'blackbox-exporter',
      blackboxExporterNamespace: config.namespace,
      targets: config.probe.targets,
    },
  },

  probers: probers($.values.probeParams),
}
