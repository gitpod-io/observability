package alertmanager

import "fmt"

const (
	Name      = "main"
	App       = "monitoring-satellite"
	Version   = "0.24.0"
	Namespace = "monitoring-satellite"
	ImageURL  = "quay.io/prometheus/alertmanager"
	Component = "alert-router"
)

func resourceName() string {
	return fmt.Sprintf("alertmanager-%s", Name)
}
