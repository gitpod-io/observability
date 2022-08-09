package nodeExporter

import (
	"github.com/gitpod-io/observability/installer/pkg/common"
)

var Objects = common.MergeLists(
	clusterRole(),
	clusterRoleBinding(),
	daemonset(),
	podsecuritypolicy(),
	service(),
	serviceAccount(),
	serviceMonitor(),
)
