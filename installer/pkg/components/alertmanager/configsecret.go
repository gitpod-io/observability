package alertmanager

import (
	"encoding/json"
	"fmt"
	"log"

	amconfig "github.com/prometheus/alertmanager/config"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"

	"github.com/gitpod-io/observability/installer/pkg/common"
)

func configSecret(ctx *common.RenderContext) ([]runtime.Object, error) {
	jsonStr, err := json.Marshal(ctx.Config.Alerting.Config)
	if err != nil {
		log.Fatal("failed to marshal config to json")
	}

	var parsedConfig amconfig.Config
	err = json.Unmarshal(jsonStr, &parsedConfig)
	if err != nil {
		log.Fatal("failed to parse config into valid alertmanager configuration")
	}

	return []runtime.Object{
		&corev1.Secret{
			TypeMeta: metav1.TypeMeta{
				APIVersion: "v1",
				Kind:       "Secret",
			},
			ObjectMeta: metav1.ObjectMeta{
				Name:      resourceName(),
				Namespace: Namespace,
				Labels:    common.Labels(Name, Component, App, Version),
			},
			StringData: map[string]string{
				"alertmanager.yaml": fmt.Sprintf("%v", parsedConfig),
			},
		},
	}, nil
}
