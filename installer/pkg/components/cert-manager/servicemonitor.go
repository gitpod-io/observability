package certmanager

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
				Name:      App,
				Namespace: ServiceMonitorNamespace,
				Labels:    labels(),
				Annotations: map[string]string{
					"argocd.argoproj.io/sync-options": "Replace=true",
				},
			},
			Spec: monitoringv1.ServiceMonitorSpec{
				JobLabel: "app.kubernetes.io/name",
				Endpoints: []monitoringv1.Endpoint{
					{
						Interval:             "60s",
						Port:                 "metrics",
						HonorLabels:          true,
						MetricRelabelConfigs: common.DropMetricsRelabeling(ctx),
					},
				},
				NamespaceSelector: monitoringv1.NamespaceSelector{
					MatchNames: []string{Namespace},
				},
				Selector: metav1.LabelSelector{
					MatchLabels: labels(),
				},
			},
		},
	}, nil
}
