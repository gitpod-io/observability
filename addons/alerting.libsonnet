function(config) {

  assert std.objectHas(config.alerting, 'slackWebhookURLWarning') &&
         std.objectHas(config.alerting, 'slackWebhookURLInfo') &&
         std.objectHas(config.alerting, 'slackChannelPrefix') : (
    "If 'alerting' is set, 'slackWebhookURLWarning', 'slackWebhookURLInfo' and 'slackChannelPrefix' should be declared"
  ),

  assert std.objectHas(config.alerting, 'slackWebhookURLCritical') || std.objectHas(config.alerting, 'pagerdutyRoutingKey') : (
    "If 'alerting' is set, 'slackWebhookURLCritical' or 'pagerdutyRoutingKey' should be declared"
  ),

  local pdConfig =
    |||
      pagerduty_configs:
        - send_resolved: true
          routing_key: '%(pagerdutyRoutingKey)s'
    |||,

  local slackConfig =
    |||
      slack_configs:
        - send_resolved: true
          api_url: %(webhookURL)s
          channel: '%(slackChannel)s'
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
    |||,

  local globalPagerDutyRoutingKey = if std.objectHas(config.alerting, 'pagerdutyRoutingKey')
  then config.alerting.pagerdutyRoutingKey
  else '',

  local globalSlackWebhookURL = if std.objectHas(config.alerting, 'slackWebhookURLCritical')
  then config.alerting.slackWebhookURLCritical
  else '',

  local globalCriticalReceiver =
    if std.length(globalPagerDutyRoutingKey) > 0
    then
      pdConfig % {
        pagerdutyRoutingKey: globalPagerDutyRoutingKey,
      }
    else
      slackConfig % {
        clusterName: config.clusterName,
        webhookURL: globalSlackWebhookURL,
        slackChannel: config.alerting.slackChannelPrefix + '_critical',
      },

  local IDEPagerDutyRoutingKey = if std.objectHas(config.alerting, 'IDE') && std.objectHas(config.alerting.IDE, 'pagerdutyRoutingKey')
  then config.alerting.IDE.pagerdutyRoutingKey
  else '',

  local IDESlackWebhookURL = if std.objectHas(config.alerting, 'IDE') && std.objectHas(config.alerting.IDE, 'slackWebhookURL')
  then config.alerting.IDE.slackWebhookURL
  else '',

  local IDECriticalReceiver =
    if !std.objectHas(config.alerting, 'IDE')
    then globalCriticalReceiver
    else if std.length(IDEPagerDutyRoutingKey) > 0
    then
      pdConfig % {
        pagerdutyRoutingKey: IDEPagerDutyRoutingKey,
      }
    else
      assert std.objectHas(config.alerting.IDE, 'slackWebhookURL') && std.objectHas(config.alerting.IDE, 'slackChannel') : (
        "Alerting for IDE team will be done via Slack, but 'slackWebhookURL' or 'slackChannel' is missing."
      );

      slackConfig % {
        clusterName: config.clusterName,
        slackChannel: config.alerting.IDE.slackChannel,
        webhookURL: IDESlackWebhookURL,
      },

  local webappPagerDutyRoutingKey = if std.objectHas(config.alerting, 'webapp') && std.objectHas(config.alerting.webapp, 'pagerdutyRoutingKey')
  then config.alerting.webapp.pagerdutyRoutingKey
  else '',

  local webappSlackWebhookURL = if std.objectHas(config.alerting, 'webapp') && std.objectHas(config.alerting.webapp, 'slackWebhookURL')
  then config.alerting.webapp.slackWebhookURL
  else '',

  local webappCriticalReceiver =
    if !std.objectHas(config.alerting, 'webapp')
    then globalCriticalReceiver
    else if std.length(webappPagerDutyRoutingKey) > 0
    then
      pdConfig % {
        pagerdutyRoutingKey: webappPagerDutyRoutingKey,
      }
    else
      assert std.objectHas(config.alerting.webapp, 'slackWebhookURL') && std.objectHas(config.alerting.webapp, 'slackChannel') : (
        "Alerting for webapp team will be done via Slack, but 'slackWebhookURL' or 'slackChannel' is missing."
      );

      slackConfig % {
        clusterName: config.clusterName,
        slackChannel: config.alerting.webapp.slackChannel,
        webhookURL: webappSlackWebhookURL,
      },

  local workspacePagerDutyRoutingKey = if std.objectHas(config.alerting, 'workspace') && std.objectHas(config.alerting.workspace, 'pagerdutyRoutingKey')
  then config.alerting.workspace.pagerdutyRoutingKey
  else '',

  local workspaceSlackWebhookURL = if std.objectHas(config.alerting, 'workspace') && std.objectHas(config.alerting.workspace, 'slackWebhookURL')
  then config.alerting.workspace.slackWebhookURL
  else '',

  local workspaceCriticalReceiver =
    if !std.objectHas(config.alerting, 'workspace')
    then globalCriticalReceiver
    else if std.length(workspacePagerDutyRoutingKey) > 0
    then
      pdConfig % {
        pagerdutyRoutingKey: workspacePagerDutyRoutingKey,
      }
    else
      assert std.objectHas(config.alerting.workspace, 'slackWebhookURL') && std.objectHas(config.alerting.workspace, 'slackChannel') : (
        "Alerting for workspace team will be done via Slack, but 'slackWebhookURL' or 'slackChannel' is missing."
      );

      slackConfig % {
        clusterName: config.clusterName,
        slackChannel: config.alerting.workspace.slackChannel,
        webhookURL: workspaceSlackWebhookURL,
      },

  local platformPagerDutyRoutingKey = if std.objectHas(config.alerting, 'platform') && std.objectHas(config.alerting.platform, 'pagerdutyRoutingKey')
  then config.alerting.platform.pagerdutyRoutingKey
  else '',

  local platformSlackWebhookURL = if std.objectHas(config.alerting, 'platform') && std.objectHas(config.alerting.platform, 'slackWebhookURL')
  then config.alerting.platform.slackWebhookURL
  else '',

  local platformCriticalReceiver =
    if !std.objectHas(config.alerting, 'platform')
    then globalCriticalReceiver
    else if std.length(platformPagerDutyRoutingKey) > 0
    then
      pdConfig % {
        pagerdutyRoutingKey: platformPagerDutyRoutingKey,
      }
    else
      assert std.objectHas(config.alerting.platform, 'slackWebhookURL') && std.objectHas(config.alerting.platform, 'slackChannel') : (
        "Alerting for platform team will be done via Slack, but 'slackWebhookURL' or 'slackChannel' is missing."
      );

      slackConfig % {
        clusterName: config.clusterName,
        slackChannel: config.alerting.platform.slackChannel,
        webhookURL: platformSlackWebhookURL,
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
          - receiver: globalCriticalReceiver
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
        - name: globalCriticalReceiver
          %(globalCriticalReceiver)s
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
        globalCriticalReceiver: globalCriticalReceiver,
      },
    },
  },
}
