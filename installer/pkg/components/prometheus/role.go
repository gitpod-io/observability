package prometheus

import (
	"fmt"

	rbacv1 "k8s.io/api/rbac/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"

	"github.com/gitpod-io/observability/installer/pkg/common"
)

// extraNamespaceRoles and extraNamespaceRoleBindings are used to give permission to prometheus to scrape metrics
// from endpoints in other namespaces.
func role(ctx *common.RenderContext) ([]runtime.Object, error) {
	return []runtime.Object{
		&rbacv1.Role{
			TypeMeta: metav1.TypeMeta{
				APIVersion: "rbac.authorization.k8s.io/v1",
				Kind:       "Role",
			},
			ObjectMeta: metav1.ObjectMeta{
				Name:      configRoleName(),
				Namespace: Namespace,
				Labels:    common.Labels(Name, Component, App, Version),
			},
			Rules: []rbacv1.PolicyRule{
				{
					APIGroups: []string{""},
					Resources: []string{"configmaps"},
					Verbs:     []string{"get"},
				},
			},
		},
	}, nil
}

func configRoleName() string {
	return fmt.Sprintf("%s-config", resourceName())
}
