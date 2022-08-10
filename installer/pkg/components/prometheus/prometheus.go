package prometheus

import (
	"fmt"

	"github.com/gitpod-io/observability/installer/pkg/common"
	monitoringv1 "github.com/prometheus-operator/prometheus-operator/pkg/apis/monitoring/v1"
	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/util/intstr"
	"k8s.io/utils/pointer"
)

func prometheus(ctx *common.RenderContext) ([]runtime.Object, error) {
	return []runtime.Object{
		&monitoringv1.Prometheus{
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
				CommonPrometheusFields: monitoringv1.CommonPrometheusFields{
					Image: pointer.String(fmt.Sprintf("%s:v%s", ImageURL, Version)),
					PodMetadata: &monitoringv1.EmbeddedObjectMetadata{
						Labels: common.Labels(Name, Component, App, Version),
					},
					Replicas: pointer.Int32(1),
					SecurityContext: &v1.PodSecurityContext{
						FSGroup:      pointer.Int64(2000),
						RunAsUser:    pointer.Int64(1000),
						RunAsNonRoot: pointer.Bool(true),
					},
					ServiceAccountName: fmt.Sprintf("prometheus-%s", Name),
					ServiceMonitorNamespaceSelector: &metav1.LabelSelector{
						MatchLabels: map[string]string{
							"kubernetes.io/metadata.name": Namespace,
						},
					},
				},
				RuleNamespaceSelector: &metav1.LabelSelector{
					MatchLabels: map[string]string{
						"kubernetes.io/metadata.name": Namespace,
					},
				},

				// Here is a list of fields that aren't enabled for every deployment
				// but should be configurable once we have a way to read configuration from a file.
				// TODO: Implement logic below with the proper configuration file;
				// CommonPrometheusFields: monitoringv1.CommonPrometheusFields{
				// 	ExternalLabels: map[string]string{
				// 		"cluster": "example-cluster",
				// 	},
				// Resources: {},
				// 	EnableFeatures: []string{"remote-write-receiver"},
				// 	NodeSelector: map[string]string{
				// 		"nodepool": "example",
				// 	},
				// 	RemoteWrite: []monitoringv1.RemoteWriteSpec{
				// 		{
				// 			URL: "https://example-remote-write-url.com",
				// 			BasicAuth: &monitoringv1.BasicAuth{
				// 				Username: v1.SecretKeySelector{
				// 					Key: "username",
				// 					LocalObjectReference: v1.LocalObjectReference{
				// 						Name: "remote-write-auth",
				// 					},
				// 				},
				// 				Password: v1.SecretKeySelector{
				// 					Key: "password",
				// 					LocalObjectReference: v1.LocalObjectReference{
				// 						Name: "remote-write-auth",
				// 					},
				// 				},
				// 			},
				// 			WriteRelabelConfigs: []monitoringv1.RelabelConfig{},
				// 		},
				// 	},
				// },
			},
		},
	}, nil
}
