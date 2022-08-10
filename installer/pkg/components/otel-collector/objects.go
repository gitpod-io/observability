package otelCollector

import (
	"github.com/gitpod-io/observability/installer/pkg/common"
)

var Objects = common.CompositeRenderFunc(
	clusterRole,
	clusterRoleBinding,
	configMap,
	deployment,
	podsecuritypolicy,
	service,
	serviceAccount,
	serviceMonitor,
)
