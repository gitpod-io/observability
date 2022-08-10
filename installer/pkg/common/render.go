// Copyright (c) 2021 Gitpod GmbH. All rights reserved.
// Licensed under the GNU Affero General Public License (AGPL).
// See License-AGPL.txt in the project root for license information.

package common

import (
	"fmt"

	"github.com/docker/distribution/reference"
	"github.com/gitpod-io/observability/installer/pkg/config"
	"helm.sh/helm/v3/pkg/cli/values"
	"k8s.io/apimachinery/pkg/runtime"
)

// Renderable turns the config into a set of Kubernetes runtime objects
type RenderFunc func(cfg *RenderContext) ([]runtime.Object, error)

type HelmFunc func(cfg *RenderContext) ([]string, error)

type HelmConfig struct {
	Enabled bool
	Values  *values.Options
}

func CompositeRenderFunc(f ...RenderFunc) RenderFunc {
	return func(ctx *RenderContext) ([]runtime.Object, error) {
		var res []runtime.Object
		for _, g := range f {
			obj, err := g(ctx)
			if err != nil {
				return nil, err
			}
			if len(obj) == 0 {
				// the RenderFunc chose not to render anything, possibly based on config it received
				continue
			}
			res = append(res, obj...)
		}
		return res, nil
	}
}

func CompositeHelmFunc(f ...HelmFunc) HelmFunc {
	return func(ctx *RenderContext) ([]string, error) {
		var res []string
		for _, g := range f {
			str, err := g(ctx)
			if err != nil {
				return nil, err
			}
			res = append(res, str...)
		}
		return res, nil
	}
}

type RenderContext struct {
	Config    config.Config
	Namespace string
}

func ImageName(imageURL, tag string) string {
	ref := fmt.Sprintf("%s:%s", imageURL, tag)
	pref, err := reference.ParseNamed(ref)
	if err != nil {
		panic(fmt.Sprintf("cannot parse image ref %s: %v", ref, err))
	}
	if _, ok := pref.(reference.Tagged); !ok {
		panic(fmt.Sprintf("image ref %s has no tag: %v", ref, err))
	}

	return ref
}

// NewRenderContext constructor function to create a new RenderContext with the values generated
func NewRenderContext(cfg config.Config, namespace string) (*RenderContext, error) {
	ctx := &RenderContext{
		Config:    cfg,
		Namespace: namespace,
	}

	return ctx, nil
}
