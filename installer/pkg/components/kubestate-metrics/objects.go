package kubestatemetrics

import (
	"github.com/gitpod-io/observability/installer/pkg/common"
)

var Objects = common.CompositeRenderFunc(
	clusterRole,
	clusterRoleBinding,
	deployment,
	podsecuritypolicy,
	service,
	serviceAccount,
	serviceMonitor,
)
