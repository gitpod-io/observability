package prometheusOperator

import (
	"github.com/gitpod-io/observability/installer/pkg/common"
)

const (
	Name      = "prometheus-operator"
	App       = "monitoring-satellite"
	Version   = "0.58.0"
	Namespace = "monitoring-satellite"
	ImageURL  = "quay.io/prometheus-operator/prometheus-operator"
	Component = "controller"
)

func prometheusOperatorLabels() map[string]string {
	return common.Labels(Name, Component, App, Version)
}
