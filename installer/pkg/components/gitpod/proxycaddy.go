package gitpod

import (
	"fmt"

	monitoringv1 "github.com/prometheus-operator/prometheus-operator/pkg/apis/monitoring/v1"
	corev1 "k8s.io/api/core/v1"
	networkv1 "k8s.io/api/networking/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"

	"github.com/gitpod-io/observability/installer/pkg/common"
)

// proxyCaddyObjects cannot be generated like other components because it is the
// only one that has different ports and selectors.
func proxyCaddyObjects() common.RenderFunc {
	return func(cfg *common.RenderContext) ([]runtime.Object, error) {
		labels := map[string]string{
			"app.kubernetes.io/component": "proxy-caddy",
			"app.kubernetes.io/name":      "gitpod",
			"app.kubernetes.io/part-of":   "kube-prometheus",
		}

		return []runtime.Object{
			&monitoringv1.ServiceMonitor{
				TypeMeta: metav1.TypeMeta{
					APIVersion: "monitoring.coreos.com/v1",
					Kind:       "ServiceMonitor",
				},
				ObjectMeta: metav1.ObjectMeta{
					Name:      "gitpod-proxy-caddy",
					Namespace: Namespace,
					Labels:    labels,
				},
				Spec: monitoringv1.ServiceMonitorSpec{
					Endpoints: []monitoringv1.Endpoint{
						{
							BearerTokenFile: "/var/run/secrets/kubernetes.io/serviceaccount/token",
							Interval:        "30s",
							Port:            "metrics",
						},
					},
					JobLabel: "app.kubernetes.io/component",
					NamespaceSelector: monitoringv1.NamespaceSelector{
						MatchNames: []string{GitpodNamespace},
					},
					Selector: metav1.LabelSelector{
						MatchLabels: labels,
					},
				},
			},
			&corev1.Service{
				TypeMeta: common.ServiceType,
				ObjectMeta: metav1.ObjectMeta{
					Name:      "gitpod-proxy-caddy",
					Namespace: GitpodNamespace,
					Labels:    labels,
				},
				Spec: corev1.ServiceSpec{
					Ports: []corev1.ServicePort{
						{
							Name: "caddy-metrics",
							Port: 8003,
						},
					},
					Selector: map[string]string{
						"component": "proxy",
					},
				},
			},
			&networkv1.NetworkPolicy{
				TypeMeta: metav1.TypeMeta{
					APIVersion: "networking.k8s.io/v1",
					Kind:       "NetworkPolicy",
				},
				ObjectMeta: metav1.ObjectMeta{
					Name:      fmt.Sprintf("%s-allow-kube-prometheus", "proxy-caddy"),
					Namespace: GitpodNamespace,
					Labels:    labels,
				},
				Spec: networkv1.NetworkPolicySpec{
					PodSelector: metav1.LabelSelector{
						MatchLabels: map[string]string{
							"component": "proxy",
						},
					},
					Ingress: []networkv1.NetworkPolicyIngressRule{
						{
							From: []networkv1.NetworkPolicyPeer{
								{
									NamespaceSelector: &metav1.LabelSelector{
										MatchLabels: map[string]string{
											"kubernetes.io/metadata.name": Namespace,
										},
									},
									PodSelector: &metav1.LabelSelector{
										MatchLabels: matchLabels,
									},
								},
							},
						},
					},
					PolicyTypes: []networkv1.PolicyType{
						networkv1.PolicyTypeIngress,
					},
				},
			},
		}, nil
	}
}
