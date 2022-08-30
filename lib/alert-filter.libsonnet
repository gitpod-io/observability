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

  // From kubernetes
  'KubePodCrashLooping',
  'KubeDeploymentGenerationMismatch',
  'KubeDeploymentReplicasMismatch',
  'KubeStatefulSetReplicasMismatch',
  'KubeStatefulSetGenerationMismatch',
  'KubeStatefulSetUpdateNotRolledOut',
  'KubeDaemonSetRolloutStuck',
  'KubeContainerWaiting',
  'KubeDaemonSetNotScheduled',  // Re-added to platform-mixin
  'KubeDaemonSetMisScheduled',
  'KubeJobNotCompleted',  // Re-added to platform-mixin
  'KubeJobFailed',  // Re-added to platform-mixin
  'KubeHpaReplicasMismatch',
  'KubeHpaMaxedOut',
  'KubeCPUOvercommit',  // Re-added to platform-mixin
  'KubeMemoryOvercommit',  // Re-added to platform-mixin
  'KubeCPUQuotaOvercommit',
  'KubeMemoryQuotaOvercommit',
  'KubeQuotaAlmostFull',
  'KubeQuotaFullyUsed',
  'KubeQuotaExceeded',
  'KubePersistentVolumeFillingUp',  // Re-added to platform-mixin
  'KubePersistentVolumeInodesFillingUp',
  'KubePersistentVolumeErrors',  // Re-added to platform-mixin
  'KubeVersionMismatch',  // Re-added to platform-mixin
  'KubeAPIErrorBudgetBurn',
  'KubeClientCertificateExpiration',
  'KubeAggregatedAPIErrors',
  'KubeAggregatedAPIDown',
  'KubeAPIDown',
  'KubeAPITerminatedRequests',
  'KubeNodeNotReady',  // Re-added to platform-mixin
  'KubeNodeUnreachable',
  'KubeletTooManyPods',
  'KubeNodeReadinessFlapping',
  'KubeletPlegDurationHigh',
  'KubeletPodStartUpLatencyHigh',
  'KubeletClientCertificateExpiration',
  'KubeletServerCertificateExpiration',
  'KubeletClientCertificateRenewalErrors',
  'KubeletServerCertificateRenewalErrors',
  'KubeletDown',  // Re-added to platform-mixin
  'KubeClientErrors',
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
