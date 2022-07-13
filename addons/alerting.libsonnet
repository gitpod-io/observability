function(config) {

  local teamWebHookMap =
    (
      if std.objectHas(config.alerting, 'platform') then
        [{ team: 'platform', webhook: config.alerting.platform.slackWebhookURL }] else []
    ) +
    (
      if std.objectHas(config.alerting, 'ide') then
        [{ team: 'ide', webhook: config.alerting.ide.slackWebhookURL }] else []
    ) +
    (
      if std.objectHas(config.alerting, 'workspace') then
        [{ team: 'workspace', webhook: config.alerting.workspace.slackWebhookURL }] else []
    ) +
    (
      if std.objectHas(config.alerting, 'webapp') then
        [{ team: 'webapp', webhook: config.alerting.webapp.slackWebhookURL }] else []
    ),


  local routeTmpl = |||
    - receiver: %(receiverName)s
      match:
        team: %(team)s
  |||,

  local routeSeverityTmpl = |||
    - receiver: %(receiverName)s
      match:
        severity: %(severity)s
  |||,

  local teamRoutesTmpls = [
    if std.objectHas(p, 'team') then routeTmpl % {
      receiverName: p.team + 'Receiver',
      team: p.team,
    }
    for p in teamWebHookMap
  ],

  local criticalRouteTmpl = [
    routeSeverityTmpl % {
      receiverName: if std.objectHas(config.alerting, 'pagerdutyRoutingKey') then 'pagerDutyCriticalReceiver' else 'slackCriticalReceiver',
      severity: 'critical',
    },
  ],

  local warningRouteTmpl = [
    routeSeverityTmpl % {
      receiverName: 'genericReceiver',
      severity: 'warning',
    },
  ],

  local infoRouteTmpl = [
    routeSeverityTmpl % {
      receiverName: 'genericReceiver',
      severity: 'info',
    },
  ],

  // this is the uglies hack ever
  // but is the only way I could figure out to format this correctly (a json object for some reason messes up the order of the keys so it doesn't work either)
  local trimRoutesTmpl(routes) = std.lstripChars(std.strReplace(routes, '- |', ''), '\n'),

  local teamRoutes = trimRoutesTmpl(std.manifestYamlDoc(teamRoutesTmpls, quote_keys=false)),
  local criticalRoute = trimRoutesTmpl(std.manifestYamlDoc(criticalRouteTmpl, quote_keys=false)),
  local warningRoute = trimRoutesTmpl(std.manifestYamlDoc(warningRouteTmpl, quote_keys=false)),
  local infoRoute = trimRoutesTmpl(std.manifestYamlDoc(infoRouteTmpl, quote_keys=false)),
  local allRoutes = std.stripChars(criticalRoute + '\n' + teamRoutes + '\n' + warningRoute + '\n' + infoRoute, '[]'),

  local slackReceiver(name, channel, webhook) = {
    name: name,
    slack_configs: [
      {
        send_resolved: true,
        api_url: webhook,
        channel: channel,
        title: '[{{ .CommonLabels.alertname }} {{ .Status | toUpper }} {{ if eq .Status "firing" }}{{ end }}]',
        text: '{{ range .Alerts }}\n*Severity: {{ .Labels.severity }}*\n*Cluster:* {{ .Labels.cluster }}\n*Alert:* {{ .Labels.alertname }}\n*Description:* {{ .Annotations.description }}\n{{ end }}\n',
        color: '{{ if eq .Status "firing" -}}{{ if eq .CommonLabels.severity "warning" -}}warning{{- else if eq .CommonLabels.severity "critical" -}}danger{{- else -}}#439FE0{{- end -}}{{ else -}}good{{- end }}',
        actions: [
          {
            type: 'button',
            text: 'Runbook :book:',
            url: '{{ .CommonAnnotations.runbook_url }}',
          },
        ],
      },
    ],
  },

  local pagerdutyReceiver(team, key) = {
    name: team + 'CriticalReceiver',
    pagerduty_configs: [
      {
        send_resolved: true,
        routing_key: key,
      },
    ],
  },


  local teamSlackReceiversArr = [slackReceiver(p.team + 'Receiver', '#a_' + p.team + '_alerts', p.webhook) for p in teamWebHookMap],
  local genericSlackReceiverArr = [slackReceiver('genericReceiver', config.alerting.generic.slackChannel, config.alerting.generic.slackWebhookURL)],
  local genericCriticalReceiverArr = [
    if std.objectHas(config.alerting, 'pagerdutyRoutingKey') then
      pagerdutyReceiver('pagerDuty', config.alerting.pagerdutyRoutingKey)
    else
      slackReceiver('slackCriticalReceiver', config.alerting.generic.slackChannel, config.alerting.generic.slackWebhookURL),
  ],

  local teamSlackReceivers = std.manifestYamlDoc(teamSlackReceiversArr, quote_keys=false),
  local genericSlackReceiver = std.manifestYamlDoc(genericSlackReceiverArr, quote_keys=false),
  local genericCriticalReceiver = std.manifestYamlDoc(genericCriticalReceiverArr, quote_keys=false),
  local allReceivers = std.stripChars(genericCriticalReceiver + '\n' + teamSlackReceivers + '\n' + genericSlackReceiver, '[]'),

  values+:: {
    alertmanager+: {
      config: |||
        global:
          resolve_timeout: 5m
        route:
          receiver: Black_Hole
          group_by: ['...']
          routes:
        %(routes)s
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
        %(receivers)s
        - name: Watchdog
        - name: Black_Hole
        templates: []
      ||| % {
        routes: allRoutes,
        receivers: allReceivers,
      },
    },
  },
}
