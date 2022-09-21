package otelcollector

import (
	"fmt"

	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"

	"github.com/gitpod-io/observability/installer/pkg/common"
)

const extraAttributesProcessor = "attributes"

func configMap(ctx *common.RenderContext) ([]runtime.Object, error) {
	var receiversConfig = buildReceiversConfig(ctx)
	var processorsConfig = buildProcessorsConfig(ctx)
	var exportersConfig = buildExportersConfig(ctx)
	var extensionsConfig = buildExtensionsConfig(ctx)
	var serviceConfig = buildServiceConfig(ctx)
	var config = fmt.Sprintf(`%s
%s
%s
%s
%s`, receiversConfig, processorsConfig, exportersConfig, extensionsConfig, serviceConfig)

	return []runtime.Object{
		&corev1.ConfigMap{
			TypeMeta: metav1.TypeMeta{
				APIVersion: "v1",
				Kind:       "ConfigMap",
			},
			ObjectMeta: metav1.ObjectMeta{
				Name:      Name,
				Namespace: Namespace,
				Labels:    common.Labels(Name, Component, App, Version),
			},
			Data: map[string]string{
				"collector.yaml": config,
			},
		},
	}, nil
}

func buildReceiversConfig(ctx *common.RenderContext) string {
	return `receivers:
  jaeger:
    protocols:
      thrift_http:
        endpoint: "0.0.0.0:14268"
  otlp:
    protocols:
      grpc: # on port 4317
      http: # on port 4318
`
}

func buildProcessorsConfig(ctx *common.RenderContext) string {
	var processorsConfig = ""
	if ctx.Config.Tracing.ExtraSpanAttributes != nil {
		processorsConfig = fmt.Sprintf(`processors:
  %s:
    actions:`, extraAttributesProcessor)

		var keyValueAttributeTemplate = `
      - key: '%s'
        value: %s
        action: insert`
		for key, value := range ctx.Config.Tracing.ExtraSpanAttributes {
			processorsConfig += fmt.Sprintf(keyValueAttributeTemplate, key, value)
		}
	}

	return processorsConfig
}

func buildExportersConfig(ctx *common.RenderContext) string {
	return fmt.Sprintf(`exporters:
  otlp:
    endpoint: "api.honeycomb.io:443"
    headers:
      "x-honeycomb-team": "%s"
      "x-honeycomb-dataset": "%s"`,
		ctx.Config.Tracing.HoneycombAPIKey, ctx.Config.Tracing.HoneycombDataset)
}

func buildExtensionsConfig(ctx *common.RenderContext) string {
	return `extensions:
  health_check:
  pprof:
  zpages:`
}

func buildServiceConfig(ctx *common.RenderContext) string {
	var serviceTemplate = `service:
  telemetry:
    logs:
      level: "debug"
  extensions: [health_check, pprof,  zpages]
  pipelines:
    traces:
     receivers: [jaeger, otlp]
     processors: [%s]
     exporters: ["otlp"]
`
	var processors = ""

	if ctx.Config.Tracing.ExtraSpanAttributes != nil {
		processors = extraAttributesProcessor
	}

	return fmt.Sprintf(serviceTemplate, processors)
}
