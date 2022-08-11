package certmanager

const (
	Namespace = "certmanager"
	App       = "certmanager"
	Component = "certmanager"
)

var (
	matchLabels = map[string]string{
		"app.kubernetes.io/component": "prometheus",
		"app.kubernetes.io/instance":  "k8s",
		"app.kubernetes.io/name":      "prometheus",
		"app.kubernetes.io/part-of":   "kube-prometheus",
		"app.kubernetes.io/version":   "2.37.0",
	}
)

func labels() map[string]string {
	return map[string]string{
		"app.kubernetes.io/component": Component,
		"app.kubernetes.io/name":      App,
		"app.kubernetes.io/part-of":   "kube-prometheus",
	}
}
