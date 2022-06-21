function(config) {

  assert std.objectHas(config.alerting, 'slackWebhookURLWarning') &&
         std.objectHas(config.alerting, 'slackWebhookURLInfo') &&
         std.objectHas(config.alerting, 'slackChannelPrefix') : (
    "If 'alerting' is set, 'slackWebhookURLWarning', 'slackWebhookURLInfo' and 'slackChannelPrefix' should be declared"
  ),

  assert std.objectHas(config.alerting, 'slackWebhookURLCritical') || std.objectHas(config.alerting, 'pagerdutyRoutingKey') : (
    "If 'alerting' is set, 'slackWebhookURLCritical' or 'pagerdutyRoutingKey' should be declared"
  ),

  local IDECriticalReceiver =
    if
      (std.objectHas(config.alerting, 'IDE') && std.objectHas(config.alerting.IDE, 'pagerdutyRoutingKey')) ||
      (!std.objectHas(config.alerting, 'IDE') && std.objectHas(config.alerting, 'pagerdutyRoutingKey'))
    then
      |||
        pagerduty_configs:
          - send_resolved: true
            routing_key: '%(pagerdutyRoutingKey)s'
      ||| % {
        pagerdutyRoutingKey: if std.objectHas(config.alerting, 'IDE') && std.objectHas(config.alerting.IDE, 'pagerdutyRoutingKey') then config.alerting.IDE.pagerdutyRoutingKey
        else config.alerting.pagerdutyRoutingKey,
      }
    else
      |||
        slack_configs:
          - send_resolved: true
            api_url: %(slackWebhookUrlCritical)s
            channel: '%(slackChannelPrefix)s_critical'
            title: '[{{ .Status | toUpper }}{{ if eq .Status "firing" }}{{ end }}] %(clusterName)s Monitoring'
            text: |
              {{ range .Alerts }}
              **Please take immediate action!**
              *Cluster:* {{ .Labels.cluster }}
              *Alert:* {{ .Labels.alertname }}
              *Description:* {{ .Annotations.description }}
              {{ end }}
            actions:
            - type: button
              text: 'Runbook :book:'
              url: '{{ .CommonAnnotations.runbook_url }}'
      ||| % {
        clusterName: config.clusterName,
        slackChannelPrefix: config.alerting.slackChannelPrefix,
        slackWebhookUrlCritical: if std.objectHas(config.alerting, 'IDE') && std.objectHas(config.alerting.IDE, 'slackWebhookURLCritical') then config.alerting.IDE.slackWebhookURLCritical
        else config.alerting.slackWebhookURLCritical,
      },

  local webappCriticalReceiver =
    if
      (std.objectHas(config.alerting, 'webapp') && std.objectHas(config.alerting.webapp, 'pagerdutyRoutingKey')) ||
      (!std.objectHas(config.alerting, 'webapp') && std.objectHas(config.alerting, 'pagerdutyRoutingKey'))
    then
      |||
        pagerduty_configs:
          - send_resolved: true
            routing_key: '%(pagerdutyRoutingKey)s'
      ||| % {
        pagerdutyRoutingKey: if std.objectHas(config.alerting, 'webapp') && std.objectHas(config.alerting.webapp, 'pagerdutyRoutingKey') then config.alerting.webapp.pagerdutyRoutingKey
        else config.alerting.pagerdutyRoutingKey,
      }
    else
      |||
        slack_configs:
          - send_resolved: true
            api_url: %(slackWebhookUrlCritical)s
            channel: '%(slackChannelPrefix)s_critical'
            title: '[{{ .Status | toUpper }}{{ if eq .Status "firing" }}{{ end }}] %(clusterName)s Monitoring'
            text: |
              {{ range .Alerts }}
              **Please take immediate action!**
              *Cluster:* {{ .Labels.cluster }}
              *Alert:* {{ .Labels.alertname }}
              *Description:* {{ .Annotations.description }}
              {{ end }}
            actions:
            - type: button
              text: 'Runbook :book:'
              url: '{{ .CommonAnnotations.runbook_url }}'
      ||| % {
        clusterName: config.clusterName,
        slackChannelPrefix: config.alerting.slackChannelPrefix,
        slackWebhookUrlCritical: if std.objectHas(config.alerting, 'webapp') && std.objectHas(config.alerting.webapp, 'slackWebhookURLCritical') then config.alerting.webapp.slackWebhookURLCritical
        else config.alerting.slackWebhookURLCritical,
      },

  local workspaceCriticalReceiver =
    if
      (std.objectHas(config.alerting, 'workspace') && std.objectHas(config.alerting.workspace, 'pagerdutyRoutingKey')) ||
      (!std.objectHas(config.alerting, 'workspace') && std.objectHas(config.alerting, 'pagerdutyRoutingKey'))
    then
      |||
        pagerduty_configs:
          - send_resolved: true
            routing_key: '%(pagerdutyRoutingKey)s'
      ||| % {
        pagerdutyRoutingKey: if std.objectHas(config.alerting, 'workspace') && std.objectHas(config.alerting.workspace, 'pagerdutyRoutingKey') then config.alerting.workspace.pagerdutyRoutingKey
        else config.alerting.pagerdutyRoutingKey,
      }
    else
      |||
        slack_configs:
          - send_resolved: true
            api_url: %(slackWebhookUrlCritical)s
            channel: '%(slackChannelPrefix)s_critical'
            title: '[{{ .Status | toUpper }}{{ if eq .Status "firing" }}{{ end }}] %(clusterName)s Monitoring'
            text: |
              {{ range .Alerts }}
              **Please take immediate action!**
              *Cluster:* {{ .Labels.cluster }}
              *Alert:* {{ .Labels.alertname }}
              *Description:* {{ .Annotations.description }}
              {{ end }}
            actions:
            - type: button
              text: 'Runbook :book:'
              url: '{{ .CommonAnnotations.runbook_url }}'
      ||| % {
        clusterName: config.clusterName,
        slackChannelPrefix: config.alerting.slackChannelPrefix,
        slackWebhookUrlCritical: if std.objectHas(config.alerting, 'workspace') && std.objectHas(config.alerting.workspace, 'slackWebhookURLCritical') then config.alerting.workspace.slackWebhookURLCritical
        else config.alerting.slackWebhookURLCritical,
      },

  local platformCriticalReceiver =
    if
      (std.objectHas(config.alerting, 'platform') && std.objectHas(config.alerting.platform, 'pagerdutyRoutingKey')) ||
      (!std.objectHas(config.alerting, 'platform') && std.objectHas(config.alerting, 'pagerdutyRoutingKey'))
    then
      |||
        pagerduty_configs:
          - send_resolved: true
            routing_key: '%(pagerdutyRoutingKey)s'
      ||| % {
        pagerdutyRoutingKey: if std.objectHas(config.alerting, 'platform') && std.objectHas(config.alerting.platform, 'pagerdutyRoutingKey') then config.alerting.platform.pagerdutyRoutingKey
        else config.alerting.pagerdutyRoutingKey,
      }
    else
      |||
        slack_configs:
          - send_resolved: true
            api_url: %(slackWebhookUrlCritical)s
            channel: '%(slackChannelPrefix)s_critical'
            title: '[{{ .Status | toUpper }}{{ if eq .Status "firing" }}{{ end }}] %(clusterName)s Monitoring'
            text: |
              {{ range .Alerts }}
              **Please take immediate action!**
              *Cluster:* {{ .Labels.cluster }}
              *Alert:* {{ .Labels.alertname }}
              *Description:* {{ .Annotations.description }}
              {{ end }}
            actions:
            - type: button
              text: 'Runbook :book:'
              url: '{{ .CommonAnnotations.runbook_url }}'
      ||| % {
        clusterName: config.clusterName,
        slackChannelPrefix: config.alerting.slackChannelPrefix,
        slackWebhookUrlCritical: if std.objectHas(config.alerting, 'platform') && std.objectHas(config.alerting.platform, 'slackWebhookURLCritical') then config.alerting.platform.slackWebhookURLCritical
        else config.alerting.slackWebhookURLCritical,
      },

  local genericCriticalReceiver =
    if std.objectHas(config.alerting, 'pagerdutyRoutingKey') then
      |||
        pagerduty_configs:
          - send_resolved: true
            routing_key: '%(pagerdutyRoutingKey)s'
      ||| % {
        pagerdutyRoutingKey: config.alerting.pagerdutyRoutingKey,
      }
    else
      |||
        slack_configs:
          - send_resolved: true
            api_url: %(slackWebhookUrlCritical)s
            channel: '%(slackChannelPrefix)s_critical'
            title: '[{{ .Status | toUpper }}{{ if eq .Status "firing" }}{{ end }}] %(clusterName)s Monitoring'
            text: |
              {{ range .Alerts }}
              **Please take immediate action!**
              *Cluster:* {{ .Labels.cluster }}
              *Alert:* {{ .Labels.alertname }}
              *Description:* {{ .Annotations.description }}
              {{ end }}
            actions:
            - type: button
              text: 'Runbook :book:'
              url: '{{ .CommonAnnotations.runbook_url }}'
      ||| % {
        clusterName: config.clusterName,
        slackWebhookUrlCritical: config.alerting.slackWebhookURLCritical,
        slackChannelPrefix: config.alerting.slackChannelPrefix,
      },

  values+:: {
    alertmanager+: {
      config: |||
        global:
          resolve_timeout: 5m
        route:
          receiver: Black_Hole
          group_by: ['...']
          routes:
          - receiver: IDECriticalReceiver
            match:
              severity: critical
              team: ide
          - receiver: webappCriticalReceiver
            match:
              severity: critical
              team: webapp
          - receiver: workspaceCriticalReceiver
            match:
              severity: critical
              team: workspace
          - receiver: platformCriticalReceiver
            match:
              severity: critical
              team: platform
          - receiver: genericCriticalReceiver
            match:
              severity: critical
          - receiver: SlackWarning
            match:
              severity: warning
          - receiver: SlackInfo
            match:
              severity: info
          - receiver: Watchdog
            match:
              alertname: Watchdog
          group_wait: 30s
          group_interval: 5m
          repeat_interval: 6h
        inhibit_rules:
        - source_match:
            severity: critical
          target_match_re:
            severity: warning|info
          equal:
          - alertname
        - source_match:
            severity: warning
          target_match_re:
            severity: info
          equal:
          - alertname
        receivers:
        - name: Black_Hole
        - name: Watchdog
        - name: IDECriticalReceiver
          %(IDECriticalReceiver)s
        - name: webappCriticalReceiver
          %(webappCriticalReceiver)s
        - name: workspaceCriticalReceiver
          %(workspaceCriticalReceiver)s
        - name: platformCriticalReceiver
          %(platformCriticalReceiver)s
        - name: genericCriticalReceiver
          %(genericCriticalReceiver)s
        - name: SlackWarning
          slack_configs:
          - send_resolved: true
            api_url: %(slackWebhookUrlWarning)s
            channel: '%(slackChannelPrefix)s_warning'
            title: '[{{ .Status | toUpper }}{{ if eq .Status "firing" }}{{ end }}] %(clusterName)s Monitoring'
            text: |
              {{ range .Alerts }}
              **Please take a look when possible**
              *Cluster:* {{ .Labels.cluster }}
              *Alert:* {{ .Labels.alertname }}
              *Description:* {{ .Annotations.description }}
              {{ end }}
            actions:
            - type: button
              text: 'Runbook :book:'
              url: '{{ .CommonAnnotations.runbook_url }}'
        - name: SlackInfo
          slack_configs:
          - send_resolved: true
            api_url: %(slackWebhookUrlInfo)s
            channel: '%(slackChannelPrefix)s_info'
            title: '[{{ .Status | toUpper }}{{ if eq .Status "firing" }}{{ end }}] %(clusterName)s Monitoring'
            text: |
              {{ range .Alerts }}
              **No need for human intervention :slightly_smiling_face:
              *Cluster:* {{ .Labels.cluster }}
              *Alert:* {{ .Labels.alertname }}
              *Description:* {{ .Annotations.description }}
              {{ end }}
            actions:
            - type: button
              text: 'Runbook :book:'
              url: '{{ .CommonAnnotations.runbook_url }}'
        templates: []
      ||| % {
        clusterName: config.clusterName,
        slackWebhookUrlWarning: config.alerting.slackWebhookURLWarning,
        slackWebhookUrlInfo: config.alerting.slackWebhookURLInfo,
        slackChannelPrefix: config.alerting.slackChannelPrefix,
        pagerdutyRoutingKey: config.alerting.pagerdutyRoutingKey,
        IDECriticalReceiver: IDECriticalReceiver,
        webappCriticalReceiver: webappCriticalReceiver,
        workspaceCriticalReceiver: workspaceCriticalReceiver,
        platformCriticalReceiver: platformCriticalReceiver,
        genericCriticalReceiver: genericCriticalReceiver,
      },
    },
  },
}
