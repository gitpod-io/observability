package kubestatemetrics

import (
	"fmt"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/resource"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"

	"github.com/gitpod-io/observability/installer/pkg/common"
)

func rbacProxyContainerSpec(portName string, portNumber int32) corev1.Container {
	return corev1.Container{
		Name:            fmt.Sprintf("kube-rbac-proxy-%s", portName),
		Image:           fmt.Sprintf("%s:v%s", rbacURL, rbacVersion),
		ImagePullPolicy: corev1.PullIfNotPresent,
		Args: []string{
			"--logtostderr",
			"--secure-listen-address=:9443",
			"--tls-cipher-suites=TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305",
			fmt.Sprintf("--upstream=http://127.0.0.1:%d/", portNumber),
		},
		Resources: corev1.ResourceRequirements{
			Requests: corev1.ResourceList{
				"cpu":    resource.MustParse("20m"),
				"memory": resource.MustParse("20Mi"),
			},
			Limits: corev1.ResourceList{
				"cpu":    resource.MustParse("40m"),
				"memory": resource.MustParse("40Mi"),
			},
		},
		Ports: []corev1.ContainerPort{{
			ContainerPort: 8443,
			Name:          fmt.Sprintf("https-%s", portName),
		}},
		SecurityContext: &corev1.SecurityContext{
			AllowPrivilegeEscalation: common.ToPointer(false),
			Capabilities:             &corev1.Capabilities{Drop: []corev1.Capability{"ALL"}},
			ReadOnlyRootFilesystem:   common.ToPointer(true),
			RunAsUser:                common.ToPointer(int64(65532)),
			RunAsGroup:               common.ToPointer(int64(65532)),
		},
	}
}

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
				Strategy: common.DeploymentStrategy(1, 1),
				Template: corev1.PodTemplateSpec{
					ObjectMeta: metav1.ObjectMeta{
						Name:      Name,
						Namespace: Namespace,
						Labels:    common.Labels(Name, Component, App, Version),
					},
					Spec: corev1.PodSpec{
						ServiceAccountName:           Name,
						AutomountServiceAccountToken: common.ToPointer(true),
						NodeSelector:                 ctx.Config.NodeSelector,
						Containers: []corev1.Container{
							{
								Name:            Name,
								Image:           fmt.Sprintf("%s:v%s", ImageURL, Version),
								ImagePullPolicy: corev1.PullIfNotPresent,
								Args: []string{
									"--host=127.0.0.1",
									"--port=8081",
									"--telemetry-host=127.0.0.1",
									"--telemetry-port=8082",
									"--metric-labels-allowlist=nodes=[cloud.google.com/gke-nodepool,topology.kubernetes.io/region],pods=[component,workspaceType,owner,metaID]",
								},
								Resources: corev1.ResourceRequirements{
									Requests: corev1.ResourceList{
										"cpu":    resource.MustParse("10m"),
										"memory": resource.MustParse("190Mi"),
									},
								},
								SecurityContext: &corev1.SecurityContext{
									AllowPrivilegeEscalation: common.ToPointer(false),
									Capabilities:             &corev1.Capabilities{Drop: []corev1.Capability{"ALL"}},
									ReadOnlyRootFilesystem:   common.ToPointer(true),
									RunAsUser:                common.ToPointer(int64(65534)),
								},
							},
							rbacProxyContainerSpec("main", 8081),
							rbacProxyContainerSpec("self", 8082),
						},
					},
				},
			},
		},
	}, nil
}
