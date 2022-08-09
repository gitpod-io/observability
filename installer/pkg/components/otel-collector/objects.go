package otelCollector

import (
	"github.com/gitpod-io/observability/installer/pkg/common"
)

var Objects = common.MergeLists(
	clusterRole(),
	clusterRoleBinding(),
	configMap(),
	deployment(),
	podsecuritypolicy(),
	service(),
	serviceAccount(),
	serviceMonitor(),
)
