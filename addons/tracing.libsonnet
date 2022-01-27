local otelCollector = import '../components/open-telemetry-collector/open-telemetry-collector.libsonnet';

function(config) {

  assert std.objectHas(config.tracing, 'honeycombAPIKey') : (
    "If 'tracing' is set, 'honeycombAPIKey' should be declared"
  ),

  values+:: {
    otelCollectorParams: {
      namespace: config.namespace,
    },
  },

  otelCollector: otelCollector($.values.otelCollectorParams),
}
