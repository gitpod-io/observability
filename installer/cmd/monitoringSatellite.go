package cmd

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strconv"

	"github.com/google/go-jsonnet"
	"github.com/spf13/cobra"
	"gopkg.in/yaml.v2"
)

var (
	clusterName        string
	namespace          string
	alertingEnabled    bool
	remoteWriteEnabled bool
	nodeAffinityLabel  string
)

// monitoringSatelliteCmd represents the monitoringSatellite command
var monitoringSatelliteCmd = &cobra.Command{
	Use:   "monitoring-satellite",
	Short: "Install or generates resources for monitoring-satellite.",
	Long:  `TODO(arthursens): elaborate with longer description and usage examples.`,
	Run: func(cmd *cobra.Command, args []string) {

		parentName := cmd.Parent().Name()
		switch parentName {
		case "generate":
			validateFlags(parentName)
			generateSatellite()
		case "install":
			validateFlags(parentName)
			// installSatellite()

		}

	},
}

func init() {
	generateCmd.AddCommand(monitoringSatelliteCmd)
	monitoringSatelliteCmd.PersistentFlags().StringVarP(&clusterName, "cluster-name", "c", "test-cluster", "Value used to the external-label 'cluster'.")
	monitoringSatelliteCmd.PersistentFlags().StringVarP(&namespace, "namespace", "n", "monitoring-satellite", "Namespace where monitoring-satellite will be installed.")
	monitoringSatelliteCmd.PersistentFlags().BoolVar(&alertingEnabled, "alerting-enabled", false, "Add alertmanager to monitoring-satellite.")
	monitoringSatelliteCmd.PersistentFlags().BoolVar(&remoteWriteEnabled, "remote-write-enabled", false, "Enables remote-write configuration to Prometheus.")
	monitoringSatelliteCmd.PersistentFlags().StringVar(&nodeAffinityLabel, "node-affinity-label", "", "Label used to set node-affinity for monitoring-satellite. We require this label's value to be equals to \"true\".")

}

func validateFlags(parent string) {
	// TODO(arthursens): validate flags
}

func generateSatellite() {
	const outputFolder = "manifests/monitoring-satellite/"

	vm := jsonnet.MakeVM()
	vm.Importer(&jsonnet.FileImporter{JPaths: []string{"vendor"}})
	vm.ExtVar("namespace", namespace)
	vm.ExtVar("cluster_name", clusterName)
	vm.ExtVar("alerting_enabled", strconv.FormatBool(alertingEnabled))
	vm.ExtVar("remote_write_enabled", strconv.FormatBool(remoteWriteEnabled))
	vm.ExtVar("is_preview", "false")
	vm.ExtVar("node_affinity_label", nodeAffinityLabel)

	output, err := vm.EvaluateFile("monitoring-satellite-example.jsonnet")
	if err != nil {
		fmt.Println(err)
	}

	var files map[string]interface{}
	if err := json.Unmarshal([]byte(output), &files); err != nil {
		fmt.Println(err)
	}

	for fileName, content := range files {
		file, err := os.Create(filepath.Join(outputFolder, fileName+".yaml"))
		if err != nil {
			fmt.Println(err)
		}

		marshal, err := yaml.Marshal(content)
		if err != nil {
			fmt.Println(err)
		}

		if _, err := file.Write(marshal); err != nil {
			fmt.Println(err)
		}
	}

	fmt.Println("Successfully written all generated files to", outputFolder)
	fmt.Println("")
	fmt.Println("Next steps:")
	fmt.Printf("First setup the cluster: kubectl apply -f %ssetup/\n", outputFolder)
	fmt.Printf("Second deploy all objects: kubectl apply -f %s\n", outputFolder)
}
