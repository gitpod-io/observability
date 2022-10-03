package importer

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
)

const YAMLpattern = "*.yaml"

// YAMLImporter is used to import manifests from git repositories that host yaml manifests
// Example usage:
//
// yamlImporter := importer.NewYAMLImporter("https://github.com/ArthurSens/observability", "manifests/production/meta/kubescape", false)
// yamlImporter.Import()
type YAMLImporter struct {
	*Importer
}

func NewYAMLImporter(gitURL, path string) *YAMLImporter {
	return &YAMLImporter{
		Importer: newImporter(gitURL, path),
	}
}

func (y YAMLImporter) Import() ([]string, error) {
	var localImport = true
	if y.GitURL != "" {
		localImport = false
		err := y.cloneRepository()
		if err != nil {
			return nil, err
		}
	}

	yamlPaths, err := y.getFiles(localImport)
	if err != nil {
		return nil, fmt.Errorf("error finding YAML files: %v", err)
	}

	var yamls []string
	for _, yamlPath := range yamlPaths {
		yaml, err := ioutil.ReadFile(yamlPath)
		if err != nil {
			return nil, fmt.Errorf("error reading YAML files: File: %s Err: %v", yamlPath, err)
		}
		yamls = append(yamls, fmt.Sprintf("---\n%s", string(yaml)))
	}

	return yamls, nil
}

func (y YAMLImporter) getFiles(local bool) ([]string, error) {
	var matches []string

	var path = fmt.Sprintf("%s/%s/", y.clonePath, y.Path)
	if local {
		path = fmt.Sprintf("%s/", y.Path)
	}

	err := filepath.Walk(path, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() {
			return nil
		}
		if matched, err := filepath.Match(YAMLpattern, filepath.Base(path)); err != nil {
			return err
		} else if matched {
			matches = append(matches, path)
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return matches, nil
}
