package probers

import (
	"fmt"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"

	"github.com/gitpod-io/observability/installer/pkg/common"
)

func deployment(ctx *common.RenderContext) ([]runtime.Object, error) {
	return []runtime.Object{
		&appsv1.Deployment{
			TypeMeta: common.DeploymentType,
			ObjectMeta: metav1.ObjectMeta{
				Name:      Name,
				Namespace: Namespace,
				Labels:    common.Labels(Name, Component, App, Version),
			},
			Spec: appsv1.DeploymentSpec{
				Selector: &metav1.LabelSelector{MatchLabels: common.Labels(Name, Component, App, Version)},
				Replicas: common.ToPointer(int32(1)),
				Template: corev1.PodTemplateSpec{
					ObjectMeta: metav1.ObjectMeta{
						Name:      Name,
						Namespace: Namespace,
						Labels:    common.Labels(Name, Component, App, Version),
					},
					Spec: corev1.PodSpec{
						Containers: []corev1.Container{{
							Name:            Name,
							Image:           fmt.Sprintf("%s:v%s", ImageURL, Version),
							ImagePullPolicy: corev1.PullIfNotPresent,
						}},
						NodeSelector: ctx.Config.NodeSelector,
					},
				},
			},
		},
	}, nil
}
