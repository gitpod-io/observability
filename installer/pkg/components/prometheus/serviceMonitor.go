package prometheus

import (
	"strings"

	monitoringv1 "github.com/prometheus-operator/prometheus-operator/pkg/apis/monitoring/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"

	"github.com/gitpod-io/observability/installer/pkg/common"
)

func serviceMonitor(ctx *common.RenderContext) ([]runtime.Object, error) {
	return []runtime.Object{
		&monitoringv1.ServiceMonitor{
			TypeMeta: metav1.TypeMeta{
				APIVersion: "monitoring.coreos.com/v1",
				Kind:       "ServiceMonitor",
			},
			ObjectMeta: metav1.ObjectMeta{
				Name:      resourceName(),
				Namespace: Namespace,
				Labels:    common.Labels(Name, Component, App, Version),
			},
			Spec: monitoringv1.ServiceMonitorSpec{
				Endpoints: []monitoringv1.Endpoint{
					{
						Port:     "web",
						Interval: "30s",
						MetricRelabelConfigs: []*monitoringv1.RelabelConfig{
							{
								SourceLabels: []monitoringv1.LabelName{"__name__"},
								Regex:        strings.Join(ctx.Config.Prometheus.MetricsToDrop, "|"),
								Action:       "drop",
							},
						},
					},
					{
						Port:     "reloader-web",
						Interval: "30s",
						MetricRelabelConfigs: []*monitoringv1.RelabelConfig{
							{
								SourceLabels: []monitoringv1.LabelName{"__name__"},
								Regex:        strings.Join(ctx.Config.Prometheus.MetricsToDrop, "|"),
								Action:       "drop",
							},
						},
					},
					{
						Port:     "cardinality",
						Interval: "5m",
						MetricRelabelConfigs: []*monitoringv1.RelabelConfig{
							{
								SourceLabels: []monitoringv1.LabelName{"__name__"},
								Regex:        strings.Join(ctx.Config.Prometheus.MetricsToDrop, "|"),
								Action:       "drop",
							},
						},
					},
				},
				Selector: metav1.LabelSelector{
					MatchLabels: common.Labels(Name, Component, App, Version),
				},
			},
		},
	}, nil
}
