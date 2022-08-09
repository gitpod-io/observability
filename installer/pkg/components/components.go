package components

import (
	"github.com/gitpod-io/observability/installer/pkg/common"
	"github.com/gitpod-io/observability/installer/pkg/components/alertmanager"
	kubestateMetrics "github.com/gitpod-io/observability/installer/pkg/components/kubestate-metrics"
	nodeExporter "github.com/gitpod-io/observability/installer/pkg/components/node-exporter"
	otelCollector "github.com/gitpod-io/observability/installer/pkg/components/otel-collector"
	"github.com/gitpod-io/observability/installer/pkg/components/prometheusOperator"
	"github.com/gitpod-io/observability/installer/pkg/components/pyrra"
	"github.com/gitpod-io/observability/installer/pkg/importer"
	"k8s.io/apimachinery/pkg/runtime"
)

var MonitoringCentralObjects = common.MergeLists(pyrra.Objects)

func MonitoringSatelliteObjects() []runtime.Object {
	mixinImporter := importer.NewMixinImporter("https://github.com/gitpod-io/observability", "")
	mixinRules := mixinImporter.ImportPrometheusRules()

	return common.MergeLists(
		alertmanager.Objects,
		kubestateMetrics.Objects,
		mixinRules,
		nodeExporter.Objects,
		otelCollector.Objects,
		prometheusOperator.Objects,
		pyrra.Objects,
	)
}
