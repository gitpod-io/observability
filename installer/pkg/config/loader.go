// Copyright (c) 2021 Gitpod GmbH. All rights reserved.
// Licensed under the GNU Affero General Public License (AGPL).
// See License-AGPL.txt in the project root for license information.

package config

import (
	"fmt"

	"sigs.k8s.io/yaml"
)

// NewDefaultConfig returns a new instance of the current config struct,
// with all defaults filled in.
func NewDefaultConfig() (interface{}, error) {
	cfg := Factory()
	err := Defaults(cfg)
	if err != nil {
		return nil, err
	}

	return cfg, nil
}

var (
	ErrInvalidType = fmt.Errorf("invalid type")
)

func Load(config string, strict bool) (cfg interface{}, err error) {
	// Load default configuration
	cfg = Factory()
	err = Defaults(cfg)
	if err != nil {
		return
	}

	// Override passed configuration onto the default
	if strict {
		err = yaml.UnmarshalStrict([]byte(config), cfg)
	} else {
		err = yaml.Unmarshal([]byte(config), cfg)
	}
	if err != nil {
		return
	}

	return cfg, nil
}

func Marshal(cfg interface{}) ([]byte, error) {
	b, err := yaml.Marshal(cfg)
	if err != nil {
		return nil, err
	}

	return []byte(fmt.Sprintf(string(b))), nil
}
