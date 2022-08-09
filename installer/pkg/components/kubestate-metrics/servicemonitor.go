package kubestateMetrics

import (
	"github.com/gitpod-io/observability/installer/pkg/common"
	monitoringv1 "github.com/prometheus-operator/prometheus-operator/pkg/apis/monitoring/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
)

type replaceLabel struct {
	Source string
	Target string
}

func labelsReplaceAndDrop(replaceLabels []replaceLabel) []*monitoringv1.RelabelConfig {
	var configs []*monitoringv1.RelabelConfig
	for _, s := range replaceLabels {
		configs = append(configs, &monitoringv1.RelabelConfig{
			Action:       "replace",
			Regex:        "(.*)",
			Replacement:  "$1",
			SourceLabels: []monitoringv1.LabelName{monitoringv1.LabelName(s.Source)},
			TargetLabel:  s.Target,
		})
		configs = append(configs, &monitoringv1.RelabelConfig{
			Action: "labeldrop",
			Regex:  s.Source,
		})
	}
	return configs
}

func endpointConfig(portName string, configs []*monitoringv1.RelabelConfig) monitoringv1.Endpoint {
	return monitoringv1.Endpoint{
		BearerTokenFile: "/var/run/secrets/kubernetes.io/serviceaccount/token",
		Port:            portName,
		Interval:        "30s",
		Scheme:          "https",
		TLSConfig: &monitoringv1.TLSConfig{
			SafeTLSConfig: monitoringv1.SafeTLSConfig{
				InsecureSkipVerify: true,
			},
		},
		RelabelConfigs: configs,
	}
}

func serviceMonitor() []runtime.Object {
	configs := labelsReplaceAndDrop([]replaceLabel{
		{
			Source: "label_cloud_google_com_gke_nodepool",
			Target: "nodepool",
		},
		{
			Source: "label_topology_kubernetes_io_region",
			Target: "region",
		},
		{
			Source: "label_component",
			Target: "component",
		},
		{
			Source: "label_workspace_type",
			Target: "workspace_type",
		},
		{
			Source: "label_owner",
			Target: "owner",
		},
		{
			Source: "label_meta_id",
			Target: "metaID",
		},
	})

	return []runtime.Object{
		&monitoringv1.ServiceMonitor{
			TypeMeta: metav1.TypeMeta{
				APIVersion: "monitoring.coreos.com/v1",
				Kind:       "ServiceMonitor",
			},
			ObjectMeta: metav1.ObjectMeta{
				Name:      Name,
				Namespace: Namespace,
				Labels:    common.Labels(Name, Component, App, Version),
			},
			Spec: monitoringv1.ServiceMonitorSpec{
				Endpoints: []monitoringv1.Endpoint{
					endpointConfig("https-main", configs),
					endpointConfig("https-self", configs),
				},
				JobLabel: "app.kubernetes.io/name",
				Selector: metav1.LabelSelector{
					MatchLabels: common.Labels(Name, Component, App, Version),
				},
			},
		},
	}
}
