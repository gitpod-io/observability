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
	gitURL string
	path   string
}

func newImporter(gitURL, path string) *importer {
	return &importer{
		gitURL: gitURL,
		path:   path,
	}
}

func (i importer) cloneRepository() {
	os.RemoveAll(clonePath)
	_, err := git.PlainClone(clonePath, false, &git.CloneOptions{
		URL: i.gitURL,
	})

	if err != nil {
		fmt.Println(err)
	}
}
