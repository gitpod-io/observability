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

func messagebusObjects() common.RenderFunc {
	return func(ctx *common.RenderContext) ([]runtime.Object, error) {
		return []runtime.Object{
			&networkv1.NetworkPolicy{
				TypeMeta: metav1.TypeMeta{
					APIVersion: "networking.k8s.io/v1",
					Kind:       "NetworkPolicy",
				},
				ObjectMeta: metav1.ObjectMeta{
					Name:      fmt.Sprintf("%s-allow-kube-prometheus", "messagebus"),
					Namespace: GitpodNamespace,
					Labels:    labels("messagebus"),
				},
				Spec: networkv1.NetworkPolicySpec{
					PodSelector: metav1.LabelSelector{
						MatchLabels: map[string]string{
							"component": "messagebus",
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

			&corev1.Service{
				TypeMeta: common.ServiceType,
				ObjectMeta: metav1.ObjectMeta{
					Name:      fmt.Sprintf("%s-%s", App, "messagebus"),
					Namespace: GitpodNamespace,
					Labels:    labels("messagebus"),
				},
				Spec: corev1.ServiceSpec{
					Ports: []corev1.ServicePort{
						{
							Name: "metrics",
							Port: 9419,
						},
					},
					Selector: map[string]string{
						"app.kubernetes.io/name": "rabbitmq",
					},
				},
			},
			&monitoringv1.ServiceMonitor{
				TypeMeta: metav1.TypeMeta{
					APIVersion: "monitoring.coreos.com/v1",
					Kind:       "ServiceMonitor",
				},
				ObjectMeta: metav1.ObjectMeta{
					Name:      fmt.Sprintf("%s-%s", App, "messagebus"),
					Namespace: Namespace,
					Labels:    labels("messagebus"),
				},
				Spec: monitoringv1.ServiceMonitorSpec{
					Endpoints: []monitoringv1.Endpoint{
						{
							BearerTokenFile: "/var/run/secrets/kubernetes.io/serviceaccount/token",
							Interval:        "60s",
							Port:            "metrics",
						},
					},
					JobLabel: "app.kubernetes.io/component",
					NamespaceSelector: monitoringv1.NamespaceSelector{
						MatchNames: []string{GitpodNamespace},
					},
					Selector: metav1.LabelSelector{
						MatchLabels: labels("messagebus"),
					},
				},
			},
		}, nil
	}
}
