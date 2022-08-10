package prometheusOperator

import (
	"github.com/gitpod-io/observability/installer/pkg/common"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/util/intstr"
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
						Name:       "https",
						Port:       8443,
						TargetPort: intstr.IntOrString{IntVal: 8443},
					},
				},
				Selector: common.Labels(Name, Component, App, Version),
			},
		},
	}, nil
}
