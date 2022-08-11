package kubestatemetrics

import (
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/util/intstr"

	"github.com/gitpod-io/observability/installer/pkg/common"
)

func service(ctx *common.RenderContext) ([]runtime.Object, error) {
	return []runtime.Object{
		&corev1.Service{
			TypeMeta: metav1.TypeMeta{
				APIVersion: "v1",
				Kind:       "Service",
			},
			ObjectMeta: metav1.ObjectMeta{
				Name:      Name,
				Namespace: Namespace,
				Labels:    common.Labels(Name, Component, App, Version),
			},
			Spec: corev1.ServiceSpec{
				Ports: []corev1.ServicePort{
					{
						Name:       "https-main",
						Port:       8443,
						TargetPort: intstr.FromString("https-main"),
					},
					{
						Name:       "https-self",
						Port:       9443,
						TargetPort: intstr.FromString("https-self"),
					},
				},
				Selector: common.Labels(Name, Component, App, Version),
			},
		},
	}, nil
}
