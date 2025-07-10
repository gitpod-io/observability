package certmanager

var (
	Namespace = "certmanager"
)

const (
	ServiceMonitorNamespace = "monitoring-satellite"
	App                     = "certmanager"
	Component               = "certmanager"
)

var (
	matchLabels = map[string]string{
		"app.kubernetes.io/component": "prometheus",
		"app.kubernetes.io/instance":  "k8s",
		"app.kubernetes.io/name":      "prometheus",
		"app.kubernetes.io/part-of":   "kube-prometheus",
		"app.kubernetes.io/version":   "2.48.1",
	}
)

func labels() map[string]string {
	return map[string]string{
		"app.kubernetes.io/component": Component,
		"app.kubernetes.io/name":      App,
		"app.kubernetes.io/part-of":   "kube-prometheus",
	}
}
