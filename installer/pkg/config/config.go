// Copyright (c) 2021 Gitpod GmbH. All rights reserved.
// Licensed under the GNU Affero General Public License (AGPL).
// See License-AGPL.txt in the project root for license information.

package config

func Factory() interface{} {
	return &Config{}
}

func Defaults(in interface{}) error {
	cfg, ok := in.(*Config)
	if !ok {
		return ErrInvalidType
	}

	cfg.Components = &Components{
		AlertManager: Version{
			Version:    "0.24.0",
			Repository: "quay.io/prometheus/alertmanager",
		},
		NodeExporter: Version{
			Version:    "1.31.1",
			Repository: "quay.io/prometheus/node-exporter",
		},
		KubeStateMetrics: Version{
			Version:    "2.5.0",
			Repository: "k8s.gcr.io/kube-state-metrics/kube-state-metrics",
		},
		OtelCollector: Version{
			Version:    "0.38.0",
			Repository: "docker.io/otel/opentelemetry-collector",
		},
		Probers: Version{
			Version:    "0.0.1",
			Repository: "ghcr.io/arthursens/http-prober",
		},
		PrometheusOperator: Version{
			Version:    "0.58.0",
			Repository: "quay.io/prometheus-operator/prometheus-operator",
		},
		Prometheus: Version{
			Version:    "2.37.0",
			Repository: "quay.io/prometheus/prometheus",
		},
		Pyrra: Version{
			Version:    "0.4.4",
			Repository: "ghcr.io/pyrra-dev/pyrra",
		},
	}

	return nil
}

// Config defines the structure of the observability config file
type Config struct {
	Components *Components `json:"components,omitempty"`
}

type Components struct {
	AlertManager       Version `json:"alertManager"`
	NodeExporter       Version `json:"nodeExporter"`
	KubeStateMetrics   Version `json:"kubeStateMetrics"`
	OtelCollector      Version `json:"otelCollector"`
	Probers            Version `json:"probers"`
	PrometheusOperator Version `json:"prometheusOperator"`
	Prometheus         Version `json:"prometheus"`
	Pyrra              Version `json:"pyrra"`
}

type Version struct {
	Version    string
	Repository string
}
