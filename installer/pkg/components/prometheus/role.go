package prometheus

import (
	"fmt"

	"github.com/gitpod-io/observability/installer/pkg/common"
	rbacv1 "k8s.io/api/rbac/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
)

// extraNamespaceRoles and extraNamespaceRoleBindings are used to give permission to prometheus to scrape metrics
// from endpoints in other namespaces.
func role() []runtime.Object {
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
	}
}

func configRoleName() string {
	return fmt.Sprintf("%s-config", resourceName())
}
