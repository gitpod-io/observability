package alertmanager

import (
	"github.com/gitpod-io/observability/installer/pkg/common"
)

var Objects = common.MergeLists(
	alertmanager(),
	configSecret(),
	role(),
	roleBinding(),
	service(),
	serviceAccount(),
	serviceMonitor(),
)
