package pyrra

import (
	"github.com/gitpod-io/observability/installer/pkg/common"
	"k8s.io/apimachinery/pkg/runtime"
)

func Objects(ctx *common.RenderContext) common.RenderFunc {
	if ctx.Config.Pyrra.Install {
		return common.CompositeRenderFunc(
			deployment,
			service,
			serviceAccount,
			clusterRole,
			clusterRoleBinding,
		)
	}

	return func(cfg *common.RenderContext) ([]runtime.Object, error) {
		return []runtime.Object{}, nil
	}
}
