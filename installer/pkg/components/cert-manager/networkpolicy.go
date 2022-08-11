package certmanager

import (
	"fmt"

	networkv1 "k8s.io/api/networking/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"

	"github.com/gitpod-io/observability/installer/pkg/common"
)

func networkPolicy(ctx *common.RenderContext) ([]runtime.Object, error) {
	return []runtime.Object{
		&networkv1.NetworkPolicy{
			TypeMeta: metav1.TypeMeta{
				APIVersion: "networking.k8s.io/v1",
				Kind:       "NetworkPolicy",
			},
			ObjectMeta: metav1.ObjectMeta{
				Name:      fmt.Sprintf("%s-allow-kube-prometheus", Component),
				Namespace: Namespace,
				Labels:    labels(),
			},
			Spec: networkv1.NetworkPolicySpec{
				PodSelector: metav1.LabelSelector{
					MatchLabels: map[string]string{
						"app":                         "cert-manager",
						"app.kubernetes.io/component": "controller",
					},
				},
				Ingress: []networkv1.NetworkPolicyIngressRule{
					{
						From: []networkv1.NetworkPolicyPeer{
							{
								NamespaceSelector: &metav1.LabelSelector{
									MatchLabels: map[string]string{
										"namespace": "monitoring-satellite",
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
