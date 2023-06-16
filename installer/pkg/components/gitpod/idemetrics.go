package gitpod

import (
	"fmt"

	monitoringv1 "github.com/prometheus-operator/prometheus-operator/pkg/apis/monitoring/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"

	"github.com/gitpod-io/observability/installer/pkg/common"
)

// ideMetricsObjects cannot be generated like other components because it has 2 endpoints
func ideMetricsObjects() common.RenderFunc {
	return func(cfg *common.RenderContext) ([]runtime.Object, error) {
		target := "ide-metrics"
		var res []runtime.Object

		obj, err := networkPolicy(target)(cfg)
		if err != nil {
			return nil, err
		}
		res = append(res, obj...)

		obj, err = service(target)(cfg)
		if err != nil {
			return nil, err
		}
		res = append(res, obj...)

		res = append(res, &monitoringv1.ServiceMonitor{
			TypeMeta: metav1.TypeMeta{
				APIVersion: "monitoring.coreos.com/v1",
				Kind:       "ServiceMonitor",
			},
			ObjectMeta: metav1.ObjectMeta{
				Name:      fmt.Sprintf("%s-%s", App, target),
				Namespace: Namespace,
				Labels:    labels(target),
				Annotations: map[string]string{
					"argocd.argoproj.io/sync-options": "Replace=true",
				},
			},
			Spec: monitoringv1.ServiceMonitorSpec{
				Endpoints: []monitoringv1.Endpoint{
					{
						BearerTokenFile:      "/var/run/secrets/kubernetes.io/serviceaccount/token",
						Interval:             "60s",
						Port:                 "metrics",
						MetricRelabelConfigs: common.DropMetricsRelabeling(cfg),
					},
					{
						BearerTokenFile:      "/var/run/secrets/kubernetes.io/serviceaccount/token",
						Interval:             "60s",
						Port:                 "metrics",
						Path:                 "/api-metrics",
						MetricRelabelConfigs: common.DropMetricsRelabeling(cfg),
					},
				},
				JobLabel: "app.kubernetes.io/component",
				NamespaceSelector: monitoringv1.NamespaceSelector{
					MatchNames: []string{GitpodNamespace},
				},
				Selector: metav1.LabelSelector{
					MatchLabels: labels(target),
				},
			},
		})

		return res, nil
	}
}
