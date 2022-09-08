package gitpod

import (
	"fmt"

	monitoringv1 "github.com/prometheus-operator/prometheus-operator/pkg/apis/monitoring/v1"
	corev1 "k8s.io/api/core/v1"
	networkv1 "k8s.io/api/networking/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/util/intstr"

	"github.com/gitpod-io/observability/installer/pkg/common"
)

func workspaceObjects() common.RenderFunc {
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
			&networkv1.NetworkPolicy{
				TypeMeta: metav1.TypeMeta{
					APIVersion: "networking.k8s.io/v1",
					Kind:       "NetworkPolicy",
				},
				ObjectMeta: metav1.ObjectMeta{
					Name:      fmt.Sprintf("%s-allow-kube-prometheus", "workspace"),
					Namespace: GitpodNamespace,
					Labels:    labels("workspace"),
				},
				Spec: networkv1.NetworkPolicySpec{
					PodSelector: metav1.LabelSelector{
						MatchLabels: map[string]string{
							"component": "workspace",
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
							Ports: []networkv1.NetworkPolicyPort{
								{
									Port:     common.ToPointer(intstr.FromInt(22999)),
									Protocol: common.ToPointer(corev1.ProtocolTCP),
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
