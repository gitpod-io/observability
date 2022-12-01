package nodeexporter

import (
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
				Name:      Name,
				Namespace: Namespace,
				Labels:    common.Labels(Name, Component, App, Version),
			},
			Spec: monitoringv1.ServiceMonitorSpec{
				Endpoints: []monitoringv1.Endpoint{
					{
						BearerTokenFile: "/var/run/secrets/kubernetes.io/serviceaccount/token",
						Port:            "https",
						Interval:        "15s",
						Scheme:          "https",
						TLSConfig: &monitoringv1.TLSConfig{
							SafeTLSConfig: monitoringv1.SafeTLSConfig{
								InsecureSkipVerify: true,
							},
						},
						MetricRelabelConfigs: common.DropMetricsRelabeling(ctx),
						RelabelConfigs: []*monitoringv1.RelabelConfig{
							{
								Action:      "replace",
								Regex:       "(.*)",
								Replacement: "$1",
								SourceLabels: []monitoringv1.LabelName{
									"__meta_kubernetes_pod_node_name",
								},
								TargetLabel: "instance",
							},
							{
								Action:      "replace",
								Regex:       "(.*)",
								Replacement: "$1",
								SourceLabels: []monitoringv1.LabelName{
									"__meta_kubernetes_pod_node_name",
								},
								TargetLabel: "node",
							},
						},
					},
				},
				JobLabel: "app.kubernetes.io/name",
				Selector: metav1.LabelSelector{
					MatchLabels: common.Labels(Name, Component, App, Version),
				},
			},
		},
	}, nil
}
