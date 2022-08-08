package pyrra

import (
	"github.com/gitpod-io/observability/installer/pkg/common"
)

var Objects = common.MergeLists(
	deployment(),
	service(),
	serviceAccount(),
	clusterRole(),
	clusterRoleBinding(),
)
