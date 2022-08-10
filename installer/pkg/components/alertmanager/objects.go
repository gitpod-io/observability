package alertmanager

import (
	"github.com/gitpod-io/observability/installer/pkg/common"
)

var Objects = common.CompositeRenderFunc(
	alertmanager,
	configSecret,
	role,
	roleBinding,
	service,
	serviceAccount,
	serviceMonitor,
)
