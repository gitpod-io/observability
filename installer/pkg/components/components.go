package components

import (
	"github.com/gitpod-io/observability/installer/pkg/common"
	"github.com/gitpod-io/observability/installer/pkg/components/alertmanager"
	certmanager "github.com/gitpod-io/observability/installer/pkg/components/cert-manager"
	"github.com/gitpod-io/observability/installer/pkg/components/gitpod"
	"github.com/gitpod-io/observability/installer/pkg/components/kubernetes"
	kubestateMetrics "github.com/gitpod-io/observability/installer/pkg/components/kubestate-metrics"
	nodeExporter "github.com/gitpod-io/observability/installer/pkg/components/node-exporter"
	otelCollector "github.com/gitpod-io/observability/installer/pkg/components/otel-collector"
	"github.com/gitpod-io/observability/installer/pkg/components/prometheus"
	prometheusoperator "github.com/gitpod-io/observability/installer/pkg/components/prometheus-operator"
	"github.com/gitpod-io/observability/installer/pkg/components/pyrra"
	"github.com/gitpod-io/observability/installer/pkg/components/shared"
	"github.com/gitpod-io/observability/installer/pkg/components/werft"
)

func MonitoringCentralObjects(ctx *common.RenderContext) common.RenderFunc {
	return common.CompositeRenderFunc(pyrra.Objects(ctx))
}

func MonitoringSatelliteObjects(ctx *common.RenderContext) common.RenderFunc {
	return common.CompositeRenderFunc(
		alertmanager.Objects,
		kubestateMetrics.Objects,
		nodeExporter.Objects,
		prometheusoperator.Objects,
		otelCollector.Objects(ctx),
		prometheus.Objects,
		pyrra.Objects(ctx),
		werft.Objects(ctx),
		gitpod.Objects(ctx),
		certmanager.Objects(ctx),
		kubernetes.Objects,
		shared.Objects,
	)
}
