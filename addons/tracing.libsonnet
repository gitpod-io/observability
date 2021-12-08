local otelCollector = import '../components/open-telemetry-collector/open-telemetry-collector.libsonnet';

function(config) {

  assert std.objectHas(config.tracing, 'honeycombAPIKey') || std.objectHas(config.tracing, 'jaegerEndpoint') : (
    "If 'tracing' is set, 'honeycombAPIKey' or 'jaegerEndpoint' should be declared"
  ),

  values+:: {
    otelCollectorParams: {
      namespace: config.namespace,
    },
  },

  otelCollector: otelCollector($.values.otelCollectorParams),
}
