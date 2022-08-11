// Copyright (c) 2021 Gitpod GmbH. All rights reserved.
// Licensed under the GNU Affero General Public License (AGPL).
// See License-AGPL.txt in the project root for license information.

package config

import (
	monitoringv1 "github.com/prometheus-operator/prometheus-operator/pkg/apis/monitoring/v1"
	corev1 "k8s.io/api/core/v1"
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

	cfg.Alerting = &Alerting{
		Config: map[string]interface{}{},
	}

	cfg.Tracing = &Tracing{
		Install: false,
	}

	cfg.Pyrra = &Pyrra{
		Install: false,
	}

	cfg.Prober = &Prober{
		Install: false,
	}

	cfg.Werft = &Werft{
		InstallServiceMonitors: false,
	}

	cfg.Gitpod = &Gitpod{
		InstallServiceMonitors: true,
	}

	cfg.Prometheus = &Prometheus{
		RemoteWrite: []*RemoteWrite{
			{
				RemoteWriteSpec: monitoringv1.RemoteWriteSpec{
					URL: "https://example.com",
				},
				Username: "user",
				Password: "password",
			},
		},
	}

	return nil
}

// Config defines the structure of the observability config file
type Config struct {
	Namespace    string            `json:"namespace"`
	Tracing      *Tracing          `json:"tracing,omitempty"`
	Alerting     *Alerting         `json:"alerting,omitempty"`
	NodeSelector map[string]string `json:"nodeSelector,omitempty"`
	Prometheus   *Prometheus       `json:"prometheus,omitempty"`
	Pyrra        *Pyrra            `json:"pyrra,omitempty"`
	Prober       *Prober           `json:"prober,omitempty"`
	Werft        *Werft            `json:"werft,omitempty"`
	Gitpod       *Gitpod           `json:"gitpod,omitempty"`
}

type Tracing struct {
	Install          bool   `json:"install"`
	HoneycombAPIKey  string `json:"honeycombAPIKey,omitempty"`
	HoneycombDataset string `json:"honeycombDataset,omitempty"`
}

type Alerting struct {
	Config map[string]interface{} `json:"config"`
}

type Prometheus struct {
	ExternalLabels map[string]string           `json:"externalLabels,omitempty"`
	EnableFeatures []string                    `json:"enableFeatures,omitempty"`
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
