package prometheus

import "fmt"

const (
	Name      = "k8s"
	App       = "monitoring-satellite"
	Version   = "2.37.0"
	Namespace = "monitoring-satellite"
	ImageURL  = "quay.io/prometheus/prometheus"
	Component = "prometheus"
)

func resourceName() string {
	return fmt.Sprintf("prometheus-%s", Name)
}
