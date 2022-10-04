package importer

import (
	"fmt"

	"sigs.k8s.io/kustomize/api/filesys"
	"sigs.k8s.io/kustomize/api/krusty"
)

// KustomizeImporter is used to import manifests from git repositories that host kustomize manifests
// Example usage:
//
// kustomizeImporter := NewKustomizeImporter("https://github.com/kubernetes-sigs/kustomize", "examples/helloWorld")
// kustomizeImporter.Import()
type KustomizeImporter struct {
	*Importer
}

func NewKustomizeImporter(gitURL, path string) *KustomizeImporter {
	return &KustomizeImporter{
		Importer: newImporter(gitURL, path),
	}
}

func (k KustomizeImporter) Import() ([]string, error) {
	var localImport = true
	if k.GitURL != "" {
		localImport = false
		err := k.cloneRepository()
		if err != nil {
			return nil, err
		}
	}

	var importPath = fmt.Sprintf("%s/%s/", k.clonePath, k.Path)
	if localImport {
		importPath = fmt.Sprintf("%s/", k.Path)
	}

	kustomize := krusty.MakeKustomizer(krusty.MakeDefaultOptions())
	m, err := kustomize.Run(filesys.MakeFsOnDisk(), importPath)
	if err != nil {
		return nil, err
	}

	yml, err := m.AsYaml()
	if err != nil {
		return nil, err
	}

	return []string{string(yml)}, nil
}
