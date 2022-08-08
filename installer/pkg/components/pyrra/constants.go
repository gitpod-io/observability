package pyrra

import (
	"fmt"

	"github.com/gitpod-io/observability/installer/pkg/common"
)

const (
	Name      = "pyrra"
	App       = "kube-prometheus"
	Version   = "0.4.4"
	Namespace = "monitoring-satellite"
	ImageURL  = "ghcr.io/pyrra-dev/pyrra"
)

func pyrraLabels(component string) map[string]string {
	return common.Labels(Name, component, App, Version)
}

func componentName(component string) string {
	return fmt.Sprintf("%s-%s", Name, component)
}
