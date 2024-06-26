package werft

import (
	"k8s.io/apimachinery/pkg/runtime"

	"github.com/gitpod-io/observability/installer/pkg/common"
)

func Objects(ctx *common.RenderContext) common.RenderFunc {
	if !ctx.Config.Werft.InstallServiceMonitors {
		return func(cfg *common.RenderContext) ([]runtime.Object, error) {
			return []runtime.Object{}, nil
		}
	}

	return common.CompositeRenderFunc(
		networkPolicy,
		service,
		serviceMonitor,
	)
}
