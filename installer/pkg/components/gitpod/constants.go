package gitpod

const (
	GitpodNamespace = "default"
	Namespace       = "monitoring-satellite"
	App             = "gitpod"
)

var (
	matchLabels = map[string]string{
		"app.kubernetes.io/component": "prometheus",
		"app.kubernetes.io/instance":  "k8s",
		"app.kubernetes.io/name":      "prometheus",
		"app.kubernetes.io/part-of":   "kube-prometheus",
		"app.kubernetes.io/version":   "2.48.1",
	}
	targets = []string{
		"agent-smith",
		"blobserve",
		"containerd-metrics",
		"content-service",
		"ide-metrics",
		"ide-service",
		"image-builder-mk3",
		"node-labeler",
		"openvsx-proxy",
		"public-api-server",
		"registry-facade",
		"proxy",
		"redis",
		"server",
		"slow-server",
		"spicedb",
		"usage",
		"ws-daemon",
		"ws-manager-bridge",
		"ws-manager",
		"ws-manager-mk2",
		"ws-proxy",
	}
)

func labels(target string) map[string]string {
	return map[string]string{
		"app.kubernetes.io/component": target,
		"app.kubernetes.io/name":      App,
		"app.kubernetes.io/part-of":   "kube-prometheus",
	}
}
