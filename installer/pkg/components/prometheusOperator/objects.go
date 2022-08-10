package prometheusOperator

import (
	"github.com/gitpod-io/observability/installer/pkg/common"
)

var Objects = common.CompositeRenderFunc(
	service,
	deployment,
	serviceAccount,
	clusterRole,
	clusterRoleBinding,
	serviceMonitor,
)
