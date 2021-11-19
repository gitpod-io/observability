local otelCollector = import '../components/open-telemetry-collector/open-telemetry-collector.libsonnet';

{
  values+:: {
    otelCollectorParams: {
      namespace: std.extVar('namespace'),
    },
  },

  otelCollector: otelCollector($.values.otelCollectorParams),
}
