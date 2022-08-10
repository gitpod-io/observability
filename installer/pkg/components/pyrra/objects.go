package pyrra

import (
	"github.com/gitpod-io/observability/installer/pkg/common"
)

var Objects = common.CompositeRenderFunc(
	deployment,
	service,
	serviceAccount,
	clusterRole,
	clusterRoleBinding,
)
