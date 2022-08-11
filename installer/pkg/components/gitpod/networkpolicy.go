package gitpod

import (
	"fmt"

	"github.com/gitpod-io/observability/installer/pkg/common"
	networkv1 "k8s.io/api/networking/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
)

func networkPolicy(target string) common.RenderFunc {
	return func(cfg *common.RenderContext) ([]runtime.Object, error) {
		return []runtime.Object{
			&networkv1.NetworkPolicy{
				TypeMeta: metav1.TypeMeta{
					APIVersion: "networking.k8s.io/v1",
					Kind:       "ServiceMonitor",
				},
				ObjectMeta: metav1.ObjectMeta{
					Name:      fmt.Sprintf("%s-allow-kube-prometheus", target),
					Namespace: Namespace,
					Labels:    labels(target),
				},
				Spec: networkv1.NetworkPolicySpec{
					PodSelector: metav1.LabelSelector{},
					Ingress: []networkv1.NetworkPolicyIngressRule{
						{
							From: []networkv1.NetworkPolicyPeer{
								{
									NamespaceSelector: &metav1.LabelSelector{
										MatchLabels: map[string]string{
											"namespace": Namespace,
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
