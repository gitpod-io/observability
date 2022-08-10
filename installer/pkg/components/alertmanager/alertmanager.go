package alertmanager

import (
	"fmt"

	v1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/resource"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/utils/pointer"

	"github.com/gitpod-io/observability/installer/pkg/common"
	monitoringv1 "github.com/prometheus-operator/prometheus-operator/pkg/apis/monitoring/v1"
)

func alertmanager(ctx *common.RenderContext) ([]runtime.Object, error) {
	return []runtime.Object{
		&monitoringv1.Alertmanager{
			TypeMeta: metav1.TypeMeta{
				APIVersion: "monitoring.coreos.com/v1",
				Kind:       "Alertmanager",
			},
			ObjectMeta: metav1.ObjectMeta{
				Name:      Name,
				Namespace: Namespace,
				Labels:    common.Labels(Name, Component, App, Version),
			},
			Spec: monitoringv1.AlertmanagerSpec{
				Image: pointer.String(fmt.Sprintf("%s:v%s", ImageURL, Version)),
				PodMetadata: &monitoringv1.EmbeddedObjectMetadata{
					Labels: common.Labels(Name, Component, App, Version),
				},
				Replicas: pointer.Int32(1),
				Resources: v1.ResourceRequirements{
					Requests: v1.ResourceList{
						v1.ResourceCPU:    resource.MustParse("4m"),
						v1.ResourceMemory: resource.MustParse("100Mi"),
					},
				},
				SecurityContext: &v1.PodSecurityContext{
					FSGroup:      pointer.Int64(2000),
					RunAsUser:    pointer.Int64(1000),
					RunAsNonRoot: pointer.Bool(true),
				},
				ServiceAccountName: fmt.Sprintf("alertmanager-%s", Name),
				Version:            Version,

				// TODO: Load all below from config file
				// NodeSelector: map[string]string{
				// 	"nodepool": "example",
				// },
			},
		},
	}, nil
}
