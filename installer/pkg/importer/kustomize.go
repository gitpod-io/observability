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

func (k KustomizeImporter) Import() []string {
	k.cloneRepository()

	kustomize := krusty.MakeKustomizer(krusty.MakeDefaultOptions())
	m, err := kustomize.Run(filesys.MakeFsOnDisk(), fmt.Sprintf("%s/%s", clonePath, k.Path))
	if err != nil {
		fmt.Println(err)
	}

	yml, err := m.AsYaml()
	if err != nil {
		fmt.Println(err)
	}

	return []string{string(yml)}
}
