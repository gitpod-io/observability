package common

import (
	"strings"

	monitoringv1 "github.com/prometheus-operator/prometheus-operator/pkg/apis/monitoring/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

func Labels(name, component, app, version string) map[string]string {
	return map[string]string{
		"app.kubernetes.io/component": component,
		"app.kubernetes.io/name":      name,
		"app.kubernetes.io/part-of":   app,
		"app.kubernetes.io/version":   version,
	}
}

func ToPointer[T any](o T) *T {
	return &o
}

// TODO(cw): find a better way to do this. Those values must exist in the appropriate places already.
var (
	TypeMetaConfigmap = metav1.TypeMeta{
		APIVersion: "v1",
		Kind:       "ConfigMap",
	}
	TypeMetaBatchJob = metav1.TypeMeta{
		APIVersion: "batch/v1",
		Kind:       "Job",
	}
	TypeMetaNetworkPolicy = metav1.TypeMeta{
		APIVersion: "networking.k8s.io/v1",
		Kind:       "NetworkPolicy",
	}
)

func DropMetricsRelabeling(ctx *RenderContext) []*monitoringv1.RelabelConfig {
	if ctx.Config.Prometheus.MetricsToDrop != nil {
		return []*monitoringv1.RelabelConfig{
			{
				SourceLabels: []monitoringv1.LabelName{"__name__"},
				Regex:        strings.Join(ctx.Config.Prometheus.MetricsToDrop, "|"),
				Action:       "drop",
			},
		}
	}
	return nil
}
