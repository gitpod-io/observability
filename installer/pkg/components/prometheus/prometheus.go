package prometheus

import (
	"fmt"

	monitoringv1 "github.com/prometheus-operator/prometheus-operator/pkg/apis/monitoring/v1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/util/intstr"
	"k8s.io/utils/pointer"

	"github.com/gitpod-io/observability/installer/pkg/common"
)

func prometheus(ctx *common.RenderContext) ([]runtime.Object, error) {
	objs := remoteWriteSecrets(ctx)

	serviceAccountName := fmt.Sprintf("prometheus-%s", Name)
	if ctx.Config.Prometheus.ServiceAccountName != "" {
		serviceAccountName = ctx.Config.Prometheus.ServiceAccountName
	}

	objs = append(objs, &monitoringv1.Prometheus{
		TypeMeta: metav1.TypeMeta{
			APIVersion: "monitoring.coreos.com/v1",
			Kind:       "Prometheus",
		},
		ObjectMeta: metav1.ObjectMeta{
			Name:      Name,
			Namespace: Namespace,
			Labels:    common.Labels(Name, Component, App, Version),
		},
		Spec: monitoringv1.PrometheusSpec{
			Alerting: &monitoringv1.AlertingSpec{
				Alertmanagers: []monitoringv1.AlertmanagerEndpoints{
					{
						APIVersion: "v2",
						// TODO: get name from alertmanager's service form alertmanager pkg
						Name:      "alertmanager-main",
						Namespace: Namespace,
						Port:      intstr.FromString("web"),
					},
				},
			},
			RuleSelector: &metav1.LabelSelector{},
			CommonPrometheusFields: monitoringv1.CommonPrometheusFields{
				Tolerations: ctx.Config.Tolerations,
				Image:       pointer.String(fmt.Sprintf("%s:v%s", ImageURL, Version)),
				PodMetadata: &monitoringv1.EmbeddedObjectMetadata{
					Labels: common.Labels(Name, Component, App, Version),
				},
				Replicas: pointer.Int32(1),
				SecurityContext: &corev1.PodSecurityContext{
					FSGroup:      pointer.Int64(2000),
					RunAsUser:    pointer.Int64(1000),
					RunAsNonRoot: pointer.Bool(true),
				},
				ExternalLabels:         ctx.Config.Prometheus.ExternalLabels,
				EnableFeatures:         ctx.Config.Prometheus.EnableFeatures,
				Resources:              ctx.Config.Prometheus.Resources,
				NodeSelector:           ctx.Config.NodeSelector,
				RemoteWrite:            remoteWriteSpecs(ctx),
				Version:                Version,
				ServiceMonitorSelector: &metav1.LabelSelector{},
				PodMonitorSelector:     &metav1.LabelSelector{},
				ServiceAccountName:     serviceAccountName,
			},
		},
	})

	return objs, nil
}

func remoteWriteSecrets(ctx *common.RenderContext) []runtime.Object {
	var secrets []runtime.Object

	for i, rw := range ctx.Config.Prometheus.RemoteWrite {
		if rw.Username == "" && rw.Password == "" {
			continue
		}

		secrets = append(secrets, &corev1.Secret{
			TypeMeta: metav1.TypeMeta{
				APIVersion: "v1",
				Kind:       "Secret",
			},
			ObjectMeta: metav1.ObjectMeta{
				Name:      fmt.Sprintf("remote-write-secret-%d", i),
				Namespace: Namespace,
				Labels:    common.Labels(Name, Component, App, Version),
			},
			StringData: map[string]string{
				"password": rw.Password,
				"username": rw.Username,
			},
		})
	}

	return secrets
}

func remoteWriteSpecs(ctx *common.RenderContext) []monitoringv1.RemoteWriteSpec {
	var specs []monitoringv1.RemoteWriteSpec

	for i, rw := range ctx.Config.Prometheus.RemoteWrite {
		if rw.Username != "" && rw.Password != "" {
			rw.BasicAuth = &monitoringv1.BasicAuth{
				Username: corev1.SecretKeySelector{
					Key: "username",
					LocalObjectReference: corev1.LocalObjectReference{
						Name: fmt.Sprintf("remote-write-secret-%d", i),
					},
				},
				Password: corev1.SecretKeySelector{
					Key: "password",
					LocalObjectReference: corev1.LocalObjectReference{
						Name: fmt.Sprintf("remote-write-secret-%d", i),
					},
				},
			}
		}

		specs = append(specs, *rw.DeepCopy())
	}

	return specs
}
