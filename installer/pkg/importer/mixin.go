package importer

import (
	"fmt"
	"strings"

	"github.com/google/go-jsonnet"
)

const (
	outputFolder = "manifests"
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

func (m MixinImporter) ImportPrometheusRules() {
	jsonnetImports := []string{platformMixinImport, ideMixinImport, webappMixinImport, workspaceMixinImport}
	imports := strings.Join(jsonnetImports, "\n")
	snippet := fmt.Sprintf(rulesSnippet, imports)

	vm := jsonnet.MakeVM()
	m.cloneRepository()
	vm.Importer(&jsonnet.FileImporter{
		JPaths: []string{fmt.Sprintf("%s/vendor", clonePath)},
	})

	out, err := vm.EvaluateAnonymousSnippet("", snippet)
	if err != nil {
		fmt.Println(err)
	}

	fmt.Println(out)
}
