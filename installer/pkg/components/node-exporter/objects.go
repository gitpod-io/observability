package nodeExporter

import (
	"github.com/gitpod-io/observability/installer/pkg/common"
)

var Objects = common.CompositeRenderFunc(
	clusterRole,
	clusterRoleBinding,
	daemonset,
	podsecuritypolicy,
	service,
	serviceAccount,
	serviceMonitor,
)
