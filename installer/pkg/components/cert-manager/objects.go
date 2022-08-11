package certManager

import (
	"github.com/gitpod-io/observability/installer/pkg/common"
)

var Objects = common.CompositeRenderFunc(
	networkPolicy,
	service,
	serviceMonitor,
)
