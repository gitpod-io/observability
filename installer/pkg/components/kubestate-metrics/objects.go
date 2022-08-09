package kubestateMetrics

import (
	"github.com/gitpod-io/observability/installer/pkg/common"
)

var Objects = common.MergeLists(
	clusterRole(),
	clusterRoleBinding(),
	deployment(),
	podsecuritypolicy(),
	prometheusRule(),
	service(),
	serviceAccount(),
	serviceMonitor(),
)
