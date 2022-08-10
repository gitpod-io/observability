package otelCollector

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
				Type: "ClusterIP",
				Ports: []corev1.ServicePort{
					{
						Name:       "jaegar",
						Port:       14268,
						TargetPort: intstr.IntOrString{IntVal: 14268},
						Protocol:   "TCP",
					},
					{
						Name:       "grpc-otlp",
						Port:       4317,
						TargetPort: intstr.IntOrString{IntVal: 4317},
						Protocol:   "TCP",
					},
					{
						Name:       "metrics",
						Port:       8888,
						TargetPort: intstr.IntOrString{IntVal: 8888},
						Protocol:   "TCP",
					},
				},
				Selector: common.Labels(Name, Component, App, Version),
			},
		},
	}, nil
}
