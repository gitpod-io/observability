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
	recursive bool
}

func NewYAMLImporter(gitURL, path string, recursive bool) *YAMLImporter {
	return &YAMLImporter{
		importer:  newImporter(gitURL, path),
		recursive: recursive,
	}
}

func (y YAMLImporter) Import() {
	y.cloneRepository()
	yamlPaths, err := y.getFiles()
	if err != nil {
		fmt.Printf("Error finding YAML files: %v", err)
	}

	for _, yamlPath := range yamlPaths {
		yaml, err := ioutil.ReadFile(yamlPath)
		if err != nil {
			fmt.Printf("Error reading YAML files: File: %s Err: %v", yamlPath, err)
		}

		// Just to showcase that we can import and manipulate YAML
		fmt.Println(string(yaml))
	}
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
