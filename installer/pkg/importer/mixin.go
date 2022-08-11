package importer

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/google/go-jsonnet"
	monitoringv1 "github.com/prometheus-operator/prometheus-operator/pkg/apis/monitoring/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"

	"github.com/gitpod-io/observability/installer/pkg/common"
)

var (
	rulesSnippet = `
	local mixin =
	// This is where we add the generated list of imports
	%s
	{};
	{
	  prometheusRules: mixin.prometheusAlerts + mixin.prometheusRules,
	}
`

	platformMixinImport  = `(import 'github.com/gitpod-io/gitpod/operations/observability/mixins/platform/mixin.libsonnet')+`
	ideMixinImport       = `(import 'github.com/gitpod-io/gitpod/operations/observability/mixins/IDE/mixin.libsonnet')+`
	webappMixinImport    = `(import 'github.com/gitpod-io/gitpod/operations/observability/mixins/meta/mixin.libsonnet')+`
	workspaceMixinImport = `(import 'github.com/gitpod-io/gitpod/operations/observability/mixins/workspace/mixin.libsonnet')+`
)

// MixinImporter is used to import manifests from git repositories that host mixins
// Example usage:
//
// mixinImporter := importer.NewMixinImporter("https://github.com/gitpod-io/observability", "")
// mixinImporter.ImportPrometheusRules()
//
// The import snippet is hard-coded because the mixin importer is very specialized to the way mixins are organized internally at gitpod.
type MixinImporter struct {
	*importer
}

func NewMixinImporter(gitURL, path string) *MixinImporter {
	return &MixinImporter{
		importer: newImporter(gitURL, path),
	}
}

func (m MixinImporter) ImportPrometheusRules(ctx *common.RenderContext) ([]runtime.Object, error) {
	m.cloneRepository()

	jsonnetImports := []string{platformMixinImport, ideMixinImport, webappMixinImport, workspaceMixinImport}
	imports := strings.Join(jsonnetImports, "\n")
	snippet := fmt.Sprintf(rulesSnippet, imports)

	vm := jsonnet.MakeVM()
	vm.Importer(&jsonnet.FileImporter{
		JPaths: []string{fmt.Sprintf("%s/vendor", clonePath)},
	})

	out, err := vm.EvaluateAnonymousSnippet("", snippet)
	if err != nil {
		fmt.Println(err)
	}

	return unmarshalMixinToRuntimeObject(out), nil
}

func unmarshalMixinToRuntimeObject(j string) []runtime.Object {
	var result map[string]interface{}
	err := json.Unmarshal([]byte(j), &result)
	if err != nil {
		fmt.Println(err)
	}

	// 'prometheusRules' is the key defined in the variable 'rulesSnippet'!
	prometheusRules := result["prometheusRules"].(map[string]interface{})
	rulesAsJSON, err := json.Marshal(prometheusRules)
	if err != nil {
		fmt.Println(err)
	}

	var ruleSpec monitoringv1.PrometheusRuleSpec
	err = json.Unmarshal(rulesAsJSON, &ruleSpec)
	if err != nil {
		fmt.Println(err)
	}

	return []runtime.Object{
		&monitoringv1.PrometheusRule{
			TypeMeta: metav1.TypeMeta{
				APIVersion: "monitoring.coreos.com/v1",
				Kind:       "PrometheusRule",
			},
			ObjectMeta: metav1.ObjectMeta{
				Name: "gitpod-monitoring",
				//TODO: get namespace from config
				Namespace: "monitoring-satellite",
			},
			Spec: ruleSpec,
		},
	}
}
