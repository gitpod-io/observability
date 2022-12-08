package cmd

import (
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"path/filepath"

	"github.com/spf13/cobra"
	"golang.org/x/sync/errgroup"
	"gopkg.in/op/go-logging.v1"
	"sigs.k8s.io/yaml"

	"github.com/gitpod-io/observability/installer/pkg/common"
	"github.com/gitpod-io/observability/installer/pkg/components"
	"github.com/gitpod-io/observability/installer/pkg/config"
	"github.com/gitpod-io/observability/installer/pkg/importer"
	"github.com/gitpod-io/observability/installer/pkg/postprocess"
)

type AppType string

const (
	MonitoringSatelliteApp AppType = "monitoring-satellite"
	MonitoringCentralApp   AppType = "monitoring-central"
)

// String is used both by fmt.Print and by Cobra in help text
func (a *AppType) String() string {
	return string(*a)
}

// Set must have pointer receiver so it doesn't change the value of a copy
func (a *AppType) Set(app string) error {
	switch app {
	case "monitoring-satellite", "monitoring-central":
		*a = AppType(app)
		return nil
	default:
		return errors.New("must be on of ['monitoring-satellite', 'monitoring-central']")
	}
}

// Type is only used in help text
func (a *AppType) Type() string {
	return "AppType"
}

func AppTypeCompletionFunc(cmd *cobra.Command, args []string, toComplete string) ([]string, cobra.ShellCompDirective) {
	return []string{
		"monitoring-satellite\tInstall the observability stack for single clusters, responsible for the ingestion of Metrics and Traces",
		"monitoring-central\tInstall the observability stack responsible for storing Metrics and Traces for long-term period, also provides the tooling necessary to analyze and use the stored data",
	}, cobra.ShellCompDirectiveDefault
}

var renderOpts struct {
	ConfigFN               string
	ValidateConfigDisabled bool
	FilesDir               string
	App                    AppType
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
  installer render --config config.yaml --app monitoring-satellite | kubectl apply -f -`,
	RunE: func(cmd *cobra.Command, args []string) error {
		yaml, err := renderFn(renderOpts.App)
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

func renderFn(app AppType) ([]string, error) {
	_, cfg, err := loadConfig(renderOpts.ConfigFN, app)
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

func loadConfig(cfgFN string, app AppType) (rawCfg interface{}, cfg *config.Config, err error) {
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

	switch app {
	case MonitoringSatelliteApp:
		rawCfg, err = config.LoadSatellite(overrideConfig, rootOpts.StrictConfigParse)
		if err != nil {
			err = fmt.Errorf("error loading config: %w", err)
			return
		}
	case MonitoringCentralApp:
		return nil, nil, errors.New("monitoring-central isn't implemented yet, aborting")
	default:
		return nil, nil, errors.New("app not set or invalid, aborting")
	}

	cfg = rawCfg.(*config.Config)
	cfg = replaceDeprecatedFields(cfg)

	return rawCfg, cfg, err
}

func renderKubernetesObjects(cfg *config.Config) ([]string, error) {
	ctx, err := common.NewRenderContext(*cfg, renderOpts.App.String())
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

	imports, err := runImports(ctx.Config.Imports.Kustomize, ctx.Config.Imports.YAML)
	if err != nil {
		return nil, err
	}
	output = append(output, imports...)

	if ctx.Config.Grafana.Install {
		grafanaImporter := importer.NewYAMLImporter("https://github.com/gitpod-io/observability", "monitoring-satellite/manifests/grafana")
		imports, err := grafanaImporter.Import()
		if err != nil {
			return nil, fmt.Errorf("failed to import grafana manifests: %v", err)
		}
		output = append(output, imports...)
		output = append(output, "---")
	}

	return output, nil
}

func replaceDeprecatedFields(cfg *config.Config) *config.Config {
	// No deprecated config is set
	if !(cfg.Prober.Install) {
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

	renderCmd.PersistentFlags().StringVarP(&renderOpts.ConfigFN, "config", "c", "", "path to the config file, use - for stdin")
	renderCmd.Flags().BoolVar(&renderOpts.ValidateConfigDisabled, "no-validation", false, "if set, the config will not be validated before running")
	renderCmd.Flags().StringVar(&renderOpts.FilesDir, "output-split-files", "", "path to output individual Kubernetes manifests to")
	renderCmd.PersistentFlags().Var(&renderOpts.App, "app", "Which observability app will be installed. Valid options are ['monitoring-satellite', 'monitoring-central'].")

	err := renderCmd.RegisterFlagCompletionFunc("app", AppTypeCompletionFunc)
	if err != nil {
		fmt.Printf("There was an error while compiling the CLI, please reach out to the platform team")
		os.Exit(1)
	}
}

// runImports will import all manifests declared in the import interface using parallelism
func runImports(kImports []importer.KustomizeImporter, yImports []importer.YAMLImporter) ([]string, error) {
	var imports []string
	g := new(errgroup.Group)

	importKustomize := func(i importer.KustomizeImporter) error {
		kImporter := importer.NewKustomizeImporter(i.GitURL, i.Path)
		imps, err := kImporter.Import()
		if err != nil {
			return fmt.Errorf("failed to import Kustomize. gitURL: %s path: %s: %v", i.GitURL, i.Path, err)
		}
		imports = append(imports, imps...)
		return nil
	}

	importYAML := func(i importer.YAMLImporter) error {
		yImporter := importer.NewYAMLImporter(i.GitURL, i.Path)
		imps, err := yImporter.Import()
		if err != nil {
			return fmt.Errorf("failed to import YAML. gitURL: %s path: %s: %v", i.GitURL, i.Path, err)
		}
		imports = append(imports, imps...)
		return nil
	}

	for _, imp := range kImports {
		imp := imp // https://golang.org/doc/faq#closures_and_goroutines
		g.Go(func() error {
			return importKustomize(imp)
		})
	}

	for _, imp := range yImports {
		imp := imp // https://golang.org/doc/faq#closures_and_goroutines
		g.Go(func() error {
			return importYAML(imp)
		})
	}
	if err := g.Wait(); err != nil {
		return nil, err
	}

	return imports, nil
}
