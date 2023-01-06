// Copyright (c) 2021 Gitpod GmbH. All rights reserved.
// Licensed under the GNU Affero General Public License (AGPL).
// See License-AGPL.txt in the project root for license information.

package config

import (
	monitoringv1 "github.com/prometheus-operator/prometheus-operator/pkg/apis/monitoring/v1"
	corev1 "k8s.io/api/core/v1"

	"github.com/gitpod-io/observability/installer/pkg/importer"
)

func Factory() interface{} {
	return &Config{}
}

func Defaults(in interface{}) error {
	cfg, ok := in.(*Config)
	if !ok {
		return ErrInvalidType
	}

	cfg.Namespace = "monitoring-satellite"

	cfg.Alerting = &Alerting{}

	cfg.Tracing = &Tracing{
		Install:            false,
		TempoBasicUser:     "user",
		TempoBasicPassword: "password",
	}

	cfg.Pyrra = &Pyrra{}
	cfg.Prober = &Prober{}
	cfg.Werft = &Werft{}
	cfg.Certmanager = &Certmanager{}
	cfg.Grafana = &Grafana{}
	cfg.Imports = &Imports{}

	cfg.Gitpod = &Gitpod{
		InstallServiceMonitors: true,
	}

	cfg.Prometheus = &Prometheus{
		RemoteWrite: []*RemoteWrite{
			{
				RemoteWriteSpec: monitoringv1.RemoteWriteSpec{
					URL: "https://example.com",
				},
			},
		},
	}

	return nil
}

// Config defines the structure of the observability config file
type Config struct {
	Namespace    string              `json:"namespace"`
	Tracing      *Tracing            `json:"tracing,omitempty"`
	Alerting     *Alerting           `json:"alerting,omitempty"`
	NodeSelector map[string]string   `json:"nodeSelector,omitempty"`
	Tolerations  []corev1.Toleration `json:"tolerations,omitempty"`
	Prometheus   *Prometheus         `json:"prometheus,omitempty"`
	Pyrra        *Pyrra              `json:"pyrra,omitempty"`
	Prober       *Prober             `json:"prober,omitempty"`
	Werft        *Werft              `json:"werft,omitempty"`
	Gitpod       *Gitpod             `json:"gitpod,omitempty"`
	Grafana      *Grafana            `json:"grafana,omitempty"`
	Certmanager  *Certmanager        `json:"certmanager,omitempty"`
	Imports      *Imports            `json:"imports,omitempty"`
}

type Tracing struct {
	Install             bool              `json:"install"`
	HoneycombAPIKey     string            `json:"honeycombAPIKey,omitempty"`
	HoneycombDataset    string            `json:"honeycombDataset,omitempty"`
	TempoBasicUser      string            `json:"tempoBasicUser,omitempty"`
	TempoBasicPassword  string            `json:"tempoBasicPassword,omitempty"`
	ExtraSpanAttributes map[string]string `json:"extraSpanAttributes,omitempty"`
}

type Alerting struct {
	PagerDutyRoutingKey string              `json:"pagerdutyRoutingKey,omitempty"`
	SlackOAuthToken     string              `json:"slackOAuthToken"`
	GenericSlackChannel string              `json:"genericSlackChannel"`
	TeamRoutes          []TeamAlertingRoute `json:"teamRoutes,omitempty"`
}

type TeamAlertingRoute struct {
	TeamLabel    string `json:"teamLabel,omitempty"`
	SlackChannel string `json:"slackChannel,omitempty"`
}

type Prometheus struct {
	ExternalLabels map[string]string           `json:"externalLabels,omitempty"`
	EnableFeatures []string                    `json:"enableFeatures,omitempty"`
	MetricsToDrop  []string                    `json:"metricsToDrop,omitempty"`
	Ingress        *GoogleIAPBasedIngress      `json:"ingress,omitempty"`
	Resources      corev1.ResourceRequirements `json:"resources,omitempty"`
	RemoteWrite    []*RemoteWrite              `json:"remoteWrite,omitempty"`
}

type RemoteWrite struct {
	monitoringv1.RemoteWriteSpec
	Username string `json:"username"`
	Password string `json:"password"`
}

type GoogleIAPBasedIngress struct {
	DNS                  string
	GCPExternalIPAddress string
	IAPClientID          string
	IAPClientSecret      string
}

type Pyrra struct {
	Install bool                   `json:"install"`
	Ingress *GoogleIAPBasedIngress `json:"ingress,omitempty"`
}

type Prober struct {
	Install bool `json:"install"`
}

type Werft struct {
	InstallServiceMonitors bool `json:"installServiceMonitors"`
}

type Gitpod struct {
	InstallServiceMonitors bool `json:"installServiceMonitors"`
}

type Grafana struct {
	Install bool `json:"install"`
}

type Certmanager struct {
	InstallServiceMonitors bool   `json:"installServiceMonitors"`
	Namespace              string `json:"namespace,omitempty"`
}

type Imports struct {
	YAML      []importer.YAMLImporter      `json:"yaml,omitempty"`
	Kustomize []importer.KustomizeImporter `json:"kustomize,omitempty"`
}
