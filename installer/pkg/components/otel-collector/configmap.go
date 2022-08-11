package otelcollector

import (
	"fmt"

	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"

	"github.com/gitpod-io/observability/installer/pkg/common"
)

func configMap(ctx *common.RenderContext) ([]runtime.Object, error) {
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
				"collector.yaml": fmt.Sprintf(`|
receivers:
  jaeger:
	protocols:
	  thrift_http:
		endpoint: "0.0.0.0:14268"
  otlp:
	protocols:
	  grpc: # on port 4317
	  http: # on port 4318
exporters:
  otlp:
	endpoint: "api.honeycomb.io:443"
	headers:
	  "x-honeycomb-team": "%s"
	  "x-honeycomb-dataset": "%s"

extensions:
  health_check:
  pprof:
  zpages:
service:
  telemetry:
	logs:
	  level: "debug"
  extensions: [health_check, pprof,  zpages]
  pipelines:
	traces:
	  receivers: [jaeger, otlp]
	  processors: [ ]
	  exporters: ["otlp"]`, ctx.Config.Tracing.HoneycombAPIKey, ctx.Config.Tracing.HoneycombDataset),
			},
		},
	}, nil
}
