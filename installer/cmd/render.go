package cmd

import (
	"fmt"

	"github.com/gitpod-io/observability/installer/pkg/components"
	"github.com/spf13/cobra"
	"sigs.k8s.io/yaml"
)

var renderOpts struct {
	ConfigFN               string
	Namespace              string
	ValidateConfigDisabled bool
	UseExperimentalConfig  bool
	FilesDir               string
}

// renderCmd represents the render command
var renderCmd = &cobra.Command{
	Use:   "render",
	Short: "Renders the Kubernetes manifests required to install observability",
	Long:  `Renders the Kubernetes manifests required to install observability`,
	RunE: func(cmd *cobra.Command, args []string) error {
		yaml, err := renderKubernetesObjects()
		if err != nil {
			return err
		}

		for _, item := range yaml {
			fmt.Println(item)
		}

		return nil
	},
}

func renderKubernetesObjects() ([]string, error) {
	objs := components.MonitoringSatelliteObjects

	k8s := make([]string, 0)
	for _, o := range objs {
		fc, err := yaml.Marshal(o)
		if err != nil {
			return nil, err
		}

		k8s = append(k8s, fmt.Sprintf("%s---", string(fc)))
	}

	return k8s, nil
}

func init() {
	rootCmd.AddCommand(renderCmd)
}
