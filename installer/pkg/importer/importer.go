package importer

import (
	"fmt"
	"os"

	"github.com/go-git/go-git/v5"
)

const (
	clonePath = "/tmp/clonedRepository"
)

type Importer struct {
	GitURL string `json:"gitURL"`
	Path   string `json:"path"`
}

func newImporter(gitURL, path string) *Importer {
	return &Importer{
		GitURL: gitURL,
		Path:   path,
	}
}

func (i Importer) cloneRepository() {
	os.RemoveAll(clonePath)
	_, err := git.PlainClone(clonePath, false, &git.CloneOptions{
		URL: i.GitURL,
	})

	if err != nil {
		fmt.Println(err)
	}
}
