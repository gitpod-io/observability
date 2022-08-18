package importer

import (
	"fmt"
	"os"

	"github.com/go-git/go-git/v5"
)

const (
	clonePath = "/tmp/clonedRepository"
)

type importer struct {
	GitURL string
	Path   string
}

func newImporter(gitURL, path string) *importer {
	return &importer{
		GitURL: gitURL,
		Path:   path,
	}
}

func (i importer) cloneRepository() {
	os.RemoveAll(clonePath)
	_, err := git.PlainClone(clonePath, false, &git.CloneOptions{
		URL: i.GitURL,
	})

	if err != nil {
		fmt.Println(err)
	}
}
