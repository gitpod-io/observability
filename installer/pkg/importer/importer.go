package importer

import (
	"os"

	"github.com/go-git/go-git/v5"
)

const (
	clonePath = "/tmp/clonedRepository"
)

type Importer struct {
	GitURL string `json:"gitURL,omitEmpty"`
	Path   string `json:"path"`
}

func newImporter(gitURL, path string) *Importer {
	return &Importer{
		GitURL: gitURL,
		Path:   path,
	}
}

func (i Importer) cloneRepository() error {
	os.RemoveAll(clonePath)
	_, err := git.PlainClone(clonePath, false, &git.CloneOptions{
		URL: i.GitURL,
	})
	if err != nil {
		return err
	}
	return nil
}
