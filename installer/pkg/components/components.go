package components

import (
	"github.com/gitpod-io/observability/installer/pkg/common"
	"github.com/gitpod-io/observability/installer/pkg/components/pyrra"
)

var MonitoringCentralObjects = common.MergeLists(pyrra.Objects)
var MonitoringSatelliteObjects = common.MergeLists(pyrra.Objects)
