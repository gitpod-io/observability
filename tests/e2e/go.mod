module gitpod-io/observability/e2e-test

go 1.16

require (
	github.com/Jeffail/gabs v1.4.0
	github.com/pkg/errors v0.9.1
	github.com/prometheus/client_golang v1.11.0
	k8s.io/api v0.22.2 // indirect
	k8s.io/apimachinery v0.22.2
	k8s.io/client-go v1.5.2
)

replace k8s.io/client-go => k8s.io/client-go v0.22.2
