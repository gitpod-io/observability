package otelcollector

import (
	"errors"

	"k8s.io/apimachinery/pkg/runtime"

	"github.com/gitpod-io/observability/installer/pkg/common"
)

func Objects(ctx *common.RenderContext) common.RenderFunc {
	if ctx.Config.Tracing.Install {
		if ctx.Config.Tracing.HoneycombAPIKey == "" || ctx.Config.Tracing.HoneycombDataset == "" {
			return func(cfg *common.RenderContext) ([]runtime.Object, error) {
				return []runtime.Object{}, errors.New("'honeycombDataset' and 'honeycombAPIKey' are required when tracing is enabled")
			}
		}

		return common.CompositeRenderFunc(
			clusterRole,
			clusterRoleBinding,
			configMap,
			deployment,
			service,
			serviceAccount,
			serviceMonitor,
		)
	}

	return func(cfg *common.RenderContext) ([]runtime.Object, error) {
		return []runtime.Object{}, nil
	}
}
