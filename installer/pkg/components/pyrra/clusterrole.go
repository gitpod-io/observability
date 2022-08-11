package pyrra

import (
	rbacv1 "k8s.io/api/rbac/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"

	"github.com/gitpod-io/observability/installer/pkg/common"
)

var allRBACVerbs = []string{
	"create",
	"delete",
	"get",
	"list",
	"patch",
	"update",
	"watch",
}

func clusterRole(ctx *common.RenderContext) ([]runtime.Object, error) {
	return []runtime.Object{
		&rbacv1.ClusterRole{
			TypeMeta: metav1.TypeMeta{
				APIVersion: "rbac.authorization.k8s.io/v1",
				Kind:       "ClusterRole",
			},
			ObjectMeta: metav1.ObjectMeta{
				Name:      componentName(kubernetesComponent),
				Namespace: Namespace,
				Labels:    pyrraLabels(kubernetesComponent),
			},
			Rules: []rbacv1.PolicyRule{
				{
					APIGroups: []string{"monitoring.coreos.com"},
					Resources: []string{"prometheusrules"},
					Verbs:     allRBACVerbs,
				},
				{
					APIGroups: []string{"pyrra.dev"},
					Resources: []string{"servicelevelobjectives"},
					Verbs:     allRBACVerbs,
				},
				{
					APIGroups: []string{"monitoring.coreos.com"},
					Resources: []string{"prometheusrules/status"},
					Verbs:     []string{"get"},
				},
				{
					APIGroups: []string{"pyrra.dev"},
					Resources: []string{"servicelevelobjectives/status"},
					Verbs: []string{
						"get",
						"patch",
						"update",
					},
				},
			},
		},
	}, nil
}

func clusterRoleBinding(ctx *common.RenderContext) ([]runtime.Object, error) {
	return []runtime.Object{
		&rbacv1.ClusterRoleBinding{
			TypeMeta: metav1.TypeMeta{
				APIVersion: "rbac.authorization.k8s.io/v1",
				Kind:       "ClusterRoleBinding",
			},
			ObjectMeta: metav1.ObjectMeta{
				Name:      componentName(kubernetesComponent),
				Namespace: Namespace,
				Labels:    pyrraLabels(kubernetesComponent),
			},
			Subjects: []rbacv1.Subject{
				{
					Kind:      "ServiceAccount",
					Name:      componentName(kubernetesComponent),
					Namespace: Namespace,
				},
			},
			RoleRef: rbacv1.RoleRef{
				Kind:     "ClusterRole",
				APIGroup: "rbac.authorization.k8s.io",
				Name:     componentName(kubernetesComponent),
			},
		},
	}, nil
}
