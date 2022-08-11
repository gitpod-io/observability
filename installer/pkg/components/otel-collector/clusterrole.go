package otelcollector

import (
	rbacv1 "k8s.io/api/rbac/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"

	"github.com/gitpod-io/observability/installer/pkg/common"
)

func clusterRole(ctx *common.RenderContext) ([]runtime.Object, error) {
	return []runtime.Object{
		&rbacv1.ClusterRole{
			TypeMeta: metav1.TypeMeta{
				APIVersion: "rbac.authorization.k8s.io/v1",
				Kind:       "ClusterRole",
			},
			ObjectMeta: metav1.ObjectMeta{
				Name:      Name,
				Namespace: Namespace,
				Labels:    common.Labels(Name, Component, App, Version),
			},
			Rules: []rbacv1.PolicyRule{
				{
					APIGroups:     []string{"policy"},
					Resources:     []string{"podsecuritypolicies"},
					Verbs:         []string{"use"},
					ResourceNames: []string{Name},
				},
			},
		},
	}, nil
}
