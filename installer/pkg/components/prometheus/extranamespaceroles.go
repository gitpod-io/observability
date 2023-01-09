package prometheus

import (
	rbacv1 "k8s.io/api/rbac/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"

	"github.com/gitpod-io/observability/installer/pkg/common"
	"github.com/gitpod-io/observability/installer/pkg/components/certmanager"
)

// extraNamespaceRoles and extraNamespaceRoleBindings are used to give permission to prometheus to scrape metrics
// from endpoints in other namespaces.
// TODO: Add more namespaces from configuration
func extraNamespaceRoles(ctx *common.RenderContext) ([]runtime.Object, error) {
	var extraRoles []runtime.Object

	extraRoles = append(extraRoles,
		roleFactory(Namespace),
		roleFactory("default"),
		roleFactory("kube-system"),
	)

	if ctx.Config.Werft.InstallServiceMonitors {
		extraRoles = append(extraRoles, roleFactory("werft"))
	}

	if ctx.Config.Certmanager.InstallServiceMonitors {
		extraRoles = append(extraRoles, roleFactory(certmanager.Namespace))
	}

	return extraRoles, nil
}

func roleFactory(ns string) *rbacv1.Role {
	return &rbacv1.Role{
		TypeMeta: metav1.TypeMeta{
			APIVersion: "rbac.authorization.k8s.io/v1",
			Kind:       "Role",
		},
		ObjectMeta: metav1.ObjectMeta{
			Name:      resourceName(),
			Namespace: ns,
			Labels:    common.Labels(Name, Component, App, Version),
		},
		Rules: []rbacv1.PolicyRule{
			{
				APIGroups: []string{""},
				Resources: []string{"services", "endpoints", "pods"},
				Verbs:     []string{"get", "list", "watch"},
			},
			{
				APIGroups: []string{"extensions"},
				Resources: []string{"ingresses"},
				Verbs:     []string{"get", "list", "watch"},
			},
			{
				APIGroups: []string{"networking.k8s.io"},
				Resources: []string{"ingresses"},
				Verbs:     []string{"get", "list", "watch"},
			},
		},
	}
}
