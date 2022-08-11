package kubestatemetrics

const (
	Name        = "kube-state-metrics"
	App         = "kube-prometheus"
	Version     = "2.5.0"
	Namespace   = "monitoring-satellite"
	Component   = "exporter"
	ImageURL    = "k8s.gcr.io/kube-state-metrics/kube-state-metrics"
	rbacURL     = "quay.io/brancz/kube-rbac-proxy"
	rbacVersion = "0.13.0"
)
