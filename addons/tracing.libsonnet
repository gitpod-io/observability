local otelCollector = import '../components/open-telemetry-collector/open-telemetry-collector.libsonnet';
local config = std.extVar('config');

{
  values+:: {
    otelCollectorParams: {
      namespace: config.namespace,
    },
  },

  otelCollector: otelCollector($.values.otelCollectorParams),
}
