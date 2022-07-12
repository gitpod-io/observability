function(config) {

  local teamWebHookMap = [
    {
      team: 'platform',
      webhook: config.alerting.platform.slackWebhookURL,
    },
    {
      team: 'ide',
      webhook: config.alerting.IDE.slackWebhookURL,
    },
    {
      team: 'workspace',
      webhook: config.alerting.workspace.slackWebhookURL,
    },
    {
      team: 'webapp',
      webhook: config.alerting.webapp.slackWebhookURL,
    },
  ],

  local routeTmpl = |||
    - receiver: %(team)sTeamReceiver
      match:
        team: %(team)s
  |||,

  local routeCriticalTmpl = |||
    - receiver: %(team)sTeamCriticalReceiver
      match:
        team: %(team)s
        severity: %(severity)s
  |||,

  local teamRoutesTmpls = [
    if std.objectHas(p, 'team') then routeTmpl % {
      team: p.team,
    }
    for p in teamWebHookMap
  ],

  local teamCriticalRoutesTmpls = [
    if std.objectHas(p, 'team') && std.objectHas(p, 'pd_key') then routeCriticalTmpl % {
      team: p.team,
      severity: 'critical',
    }
    for p in teamWebHookMap
  ],

  local slackReceiver(team, webhook) = {
    name: team + 'TeamReceiver',
    slack_configs: [
      {
        send_resolved: true,
        api_url: webhook,
        channel: 'a_' + team + '_alerts',
        title: '[{{ .Status | toUpper }}{{ if eq .Status "firing" }}{{ end }}] {{ .Labels.cluster }} Monitoring',
        text: '{{ range .Alerts }}\n**Please take immediate action!**\n*Cluster:* {{ .Labels.cluster }}\n*Alert:* {{ .Labels.alertname }}\n*Description:* {{ .Annotations.description }}\n{{ end }}\n',
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
    name: team + 'TeamCriticalReceiver',
    pagerduty_configs: [
      {
        send_resolved: true,
        routing_key: key,
      },
    ],
  },

  local teamCriticalReceiversArr = [if std.objectHas(p, 'pd_key') then pagerdutyReceiver(p.team, p.pd_key) for p in teamWebHookMap],

  local teamNonCriticalReceiversArr =
    [slackReceiver(config.alerting.generic.name, config.alerting.generic.slackWebhookURL)] +
    [slackReceiver(p.team, p.webhook) for p in teamWebHookMap],

  // this is the uglies hack ever
  // but is the only way I could figure out to format this correctly (a json object for some reason messes up the order of the keys so it doesn't work either)
  local trimRoutesTmpl(routes) = std.lstripChars(std.strReplace(routes, '- |', ''), '\n'),

  local routes = trimRoutesTmpl(std.manifestYamlDoc(teamRoutesTmpls, quote_keys=false)),
  local criticalRoutes = trimRoutesTmpl(std.manifestYamlDoc(std.prune(teamCriticalRoutesTmpls), quote_keys=false)),
  local allRoutes = std.stripChars(routes + '\n' + criticalRoutes, '[]'),

  local teamNonCriticalReceivers = std.manifestYamlDoc(teamNonCriticalReceiversArr, quote_keys=false),
  local teamCriticalReceivers = std.manifestYamlDoc(std.prune(teamCriticalReceiversArr), quote_keys=false),
  local allReceivers = std.stripChars(teamNonCriticalReceivers + '\n' + teamCriticalReceivers, '[]'),

  values+:: {
    alertmanager+: {
      config: |||
        global:
          resolve_timeout: 5m
        route:
          receiver: %(generic)sTeamReceiver
          group_by: ['...']
          routes:
        %(teamRoutes)s
          - receiver: globalCriticalReceiver
            match:
              severity: critical
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
        %(teamReceivers)s
        - name: Watchdog
        - name: globalCriticalReceiver
          pagerduty_configs:
          - send_resolved: true
            routing_key: 'global-pd-routing-key'
        templates: []
      ||| % {
        generic: config.alerting.generic.name,
        teamRoutes: allRoutes,
        teamReceivers: allReceivers,
        clusterName: config.clusterName,
        pagerdutyRoutingKey: config.alerting.pagerdutyRoutingKey,
      },
    },
  },
}
