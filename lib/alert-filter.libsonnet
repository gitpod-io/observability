// Before mapping and changing alerts severity, it is good to keep track on ho they are being categorized upstream!
// There is probably a good reason for why they are categorized the way they are.
local unwatedAlerts = [
  // From Kubernetes
  'KubeStateMetricsListErrors',
  'KubeJobCompletion',
  'KubePodNotReady',
  'AggregatedAPIErrors',
  'CPUThrottlingHigh',
  'KubeProxyDown',


  // From node-exporter
  'NodeFilesystemSpaceFillingUp',
  'NodeHighNumberConntrackEntriesUsed',

  // From kube-prometheus
  'Watchdog',

  // From certmanager
  'CertManagerAbsent',
  'CertManagerCertExpirySoon',
  'CertManagerCertNotReady',
  'CertManagerHittingRateLimits',
];

{
  spec+: {
    groups: std.map(
      function(group) group {
        rules: std.filter(
          function(rule)
            // Here we put what we want to keep. And that is all recording rules
            // and everything that is not unwanted
            'record' in rule || !std.member(unwatedAlerts, rule.alert),
          group.rules
        ),
      },
      super.groups
    ),
  },
}
