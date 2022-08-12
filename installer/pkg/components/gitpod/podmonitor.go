package gitpod

import (
	monitoringv1 "github.com/prometheus-operator/prometheus-operator/pkg/apis/monitoring/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"

	"github.com/gitpod-io/observability/installer/pkg/common"
)

func podMonitor() common.RenderFunc {
	return func(ctx *common.RenderContext) ([]runtime.Object, error) {
		return []runtime.Object{
			&monitoringv1.PodMonitor{
				TypeMeta: metav1.TypeMeta{
					APIVersion: "monitoring.coreos.com/v1",
					Kind:       "PodMonitor",
				},
				ObjectMeta: metav1.ObjectMeta{
					Name:      "workspace",
					Namespace: Namespace,
					Labels: map[string]string{
						"app.kubernetes.io/name":    "gitpod",
						"app.kubernetes.io/part-of": "kube-prometheus",
					},
				},
				Spec: monitoringv1.PodMonitorSpec{
					NamespaceSelector: monitoringv1.NamespaceSelector{
						MatchNames: []string{GitpodNamespace},
					},
					Selector: metav1.LabelSelector{
						MatchLabels: map[string]string{
							"component":     "workspace",
							"workspaceType": "regular",
						},
					},
					PodMetricsEndpoints: []monitoringv1.PodMetricsEndpoint{
						{
							Interval:      "60s",
							Port:          "supervisor",
							ScrapeTimeout: "5s",
							MetricRelabelConfigs: []*monitoringv1.RelabelConfig{
								{
									Action: "keep",
									Regex:  "gitpod_(.*)",
									SourceLabels: []monitoringv1.LabelName{
										"__name__",
									},
								},
							},
						},
					},
				},
			},
		}, nil
	}
}
