package prometheus

import (
	"github.com/gitpod-io/observability/installer/pkg/common"
)

var Objects = common.MergeLists(
	clusterRole(),
	clusterRoleBinding(),
	prometheus(),
	role(),
	roleBinding(),
	extraNamespaceRoles(),
	extraNamespaceRoleBindings(),
	service(),
	serviceAccount(),
	serviceMonitor(),
)
