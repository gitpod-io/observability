package alertmanager

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
			TypeMeta: metav1.TypeMeta{
				APIVersion: "v1",
				Kind:       "Service",
			},
			ObjectMeta: metav1.ObjectMeta{
				Name:      resourceName(),
				Namespace: Namespace,
				Labels:    common.Labels(Name, Component, App, Version),
			},
			Spec: corev1.ServiceSpec{
				Ports: []corev1.ServicePort{
					{
						Name:       "web",
						Port:       9093,
						TargetPort: intstr.IntOrString{IntVal: 9093},
					},
					{
						Name:       "reloader-web",
						Port:       8080,
						TargetPort: intstr.IntOrString{IntVal: 8080},
					},
				},
				Selector: common.Labels(Name, Component, App, Version),
			},
		},
	}
}