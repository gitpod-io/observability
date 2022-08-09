package shared

import (
	"github.com/gitpod-io/observability/installer/pkg/common"
)

var Objects = common.MergeLists(
	restrictedPodsecurityPolicy(),
)
