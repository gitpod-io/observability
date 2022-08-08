package components

import (
	"github.com/gitpod-io/observability/installer/pkg/common"
	"github.com/gitpod-io/observability/installer/pkg/components/alertmanager"
	nodeExporter "github.com/gitpod-io/observability/installer/pkg/components/node-exporter"
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
		pyrra.Objects,
		nodeExporter.Objects,
		prometheusOperator.Objects,
		mixinRules,
		alertmanager.Objects)
}
