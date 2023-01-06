package certmanager

import (
	"k8s.io/apimachinery/pkg/runtime"

	"github.com/gitpod-io/observability/installer/pkg/common"
)

func Objects(ctx *common.RenderContext) common.RenderFunc {
	if ctx.Config.Certmanager.Namespace != "" {
		Namespace = ctx.Config.Certmanager.Namespace
	}

	if ctx.Config.Certmanager.InstallServiceMonitors {
		return common.CompositeRenderFunc(
			networkPolicy,
			service,
			serviceMonitor,
		)
	}

	return func(cfg *common.RenderContext) ([]runtime.Object, error) {
		return []runtime.Object{}, nil
	}
}
