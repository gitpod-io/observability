package cmd

import (
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"path/filepath"

	"github.com/spf13/cobra"
	"gopkg.in/op/go-logging.v1"
	"sigs.k8s.io/yaml"

	"github.com/gitpod-io/observability/installer/pkg/common"
	"github.com/gitpod-io/observability/installer/pkg/components"
	"github.com/gitpod-io/observability/installer/pkg/config"
	"github.com/gitpod-io/observability/installer/pkg/importer"
	"github.com/gitpod-io/observability/installer/pkg/postprocess"
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
	Short: "Renders the Kubernetes manifests required to install Gitpod's observability stack",
	Long: `Renders the Kubernetes manifests required to install Gitpod's observability stack

A config file is required which can be generated with the init command.`,
	Example: `  # Default install.
  installer render --config config.yaml | kubectl apply -f -

  # Install Gitpod's observability stack into a non-default namespace.
  installer render --config config.yaml --namespace gitpod | kubectl apply -f -`,
	RunE: func(cmd *cobra.Command, args []string) error {
		yaml, err := renderFn()
		if err != nil {
			return err
		}

		if renderOpts.FilesDir != "" {
			err := saveYamlToFiles(renderOpts.FilesDir, yaml)
			if err != nil {
				return err
			}
			return nil
		}

		for _, item := range yaml {
			fmt.Println(item)
		}

		return nil
	},
}

func renderFn() ([]string, error) {
	_, cfg, err := loadConfig(renderOpts.ConfigFN)
	if err != nil {
		return nil, err
	}

	return renderKubernetesObjects(cfg)
}

func saveYamlToFiles(dir string, yaml []string) error {
	for i, mf := range yaml {
		objs, err := common.YamlToRuntimeObject([]string{mf})
		if err != nil {
			return err
		}
		obj := objs[0]
		fn := filepath.Join(dir, fmt.Sprintf("%03d_%s_%s.yaml", i, obj.Kind, obj.Metadata.Name))
		err = os.WriteFile(fn, []byte(mf), 0644)
		if err != nil {
			return err
		}
	}
	return nil
}

func loadConfig(cfgFN string) (rawCfg interface{}, cfg *config.Config, err error) {
	var overrideConfig string
	// Update overrideConfig if cfgFN is not empty
	switch cfgFN {
	case "-":
		b, err := io.ReadAll(os.Stdin)
		if err != nil {
			return nil, nil, err
		}
		overrideConfig = string(b)
	case "":
		return nil, nil, fmt.Errorf("missing config file")
	default:
		cfgBytes, err := ioutil.ReadFile(cfgFN)
		if err != nil {
			panic(fmt.Sprintf("couldn't read file %s, %s", cfgFN, err))
		}
		overrideConfig = string(cfgBytes)
	}

	rawCfg, err = config.Load(overrideConfig, rootOpts.StrictConfigParse)
	if err != nil {
		err = fmt.Errorf("error loading config: %w", err)
		return
	}
	cfg = rawCfg.(*config.Config)
	cfg = replaceDeprecatedFields(cfg)

	return rawCfg, cfg, err
}

func renderKubernetesObjects(cfg *config.Config) ([]string, error) {
	ctx, err := common.NewRenderContext(*cfg, renderOpts.Namespace)
	if err != nil {
		return nil, err
	}

	objs, err := common.CompositeRenderFunc(components.MonitoringSatelliteObjects(ctx))(ctx)
	if err != nil {
		return nil, err
	}

	k8s := make([]string, 0)
	for _, o := range objs {
		fc, err := yaml.Marshal(o)
		if err != nil {
			return nil, err
		}

		k8s = append(k8s, fmt.Sprintf("---\n%s\n", string(fc)))
	}

	// convert everything to individual objects
	runtimeObjs, err := common.YamlToRuntimeObject(k8s)
	if err != nil {
		return nil, err
	}

	// sort the objects and return the plain YAML
	sortedObjs, err := common.DependencySortingRenderFunc(runtimeObjs)
	if err != nil {
		return nil, err
	}

	postProcessed, err := postprocess.Run(sortedObjs)
	if err != nil {
		return nil, err
	}

	// output the YAML to stdout
	output := make([]string, 0)
	for _, c := range postProcessed {
		output = append(output, fmt.Sprintf("---\n# %s/%s %s\n%s", c.TypeMeta.APIVersion, c.TypeMeta.Kind, c.Metadata.Name, c.Content))
	}

	for _, imp := range ctx.Config.Imports.Kustomize {
		kImporter := importer.NewKustomizeImporter(imp.GitURL, imp.Path)
		output = append(output, kImporter.Import()...)
	}

	for _, imp := range ctx.Config.Imports.YAML {
		yImporter := importer.NewYAMLImporter(imp.GitURL, imp.Path)
		output = append(output, yImporter.Import()...)
	}

	if ctx.Config.Grafana.Install {
		grafanaImporter := importer.NewYAMLImporter("https://github.com/gitpod-io/observability", "monitoring-satellite/manifests/grafana")
		output = append(output, grafanaImporter.Import()...)
		output = append(output, "---")
	}

	return output, nil
}

func replaceDeprecatedFields(cfg *config.Config) *config.Config {
	// No deprecated config is set
	if !(cfg.Kubescape.Install || cfg.Prober.Install) {
		return cfg
	}

	// Set up logging to stderr, so it is not mixed with the rendered output.
	var format = logging.MustStringFormatter(
		`%{color}%{time:15:04:05} [%{level:.4s}]%{color:reset} %{message}`,
	)
	var backend = logging.AddModuleLevel(
		logging.NewBackendFormatter(logging.NewLogBackend(os.Stderr, "", 0), format))

	backend.SetLevel(logging.INFO, "")
	logging.SetBackend(backend)

	logger, _ := logging.GetLogger("INFO")

	if cfg.Imports == nil {
		cfg.Imports = &config.Imports{
			YAML:      []importer.YAMLImporter{},
			Kustomize: []importer.KustomizeImporter{},
		}
	}

	if cfg.Kubescape.Install {
		logger.Info("kubescape.install is deprecated, please use the importer interface instead.")
		cfg.Imports.YAML = append(cfg.Imports.YAML, importer.YAMLImporter{
			Importer: &importer.Importer{
				GitURL: "https://github.com/gitpod-io/observability",
				Path:   "monitoring-satellite/manifests/kubescape",
			},
		})
	}

	if cfg.Prober.Install {
		logger.Info("prober.install is deprecated, please use the importer interface instead.")
		cfg.Imports.YAML = append(cfg.Imports.YAML, importer.YAMLImporter{
			Importer: &importer.Importer{
				GitURL: "https://github.com/gitpod-io/observability",
				Path:   "monitoring-satellite/manifests/probers",
			},
		})
	}

	return cfg
}

func init() {
	rootCmd.AddCommand(renderCmd)

	renderCmd.PersistentFlags().StringVarP(&renderOpts.ConfigFN, "config", "c", os.Getenv("GITPOD_INSTALLER_CONFIG"), "path to the config file, use - for stdin")
	renderCmd.PersistentFlags().StringVarP(&renderOpts.Namespace, "namespace", "n", "default", "namespace to deploy to")
	renderCmd.Flags().BoolVar(&renderOpts.ValidateConfigDisabled, "no-validation", false, "if set, the config will not be validated before running")
	renderCmd.Flags().StringVar(&renderOpts.FilesDir, "output-split-files", "", "path to output individual Kubernetes manifests to")
}
