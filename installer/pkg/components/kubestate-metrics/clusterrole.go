package kubestateMetrics

import (
	"github.com/gitpod-io/observability/installer/pkg/common"
	rbacv1 "k8s.io/api/rbac/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
)

var (
	listWatchRBAC = []string{
		"list",
		"watch",
	}
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
					APIGroups: []string{""},
					Resources: []string{
						"configmaps",
						"secrets",
						"nodes",
						"pods",
						"services",
						"serviceaccounts",
						"resourcequotas",
						"replicationcontrollers",
						"limitranges",
						"persistentvolumeclaims",
						"persistentvolumes",
						"namespaces",
						"endpoints",
					},
					Verbs: listWatchRBAC,
				},
				{
					APIGroups: []string{"apps"},
					Resources: []string{
						"statefulsets",
						"daemonsets",
						"deployments",
						"replicasets",
					},
					Verbs: listWatchRBAC,
				},
				{
					APIGroups: []string{"batch"},
					Resources: []string{
						"jobs",
						"cronjobs",
					},
					Verbs: listWatchRBAC,
				},
				{
					APIGroups: []string{"autoscaling"},
					Resources: []string{"horizontalpodautoscalers"},
					Verbs:     listWatchRBAC,
				},
				{
					APIGroups: []string{"policy"},
					Resources: []string{"poddisruptionbudgets"},
					Verbs:     listWatchRBAC,
				},
				{
					APIGroups: []string{"certificates.k8s.io"},
					Resources: []string{"certificatesigningrequests"},
					Verbs:     listWatchRBAC,
				},
				{
					APIGroups: []string{"storage.k8s.io"},
					Resources: []string{
						"storageclasses",
						"volumeattachments",
					},
					Verbs: listWatchRBAC,
				},
				{
					APIGroups: []string{"admissionregistration.k8s.io"},
					Resources: []string{
						"mutatingwebhookconfigurations",
						"validatingwebhookconfigurations",
					},
					Verbs: listWatchRBAC,
				},
				{
					APIGroups: []string{"networking.k8s.io"},
					Resources: []string{
						"networkpolicies",
						"ingresses",
					},
					Verbs: listWatchRBAC,
				},
				{
					APIGroups: []string{"coordination.k8s.io"},
					Resources: []string{"leases"},
					Verbs:     listWatchRBAC,
				},
				{
					APIGroups: []string{"rbac.authorization.k8s.io"},
					Resources: []string{
						"clusterroles",
						"roles",
					},
					Verbs: listWatchRBAC,
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
					ResourceNames: []string{Name},
				},
			},
		},
	}, nil
}
