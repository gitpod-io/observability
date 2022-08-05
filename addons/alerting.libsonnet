function(config) {

  local teamMap =
    (
      if std.objectHas(config.alerting, 'platform') then
        [{ team: 'platform' }] else []
    ) +
    (
      if std.objectHas(config.alerting, 'ide') then
        [{ team: 'ide' }] else []
    ) +
    (
      if std.objectHas(config.alerting, 'workspace') then
        [{ team: 'workspace' }] else []
    ) +
    (
      if std.objectHas(config.alerting, 'webapp') then
        [{ team: 'webapp' }] else []
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
    for p in teamMap
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


  # This was a nightmare to do. The URL that we get from the query that triggered the alert is the address of the prometheus
  # Since we can't access it from outside, we want to link to grafana with the query
  # So we descent into madness, i.e. we use regex to replace the relevant parts and concatenate that with the url of our grafana. In order of execution
  # "reReplaceAll "%22" "%5C%22" (index .Alerts 0).GeneratorURL - .GeneratorURL is a link to the prometheus with the query. We replace %22 (", with (\"), as this is what makes grafana happy
  # reReplaceAll ".*expr=" ... - The URL is something like: http://prometheus.:9090/graph?g0.range_input=1h&g0.expr=QUERY&g0.tab=1 We keep everything after `expr=` and replace the rest with our grafana URL
  # reReplaceAll "&g0.tab=1" "%22%7D%5D%7D" - replaces the last bit (&g0.tab=1) with ("}]})
  # reReplaceAll `\\+` "%20" - replace all (+) with spaces ( ) - again to make grafana happy
  # reReplaceAll "%0A" "" - newlines with nothing
  # reReplaceAll "%28" "(" | reReplaceAll "%29" ")" - self explanatory
  local queryButtonTmpl = '{{ reReplaceAll "%22" "%5C%22" (index .Alerts 0).GeneratorURL | reReplaceAll ".*expr=" "https://grafana.gitpod.io/explore?orgId=1&left=%7B%22range%22:%7B%22from%22:%22now-1h%22,%22to%22:%22now%22%7D,%22datasource%22:%22VictoriaMetrics%22,%22queries%22:%5B%7B%22refId%22:%22A%22,%22expr%22:%22" | reReplaceAll "&g0.tab=1" "%22%7D%5D%7D" | reReplaceAll `\\+` "%20" | reReplaceAll "%0A" "" | reReplaceAll "%28" "(" | reReplaceAll "%29" ")" }}',

  local slackReceiver(name, channel) = {
    name: name,
    slack_configs: [
      {
        send_resolved: true,
        api_url: 'https://slack.com/api/chat.postMessage',
        channel: channel,
        http_config: {
          authorization: {
            credentials: config.alerting.slackOAuthToken,
          },
        },
        title: '[{{ .CommonLabels.alertname }} {{ .Status | toUpper }} {{ if eq .Status "firing" }}{{ end }}]',
        text: '{{ range .Alerts }}\n*Summary*: {{ .Annotations.summary }}\n*Severity: {{ .Labels.severity }}*\n*Cluster:* {{ .Labels.cluster }}\n*Alert:* {{ .Labels.alertname }}\n*Description:* {{ .Annotations.description }}\n{{ end }}\n',
        color: '{{ if eq .Status "firing" -}}{{ if eq .CommonLabels.severity "warning" -}}warning{{- else if eq .CommonLabels.severity "critical" -}}danger{{- else -}}#439FE0{{- end -}}{{ else -}}good{{- end }}',
        actions: [
          {
            type: 'button',
            text: 'Runbook :book:',
            url: '{{ .CommonAnnotations.runbook_url }}',
          },
          {
            type: 'button',
            text: 'Query :prometheus:',
            url: queryButtonTmpl,
          },
          {
            type: 'button',
            text: 'Dashboard :grafana:',
            url: '{{ .CommonAnnotations.dashboard_url}}',
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
        links: [
          {
            text: 'Runbook :book:',
            href: '{{ .CommonAnnotations.runbook_url }}',
          },
          {
            text: 'Query :prometheus:',
            href: queryButtonTmpl,
          },
          {
            text: 'Dashboard :grafana:',
            href: '{{ .CommonAnnotations.dashboard_url }}',
          },
        ],
      },
    ],
  },

  local teamSlackReceiversArr = [slackReceiver(p.team + 'Receiver', '#t_' + p.team + '_alerts') for p in teamMap],
  local genericSlackReceiverArr = [slackReceiver('genericReceiver', config.alerting.generic.slackChannel)],
  local genericCriticalReceiverArr = [
    if std.objectHas(config.alerting, 'pagerdutyRoutingKey') then
      pagerdutyReceiver('pagerDuty', config.alerting.pagerdutyRoutingKey)
    else
      slackReceiver('slackCriticalReceiver', config.alerting.generic.slackChannel),
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
