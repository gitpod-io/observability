package pyrra

import (
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
)

func serviceAccount() []runtime.Object {
	return []runtime.Object{
		&corev1.ServiceAccount{
			TypeMeta: metav1.TypeMeta{
				APIVersion: "apps/v1",
				Kind:       "ServiceAccount",
			},
			ObjectMeta: metav1.ObjectMeta{
				Name:      componentName(kubernetesComponent),
				Namespace: Namespace,
				Labels:    pyrraLabels(kubernetesComponent),
			},
		},
	}
}
