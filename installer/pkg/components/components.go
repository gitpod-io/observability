package components

import (
	"github.com/gitpod-io/observability/installer/pkg/common"
	"github.com/gitpod-io/observability/installer/pkg/components/alertmanager"
	certManager "github.com/gitpod-io/observability/installer/pkg/components/cert-manager"
	"github.com/gitpod-io/observability/installer/pkg/components/gitpod"
	kubestateMetrics "github.com/gitpod-io/observability/installer/pkg/components/kubestate-metrics"
	nodeExporter "github.com/gitpod-io/observability/installer/pkg/components/node-exporter"
	otelCollector "github.com/gitpod-io/observability/installer/pkg/components/otel-collector"
	"github.com/gitpod-io/observability/installer/pkg/components/prometheus"
	prometheusoperator "github.com/gitpod-io/observability/installer/pkg/components/prometheus-operator"
	"github.com/gitpod-io/observability/installer/pkg/components/pyrra"
	"github.com/gitpod-io/observability/installer/pkg/components/werft"
	"github.com/gitpod-io/observability/installer/pkg/importer"
)

func MonitoringCentralObjects(ctx *common.RenderContext) common.RenderFunc {
	return common.CompositeRenderFunc(pyrra.Objects(ctx))
}

func MonitoringSatelliteObjects(ctx *common.RenderContext) common.RenderFunc {
	mixinImporter := importer.NewMixinImporter("https://github.com/gitpod-io/observability", "")

	return common.CompositeRenderFunc(
		alertmanager.Objects,
		kubestateMetrics.Objects,
		mixinImporter.ImportPrometheusRules,
		nodeExporter.Objects,
		prometheusoperator.Objects,
		otelCollector.Objects(ctx),
		prometheus.Objects,
		pyrra.Objects(ctx),
		werft.Objects(ctx),
		gitpod.Objects(ctx),
		certManager.Objects,
	)
}
