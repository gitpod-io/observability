package gitpod

import (
	"github.com/gitpod-io/observability/installer/pkg/common"
	"k8s.io/apimachinery/pkg/runtime"
)

func generateObjects(target string) common.RenderFunc {
	return common.CompositeRenderFunc(
		networkPolicy(target),
		service(target),
		serviceMonitor(target),
	)
}

func Objects(ctx *common.RenderContext) common.RenderFunc {
	if !ctx.Config.Gitpod.InstallServiceMonitors {
		return func(cfg *common.RenderContext) ([]runtime.Object, error) {
			return []runtime.Object{}, nil
		}
	}

	var objects common.RenderFunc
	for _, t := range targets {
		objects = common.CompositeRenderFunc(objects, generateObjects(t))
	}
	return objects
}
