package pyrra

import (
	"github.com/gitpod-io/observability/installer/pkg/common"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/util/intstr"
)

func service() []runtime.Object {
	return []runtime.Object{
		&corev1.Service{
			TypeMeta: common.ServiceType,
			ObjectMeta: metav1.ObjectMeta{
				Name:      componentName(apiComponent),
				Namespace: Namespace,
				Labels:    pyrraLabels(apiComponent),
			},
			Spec: corev1.ServiceSpec{
				Ports: []corev1.ServicePort{
					{
						Name:       "http",
						Port:       9099,
						TargetPort: intstr.IntOrString{IntVal: 9099},
					},
				},
				Selector: pyrraLabels(apiComponent),
			},
		},
		&corev1.Service{
			TypeMeta: common.ServiceType,
			ObjectMeta: metav1.ObjectMeta{
				Name:      componentName(kubernetesComponent),
				Namespace: Namespace,
				Labels:    pyrraLabels(kubernetesComponent),
			},
			Spec: corev1.ServiceSpec{
				Ports: []corev1.ServicePort{
					{
						Name:       "http",
						Port:       9444,
						TargetPort: intstr.IntOrString{IntVal: 9444},
					},
				},
				Selector: pyrraLabels(kubernetesComponent),
			},
		},
	}
}
