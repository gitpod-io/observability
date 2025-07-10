package prometheus

import "fmt"

const (
	Name      = "k8s"
	App       = "kube-prometheus"
	Version   = "2.55.1"
	Namespace = "monitoring-satellite"
	ImageURL  = "quay.io/prometheus/prometheus"
	Component = "prometheus"
)

func resourceName() string {
	return fmt.Sprintf("prometheus-%s", Name)
}
