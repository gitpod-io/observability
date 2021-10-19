// Before mapping and changing alerts severity, it is good to keep track on ho they are being categorized upstream!
// There is probably a good reason for why they are categorized the way they are.
local alertSeverityMap = {
  // Critical alerts
  // Map alerts as 'critical' if it indicates a problem that requires human intervention immediately.
  NodeFilesystemAlmostOutOfSpace: 'critical',

  // Warning alerts
  // Map alerts as 'warning' if it indicates a problem that needs human intervention, but it can wait until the next shift.
  KubeStateMetricsListErrors: 'warning',
  PrometheusRuleFailures: 'warning',

  // Info alerts
  // Map alerts as 'warning' if there is no need for human intervention at all, but it still provides useful information about the system behavior.
  Watchdog: 'info',
};

{
  spec+: {
    groups: std.map(
      function(group) group {
        rules: std.map(
          function(rule)
            if 'alert' in rule && (rule.alert in alertSeverityMap) then
              rule { labels+: { severity: alertSeverityMap[rule.alert] } }
            else
              rule,
          super.rules
        ),
      },
      super.groups
    ),
  },
}
