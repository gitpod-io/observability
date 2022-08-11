package otelcollector

import (
	"k8s.io/apimachinery/pkg/runtime"

	"github.com/gitpod-io/observability/installer/pkg/common"
)

func Objects(ctx *common.RenderContext) common.RenderFunc {
	if ctx.Config.Tracing.Install {
		return common.CompositeRenderFunc(
			clusterRole,
			clusterRoleBinding,
			configMap,
			deployment,
			podsecuritypolicy,
			service,
			serviceAccount,
			serviceMonitor,
		)
	}

	return func(cfg *common.RenderContext) ([]runtime.Object, error) {
		return []runtime.Object{}, nil
	}
}
