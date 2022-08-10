package otelCollector

import (
	"github.com/gitpod-io/observability/installer/pkg/common"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
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
						ServiceAccountName: Name,
						Containers: []corev1.Container{{
							Name:            Name,
							Image:           common.ImageName(ctx.Config.Components.OtelCollector.Repository, ctx.Config.Components.OtelCollector.Version),
							ImagePullPolicy: corev1.PullIfNotPresent,
							Args: []string{
								"--config=/conf/collector.yaml",
							},
						}},
						NodeSelector: map[string]string{
							"kubernetes.io/os": "linux",
							"nodepool":         "monitoring",
						},
						Volumes: []corev1.Volume{
							{
								Name: Name,
								VolumeSource: corev1.VolumeSource{
									ConfigMap: &corev1.ConfigMapVolumeSource{
										LocalObjectReference: corev1.LocalObjectReference{Name: Name},
										Items: []corev1.KeyToPath{
											{
												Key:  "collector.yaml",
												Path: "collector.yaml",
											},
										},
									},
								},
							},
						},
					},
				},
			},
		},
	}, nil
}