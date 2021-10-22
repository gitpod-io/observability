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
	clusterName          string
	namespace            string
	alertingEnabled      bool
	criticalSlackWebhook string
	warningSlackWebhook  string
	infoSlackWebhook     string
	slackChannelPrefix   string
	pdRoutingKey         string
	remoteWriteEnabled   bool
	remoteWriteUsername  string
	remoteWritePassword  string
	remoteWriteURL       string
	nodeAffinityLabel    string
)

// monitoringSatelliteCmd represents the monitoringSatellite command
var monitoringSatelliteCmd = &cobra.Command{
	Use:   "monitoring-satellite",
	Short: "Install or generates resources for monitoring-satellite.",
	Long:  `TODO(arthursens): elaborate with longer description and usage examples.`,
	Run: func(cmd *cobra.Command, args []string) {
		validateFlags()

		parentName := cmd.Parent().Name()
		switch parentName {
		case "generate":
			generateSatellite()
		case "install":
			// installSatellite()

		}

	},
}

func init() {
	generateCmd.AddCommand(monitoringSatelliteCmd)
	monitoringSatelliteCmd.PersistentFlags().StringVarP(&clusterName, "cluster-name", "c", "test-cluster", "Value used to the external-label 'cluster'.")
	monitoringSatelliteCmd.PersistentFlags().StringVarP(&namespace, "namespace", "n", "monitoring-satellite", "Namespace where monitoring-satellite will be installed.")
	monitoringSatelliteCmd.PersistentFlags().BoolVar(&alertingEnabled, "alerting-enabled", false, "Add alertmanager to monitoring-satellite.")
	monitoringSatelliteCmd.PersistentFlags().StringVar(&criticalSlackWebhook, "critical-slack-webhook-url", "", "Slack Webhook URL used to route critical alerts. If '--alerting-enabled' is set, whether '--critical-slack-webhook-url' or '--pagerduty-routing-key' is required. '--pagerduty-routing-key' has higher priority.")
	monitoringSatelliteCmd.PersistentFlags().StringVar(&warningSlackWebhook, "warning-slack-webhook-url", "", "Slack Webhook URL used to route warning alerts. Required if '--alerting-enabled' was set.")
	monitoringSatelliteCmd.PersistentFlags().StringVar(&infoSlackWebhook, "info-slack-webhook-url", "", "Slack Webhook URL used to route info alerts. Required if '--alerting-enabled' was set.")
	monitoringSatelliteCmd.PersistentFlags().StringVar(&slackChannelPrefix, "slack-channel-prefix", "", "Prefix of slack channels used by Alertmanager. Required if '--alerting-enabled' was set.")
	monitoringSatelliteCmd.PersistentFlags().StringVar(&pdRoutingKey, "pagerduty-routing-key", "", "Routing key used to route critical alerts. If '--alerting-enabled' is set, whether '--critical-slack-webhook-url' or '--pagerduty-routing-key' is required. '--pagerduty-routing-key' has higher priority.")
	monitoringSatelliteCmd.PersistentFlags().BoolVar(&remoteWriteEnabled, "remote-write-enabled", false, "Enables remote-write configuration to Prometheus.")
	monitoringSatelliteCmd.PersistentFlags().StringVar(&remoteWriteUsername, "remote-write-username", "", "Username used by basic auth when remote writing. Required if '--remote-write-enabled' was set.")
	monitoringSatelliteCmd.PersistentFlags().StringVar(&remoteWritePassword, "remote-write-password", "", "Password used by basic auth when remote writing. Required if '--remote-write-enabled' was set.")
	monitoringSatelliteCmd.PersistentFlags().StringVar(&remoteWriteURL, "remote-write-url", "", "Backend URL where prometheus will push metrics to. Required if '--remote-write-enabled' was set.")
	monitoringSatelliteCmd.PersistentFlags().StringVar(&nodeAffinityLabel, "node-affinity-label", "", "Label used to set node-affinity for monitoring-satellite. We require this label's value to be equals to 'true'.")
}

func validateFlags() {
	validFlags := true

	if alertingEnabled {
		if infoSlackWebhook == "" {
			fmt.Println("'--info-slack-webhook-url' is required when '--alerting-enabled' is set.")
			validFlags = false
		}
		if warningSlackWebhook == "" {
			fmt.Println("'--warning-slack-webhook-url' is required when '--alerting-enabled' is set.")
			validFlags = false
		}
		if criticalSlackWebhook == "" && pdRoutingKey == "" {
			fmt.Println("If '--alerting-enabled' is set, whether '--critical-slack-webhook-url' or '--pagerduty-routing-key' is required. '--pagerduty-routing-key' has higher priority.")
			validFlags = false
		}
	}

	if remoteWriteEnabled {
		if remoteWriteUsername == "" {
			fmt.Println("'--remote-write-username' is required when '--remote-write-enabled' is set.")
			validFlags = false
		}
		if remoteWritePassword == "" {
			fmt.Println("'--remote-write-password' is required when '--remote-write-enabled' is set.")
			validFlags = false
		}
		if remoteWriteURL == "" {
			fmt.Println("'--remote-write-url' is required when '--remote-write-enabled' is set.")
			validFlags = false
		}
	}

	if !validFlags {
		os.Exit(1)
	}
}

func generateSatellite() {
	const outputFolder = "manifests/monitoring-satellite/"

	vm := jsonnet.MakeVM()
	vm.Importer(&jsonnet.FileImporter{JPaths: []string{"vendor"}})
	vm.ExtVar("namespace", namespace)
	vm.ExtVar("cluster_name", clusterName)
	vm.ExtVar("alerting_enabled", strconv.FormatBool(alertingEnabled))
	vm.ExtVar("slack_webhook_url_critical", criticalSlackWebhook)
	vm.ExtVar("slack_webhook_url_warning", warningSlackWebhook)
	vm.ExtVar("slack_webhook_url_info", infoSlackWebhook)
	vm.ExtVar("slack_channel_prefix", slackChannelPrefix)
	vm.ExtVar("pagerduty_routing_key", pdRoutingKey)
	vm.ExtVar("remote_write_enabled", strconv.FormatBool(remoteWriteEnabled))
	vm.ExtVar("remote_write_username", remoteWriteUsername)
	vm.ExtVar("remote_write_password", remoteWritePassword)
	vm.ExtCode("remote_write_urls", fmt.Sprintf("['%s']", remoteWriteURL))
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
