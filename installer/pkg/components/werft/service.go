package werft

import (
	"fmt"

	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"

	"github.com/gitpod-io/observability/installer/pkg/common"
)

func service(ctx *common.RenderContext) ([]runtime.Object, error) {
	return []runtime.Object{
		&corev1.Service{
			TypeMeta: common.ServiceType,
			ObjectMeta: metav1.ObjectMeta{
				Name:      fmt.Sprintf("%s-metrics", App),
				Namespace: Namespace,
				Labels:    labels(),
			},
			Spec: corev1.ServiceSpec{
				Ports: []corev1.ServicePort{
					{
						Name: "metrics",
						Port: 9500,
					},
				},
				Selector: map[string]string{
					"component": Component,
				},
			},
		},
	}, nil
}
