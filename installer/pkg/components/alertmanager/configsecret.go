package alertmanager

import (
	"fmt"

	"github.com/prometheus/common/model"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"

	"github.com/gitpod-io/observability/installer/pkg/common"
	"github.com/gitpod-io/observability/installer/pkg/config"
)

const queryString = `{{ reReplaceAll "%22" "%5C%22" (index .Alerts 0).GeneratorURL | reReplaceAll ".*expr=" "https://grafana.gitpod.io/explore?orgId=1&left=%7B%22range%22:%7B%22from%22:%22now-1h%22,%22to%22:%22now%22%7D,%22datasource%22:%22VictoriaMetrics%22,%22queries%22:%5B%7B%22refId%22:%22A%22,%22expr%22:%22" | reReplaceAll "&g0.tab=1" "%22%7D%5D%7D" | reReplaceAll ` + "`\\+`" + ` "%20" | reReplaceAll "%0A" "" | reReplaceAll "%28" "(" | reReplaceAll "%29" ")" }}`

func configSecret(ctx *common.RenderContext) ([]runtime.Object, error) {
	var receivers []*config.Receiver

	receivers = append(receivers, criticalReceivers(ctx)...)
	receivers = append(receivers, defaultReceivers(ctx)...)
	receivers = append(receivers, teamSlackReceivers(ctx)...)
	resolveTimeout, _ := model.ParseDuration("5m")

	alertingConfig := config.AlertmanagerConfig{
		Global: &config.GlobalConfig{
			ResolveTimeout: &resolveTimeout,
		},
		Route: &config.Route{
			Receiver:       "Black_Hole",
			GroupByStr:     []string{"..."},
			GroupWait:      "30s",
			GroupInterval:  "5m",
			RepeatInterval: "6h",
			Routes:         routes(ctx),
		},
		InhibitRules: inhibitRules(),
		Receivers:    receivers,
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
				"alertmanager.yaml": alertingConfig.String(),
			},
		},
	}, nil
}

func routes(ctx *common.RenderContext) []*config.Route {
	var routes []*config.Route

	if ctx.Config.Alerting.IncidentIoURL != "" && ctx.Config.Alerting.IncidentIoAuthToken != "" {
		routes = append(routes, &config.Route{
			Receiver: "criticalReceiverIncidentIO",
			Match: map[string]string{
				"severity": "critical",
			},
			Continue: true,
		})
	}

	routes = append(routes, &config.Route{
		Receiver: "criticalReceiver",
		Match: map[string]string{
			"severity": "critical",
		},
		Continue: false,
	})

	for _, tRoute := range ctx.Config.Alerting.TeamRoutes {
		routes = append(routes, &config.Route{
			Receiver: fmt.Sprintf("%s-slackReceiver", tRoute.TeamLabel),
			Match: map[string]string{
				"team": tRoute.TeamLabel,
			},
			Continue: false,
		})
	}

	routes = append(routes, &config.Route{
		Receiver: "genericReceiver",
		MatchRE: map[string]string{
			"severity": "info|warning",
		},
		Continue: false,
	})

	return routes
}

func inhibitRules() []*config.InhibitRule {
	var inhibitRules []*config.InhibitRule

	inhibitRules = append(inhibitRules, &config.InhibitRule{
		SourceMatch: map[string]string{
			"severity": "critical",
		},
		TargetMatchRE: map[string]string{
			"severity": "info|warning",
		},
		Equal: []string{"alertname"},
	})

	inhibitRules = append(inhibitRules, &config.InhibitRule{
		SourceMatch: map[string]string{
			"severity": "warning",
		},
		TargetMatchRE: map[string]string{
			"severity": "info",
		},
		Equal: []string{"alertname"},
	})

	return inhibitRules
}

func criticalReceivers(ctx *common.RenderContext) []*config.Receiver {
	var receivers []*config.Receiver

	if ctx.Config.Alerting.PagerDutyRoutingKey != "" {
		receivers = append(receivers, &config.Receiver{
			Name: "criticalReceiver",
			PagerdutyConfigs: []*config.PagerdutyConfig{
				{
					VSendResolved: common.ToPointer(true),
					RoutingKey:    ctx.Config.Alerting.PagerDutyRoutingKey,
					Links: []config.PagerdutyLink{
						{
							Href: "{{ .CommonAnnotations.runbook_url }}",
							Text: "Runbook",
						},
						{
							Href: queryString,
							Text: "Query",
						},
						{
							Href: "{{ .CommonAnnotations.dashboard_url}}",
							Text: "Dashboard",
						},
					},
				},
			},
		})
	}

	if ctx.Config.Alerting.IncidentIoURL != "" && ctx.Config.Alerting.IncidentIoAuthToken != "" {
		receivers = append(receivers, &config.Receiver{
			Name: "criticalReceiverIncidentIO",
			WebhookConfigs: []*config.WebhookConfig{
				{
					VSendResolved: common.ToPointer(true),
					URL:           ctx.Config.Alerting.IncidentIoURL,
					HTTPConfig: &config.HTTPClientConfig{
						Authorization: &config.Authorization{
							Credentials: ctx.Config.Alerting.IncidentIoAuthToken,
						},
					},
				},
			},
		})
	}

	if len(receivers) == 0 {
		receivers = append(receivers, &config.Receiver{
			Name: "criticalReceiver",
			SlackConfigs: []*config.SlackConfig{
				{
					VSendResolved: common.ToPointer(true),
					APIURL:        "https://slack.com/api/chat.postMessage",
					Channel:       ctx.Config.Alerting.GenericSlackChannel,
					Color:         "{{ if eq .Status \"firing\" -}}{{ if eq .CommonLabels.severity \"warning\" -}}warning{{- else if eq .CommonLabels.severity \"critical\" -}}danger{{- else -}}#439FE0{{- end -}}{{ else -}}good{{- end }}",
					Title:         "[{{ .CommonLabels.alertname }} {{ .Status | toUpper }} {{ if eq .Status \"firing\" }}{{ end }}]",
					Text:          "{{ range .Alerts }}\n*Summary*: {{ .Annotations.summary }}\n*Severity: {{ .Labels.severity }}*\n*Cluster:* {{ .Labels.cluster }}\n*Alert:* {{ .Labels.alertname }}\n*Description:* {{ .Annotations.description }}\n{{ end }}",
					HTTPConfig: &config.HTTPClientConfig{
						Authorization: &config.Authorization{
							Credentials: ctx.Config.Alerting.SlackOAuthToken,
						},
					},
					Actions: slackButtons(),
				},
			},
		})
	}

	return receivers
}

func defaultReceivers(ctx *common.RenderContext) []*config.Receiver {
	var receivers []*config.Receiver

	receivers = append(receivers, &config.Receiver{Name: "Black_Hole"})
	receivers = append(receivers, &config.Receiver{
		Name: "genericReceiver",
		SlackConfigs: []*config.SlackConfig{
			{
				VSendResolved: common.ToPointer(true),
				APIURL:        "https://slack.com/api/chat.postMessage",
				Channel:       ctx.Config.Alerting.GenericSlackChannel,
				Color:         "{{ if eq .Status \"firing\" -}}{{ if eq .CommonLabels.severity \"warning\" -}}warning{{- else if eq .CommonLabels.severity \"critical\" -}}danger{{- else -}}#439FE0{{- end -}}{{ else -}}good{{- end }}",
				Title:         "[{{ .CommonLabels.alertname }} {{ .Status | toUpper }} {{ if eq .Status \"firing\" }}{{ end }}]",
				Text:          "{{ range .Alerts }}\n*Summary*: {{ .Annotations.summary }}\n*Severity: {{ .Labels.severity }}*\n*Cluster:* {{ .Labels.cluster }}\n*Alert:* {{ .Labels.alertname }}\n*Description:* {{ .Annotations.description }}\n{{ end }}",
				HTTPConfig: &config.HTTPClientConfig{
					Authorization: &config.Authorization{
						Credentials: ctx.Config.Alerting.SlackOAuthToken,
					},
				},
				Actions: slackButtons(),
			},
		},
	})
	return receivers
}

func teamSlackReceivers(ctx *common.RenderContext) []*config.Receiver {
	var receivers []*config.Receiver
	for _, tRoute := range ctx.Config.Alerting.TeamRoutes {
		var receiver config.Receiver

		receiver.Name = fmt.Sprintf("%s-slackReceiver", tRoute.TeamLabel)
		receiver.SlackConfigs = []*config.SlackConfig{
			{
				VSendResolved: common.ToPointer(true),
				APIURL:        "https://slack.com/api/chat.postMessage",
				Channel:       tRoute.SlackChannel,
				Color:         "{{ if eq .Status \"firing\" -}}{{ if eq .CommonLabels.severity \"warning\" -}}warning{{- else if eq .CommonLabels.severity \"critical\" -}}danger{{- else -}}#439FE0{{- end -}}{{ else -}}good{{- end }}",
				Title:         "[{{ .CommonLabels.alertname }} {{ .Status | toUpper }} {{ if eq .Status \"firing\" }}{{ end }}]",
				Text:          "{{ range .Alerts }}\n*Summary*: {{ .Annotations.summary }}\n*Severity: {{ .Labels.severity }}*\n*Cluster:* {{ .Labels.cluster }}\n*Alert:* {{ .Labels.alertname }}\n*Description:* {{ .Annotations.description }}\n{{ end }}",
				HTTPConfig: &config.HTTPClientConfig{
					Authorization: &config.Authorization{
						Credentials: ctx.Config.Alerting.SlackOAuthToken,
					},
				},
				Actions: slackButtons(),
			},
		}

		receivers = append(receivers, &receiver)
	}
	return receivers
}

func slackButtons() []config.SlackAction {
	return []config.SlackAction{
		{
			Type: "button",
			Text: "Runbook :book:",
			URL:  "{{ .CommonAnnotations.runbook_url }}",
		},
		{
			Type: "button",
			Text: "Query :prometheus:",
			URL:  queryString,
		},
		{
			Type: "button",
			Text: "Dashboard :grafana:",
			URL:  "{{ .CommonAnnotations.dashboard_url}}",
		},
	}
}
