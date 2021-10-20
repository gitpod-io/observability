package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

// monitoringCentralCmd represents the monitoringCentral command
var monitoringCentralCmd = &cobra.Command{
	Use:   "monitoring-central",
	Short: "A brief description of your command",
	Long: `A longer description that spans multiple lines and likely contains examples
and usage of using your command. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("monitoringCentral called")
	},
}

func init() {
	generateCmd.AddCommand(monitoringCentralCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// monitoringCentralCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// monitoringCentralCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}
