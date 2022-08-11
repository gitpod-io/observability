package prometheusoperator

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
				Name:      Name,
				Namespace: Namespace,
				Labels:    common.Labels(Name, Component, App, Version),
			},
			Rules: []rbacv1.PolicyRule{
				{
					APIGroups: []string{"monitoring.coreos.com"},
					Resources: []string{
						"alertmanagers",
						"alertmanagers/finalizers",
						"alertmanagerconfigs",
						"prometheuses",
						"prometheuses/finalizers",
						"prometheuses/status",
						"thanosrulers",
						"thanosrulers/finalizers",
						"servicemonitors",
						"podmonitors",
						"probes",
						"prometheusrules",
					},
					Verbs: []string{"*"},
				},
				{
					APIGroups: []string{"apps"},
					Resources: []string{"statefulsets"},
					Verbs:     []string{"*"},
				},
				{
					APIGroups: []string{""},
					Resources: []string{"configmaps", "secrets"},
					Verbs:     []string{"*"},
				},
				{
					APIGroups: []string{""},
					Resources: []string{"pods"},
					Verbs:     []string{"list", "delete"},
				},
				{
					APIGroups: []string{""},
					Resources: []string{"services", "services/finalizers", "endpoints"},
					Verbs:     []string{"get", "create", "update", "delete"},
				},
				{
					APIGroups: []string{""},
					Resources: []string{"nodes"},
					Verbs:     []string{"list", "watch"},
				},
				{
					APIGroups: []string{""},
					Resources: []string{"namespaces"},
					Verbs:     []string{"list", "watch", "get"},
				},
				{
					APIGroups: []string{"networking.k8s.io"},
					Resources: []string{"ingresses"},
					Verbs:     []string{"list", "watch", "get"},
				},
				{
					APIGroups: []string{"authentication.k8s.io"},
					Resources: []string{"tokenreviews"},
					Verbs:     []string{"create"},
				},
				{
					APIGroups: []string{"authorization.k8s.io"},
					Resources: []string{"subjectaccessreviews"},
					Verbs:     []string{"create"},
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
