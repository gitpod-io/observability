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
	*importer
}

func NewYAMLImporter(gitURL, path string) *YAMLImporter {
	return &YAMLImporter{
		importer: newImporter(gitURL, path),
	}
}

func (y YAMLImporter) Import() []string {
	y.cloneRepository()
	yamlPaths, err := y.getFiles()
	if err != nil {
		fmt.Printf("Error finding YAML files: %v", err)
	}

	var yamls []string
	for _, yamlPath := range yamlPaths {
		yaml, err := ioutil.ReadFile(yamlPath)
		if err != nil {
			fmt.Printf("Error reading YAML files: File: %s Err: %v", yamlPath, err)
		}

		yamls = append(yamls, fmt.Sprintf("%s\n---", string(yaml)))
	}

	return yamls
}

func (y YAMLImporter) getFiles() ([]string, error) {
	var matches []string
	err := filepath.Walk(fmt.Sprintf("%s/%s/", clonePath, y.path), func(path string, info os.FileInfo, err error) error {
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
