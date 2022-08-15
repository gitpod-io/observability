package kubernetes

import (
	"github.com/gitpod-io/observability/installer/pkg/common"
)

var Objects = common.CompositeRenderFunc(
	serviceMonitorAPIServer,
	serviceMonitorKubelet,
)
