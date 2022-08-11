package prometheus

import (
	rbacv1 "k8s.io/api/rbac/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"

	"github.com/gitpod-io/observability/installer/pkg/common"
	"github.com/gitpod-io/observability/installer/pkg/components/shared"
)

func clusterRole(ctx *common.RenderContext) ([]runtime.Object, error) {
	return []runtime.Object{
		&rbacv1.ClusterRole{
			TypeMeta: metav1.TypeMeta{
				APIVersion: "rbac.authorization.k8s.io/v1",
				Kind:       "ClusterRole",
			},
			ObjectMeta: metav1.ObjectMeta{
				Name:      resourceName(),
				Namespace: Namespace,
				Labels:    common.Labels(Name, Component, App, Version),
			},
			Rules: []rbacv1.PolicyRule{
				{
					APIGroups: []string{"monitoring.coreos.com"},
					Resources: []string{"nodes/metrics"},
					Verbs:     []string{"get"},
				},
				{
					NonResourceURLs: []string{"/metrics"},

					Verbs: []string{"get"},
				},
				{
					APIGroups:     []string{"policy"},
					Resources:     []string{"podsecuritypolicies"},
					Verbs:         []string{"use"},
					ResourceNames: []string{shared.RestrictedPodsecurityPolicyName()},
				},
			},
		},
	}, nil
}
