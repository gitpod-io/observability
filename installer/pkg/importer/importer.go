package importer

import (
	"crypto/rand"
	"fmt"
	"math/big"
	"os"

	"github.com/go-git/go-git/v5"
)

type Importer struct {
	GitURL    string `json:"gitURL,omitEmpty"`
	Path      string `json:"path"`
	clonePath string
}

func newImporter(gitURL, path string) *Importer {
	n, err := rand.Int(rand.Reader, big.NewInt(999))
	if err != nil {
		panic(err)
	}

	return &Importer{
		GitURL:    gitURL,
		Path:      path,
		clonePath: gitURL + fmt.Sprint(n),
	}
}

func (i Importer) cloneRepository() error {
	os.RemoveAll(i.clonePath)
	_, err := git.PlainClone(i.clonePath, false, &git.CloneOptions{
		URL: i.GitURL,
	})
	if err != nil {
		return err
	}
	return nil
}
