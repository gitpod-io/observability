package pyrra

import (
	"fmt"

	"github.com/gitpod-io/observability/installer/pkg/common"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/utils/pointer"
)

const (
	apiComponent        = "api"
	kubernetesComponent = "kubernetes"
)

func replicas() *int32 {
	replicas := int32(1)
	return &replicas
}

func deployment() []runtime.Object {
	return []runtime.Object{
		&appsv1.Deployment{
			TypeMeta: common.DeploymentType,
			ObjectMeta: metav1.ObjectMeta{
				Name:      Name,
				Namespace: Namespace,
				Labels:    pyrraLabels(apiComponent),
			},
			Spec: appsv1.DeploymentSpec{
				Selector: &metav1.LabelSelector{MatchLabels: pyrraLabels(apiComponent)},
				Replicas: replicas(),
				Strategy: common.DeploymentStrategy(1, 1),
				Template: corev1.PodTemplateSpec{
					ObjectMeta: metav1.ObjectMeta{
						Name:      Name,
						Namespace: Namespace,
						Labels:    pyrraLabels(apiComponent),
					},
					Spec: corev1.PodSpec{
						Containers: []corev1.Container{{
							Name:            Name,
							Image:           fmt.Sprintf("%s:v%s", ImageURL, Version),
							ImagePullPolicy: corev1.PullIfNotPresent,
							Args: []string{
								"api",
								"--api-url=http://pyrra-kubernetes.monitoring-central.svc.cluster.local:9444",
								"--prometheus-url=http://victoriametrics.monitoring-central.svc.cluster.local:8428",
							},
							Ports: []corev1.ContainerPort{{
								ContainerPort: 9099,
							}},
							SecurityContext: &corev1.SecurityContext{
								AllowPrivilegeEscalation: pointer.Bool(false),
								ReadOnlyRootFilesystem:   pointer.Bool(true),
							},
						}},
					},
				},
			},
		},
		&appsv1.Deployment{
			TypeMeta: common.DeploymentType,
			ObjectMeta: metav1.ObjectMeta{
				Name:      Name,
				Namespace: Namespace,
				Labels:    pyrraLabels(kubernetesComponent),
			},
			Spec: appsv1.DeploymentSpec{
				Selector: &metav1.LabelSelector{MatchLabels: pyrraLabels(kubernetesComponent)},
				Replicas: replicas(),
				Strategy: common.DeploymentStrategy(1, 1),
				Template: corev1.PodTemplateSpec{
					ObjectMeta: metav1.ObjectMeta{
						Name:      Name,
						Namespace: Namespace,
						Labels:    pyrraLabels(kubernetesComponent),
					},
					Spec: corev1.PodSpec{
						ServiceAccountName: "pyrra-kubernetes",
						Containers: []corev1.Container{{
							Name:            Name,
							Image:           fmt.Sprintf("%s:v%s", ImageURL, Version),
							ImagePullPolicy: corev1.PullIfNotPresent,
							Args:            []string{"kubernetes"},
							Ports: []corev1.ContainerPort{{
								ContainerPort: 9099,
							}},
							SecurityContext: &corev1.SecurityContext{
								AllowPrivilegeEscalation: pointer.Bool(false),
								ReadOnlyRootFilesystem:   pointer.Bool(true),
							},
						}},
					},
				},
			},
		},
	}
}
