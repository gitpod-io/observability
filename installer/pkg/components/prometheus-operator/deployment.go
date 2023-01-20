package prometheusoperator

import (
	"fmt"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/resource"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/utils/pointer"

	"github.com/gitpod-io/observability/installer/pkg/common"
)

func deployment(ctx *common.RenderContext) ([]runtime.Object, error) {
	return []runtime.Object{
		&appsv1.Deployment{
			TypeMeta: metav1.TypeMeta{
				APIVersion: "apps/v1",
				Kind:       "Deployment",
			},
			ObjectMeta: metav1.ObjectMeta{
				Name:      Name,
				Namespace: Namespace,
				Labels:    common.Labels(Name, Component, App, Version),
			},
			Spec: appsv1.DeploymentSpec{

				Selector: &metav1.LabelSelector{MatchLabels: common.Labels(Name, Component, App, Version)},
				Replicas: pointer.Int32(1),
				Template: corev1.PodTemplateSpec{

					ObjectMeta: metav1.ObjectMeta{
						Labels: common.Labels(Name, Component, App, Version),
						Annotations: map[string]string{
							"kubectl.kubernetes.io/default-container": "prometheus-operator",
						},
					},
					Spec: corev1.PodSpec{
						Tolerations:                  ctx.Config.Tolerations,
						NodeSelector:                 ctx.Config.NodeSelector,
						AutomountServiceAccountToken: pointer.Bool(true),
						SecurityContext: &corev1.PodSecurityContext{
							RunAsNonRoot: common.ToPointer(true),
							RunAsUser:    common.ToPointer(int64(65534)),
						},
						ServiceAccountName: Name,
						Containers: []corev1.Container{{
							Name:  Name,
							Image: fmt.Sprintf("%s:v%s", ImageURL, Version),
							Args: []string{
								"--kubelet-service=kube-system/kubelet",
								fmt.Sprintf("--prometheus-config-reloader=quay.io/prometheus-operator/prometheus-config-reloader:v%s", Version),
							},
							Ports: []corev1.ContainerPort{{
								ContainerPort: 8080,
								Name:          "http",
							}},
							Resources: corev1.ResourceRequirements{
								Limits: corev1.ResourceList{
									corev1.ResourceMemory: resource.MustParse("1000Mi"),
								},
								Requests: corev1.ResourceList{
									corev1.ResourceCPU:    resource.MustParse("100m"),
									corev1.ResourceMemory: resource.MustParse("100Mi"),
								},
							},
							SecurityContext: &corev1.SecurityContext{
								AllowPrivilegeEscalation: pointer.Bool(false),
								Capabilities: &corev1.Capabilities{
									Drop: []corev1.Capability{"ALL"},
								},
								ReadOnlyRootFilesystem: pointer.Bool(true),
							},
						},
							{
								Name:  "kube-rbac-proxy",
								Image: "quay.io/brancz/kube-rbac-proxy:v0.13.0",
								Args: []string{
									"--logtostderr",
									"--secure-listen-address=:8443",
									"--tls-cipher-suites=TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305",
									"--upstream=http://127.0.0.1:8080/",
								},
								Ports: []corev1.ContainerPort{
									{Name: "https", ContainerPort: 8443},
								},
								Resources: corev1.ResourceRequirements{
									Limits: corev1.ResourceList{
										corev1.ResourceCPU:    resource.MustParse("20m"),
										corev1.ResourceMemory: resource.MustParse("40Mi"),
									},
									Requests: corev1.ResourceList{
										corev1.ResourceCPU:    resource.MustParse("10m"),
										corev1.ResourceMemory: resource.MustParse("20Mi"),
									},
								},
								SecurityContext: &corev1.SecurityContext{
									AllowPrivilegeEscalation: pointer.Bool(false),
									ReadOnlyRootFilesystem:   pointer.Bool(true),
									RunAsUser:                pointer.Int64(65532),
									RunAsGroup:               pointer.Int64(65532),
									RunAsNonRoot:             pointer.Bool(true),
									Capabilities: &corev1.Capabilities{
										Drop: []corev1.Capability{"ALL"},
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
