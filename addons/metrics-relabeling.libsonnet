{
  kubernetesControlPlane+: {
    serviceMonitorKubelet+: {
      spec+: {
        endpoints: std.map(
          function(endpoint) endpoint {
            metricRelabelings+: if 'path' in endpoint && endpoint.path == '/metrics/cadvisor' then
              [
                {
                  sourceLabels: ['__name__'],
                  action: 'drop',
                  regex: 'container_(' + std.join('|',
                                                  [
                                                    'memory_failures_total',
                                                    'fs_reads_total',
                                                    'cpu_user_seconds_total',
                                                    'memory_failcnt',
                                                    'cpu_system_seconds_total',
                                                    'memory_max_usage_bytes',
                                                    'memory_swap',
                                                    'processes',
                                                    'memory_cache',
                                                    'memory_mapped_file',
                                                    'memory_usage_bytes',
                                                    'sockets',
                                                    'spec_cpu_period',
                                                    'spec_memory_limit_bytes',
                                                    'file_descriptors',
                                                    'spec_memory_reservation_limit_bytes',
                                                    'last_seen',
                                                    'spec_cpu_shares',
                                                    'spec_memory_swap_limit_bytes',
                                                    'threads_max',
                                                    'start_time_seconds',
                                                    'threads',
                                                    'ulimits_soft',
                                                    'cpu_cfs_periods_total',
                                                    'cpu_cfs_throttled_periods_total',
                                                    'spec_cpu_quota',
                                                    'blkio_device_usage_total',
                                                  ]) + ')',
                },
              ]
            else [],
          }
          , super.endpoints
        ),
      },
    },
  },

  kubeStateMetrics+: {
    serviceMonitor+: {
      spec+: {
        endpoints: std.map(
          function(endpoint) endpoint {
            metricRelabelings+: [
              {
                action: 'replace',
                regex: '(.*)',
                replacement: '$1',
                sourceLabels: ['label_cloud_google_com_gke_nodepool'],
                targetLabel: 'nodepool',
              },
              {
                action: 'labeldrop',
                regex: 'label_cloud_google_com_gke_nodepool',
              },
              {
                action: 'replace',
                regex: '(.*)',
                replacement: '$1',
                sourceLabels: ['label_topology_kubernetes_io_region'],
                targetLabel: 'region',
              },
              {
                action: 'labeldrop',
                regex: 'label_topology_kubernetes_io_region',
              },
              {
                action: 'replace',
                regex: '(.*)',
                replacement: '$1',
                sourceLabels: ['label_component'],
                targetLabel: 'component',
              },
              {
                action: 'labeldrop',
                regex: 'label_component',
              },
              {
                action: 'replace',
                regex: '(.*)',
                replacement: '$1',
                sourceLabels: ['label_workspace_type'],
                targetLabel: 'workspace_type',
              },
              {
                action: 'labeldrop',
                regex: 'label_workspace_type',
              },
              {
                action: 'replace',
                regex: '(.*)',
                replacement: '$1',
                sourceLabels: ['label_owner'],
                targetLabel: 'owner',
              },
              {
                action: 'labeldrop',
                regex: 'label_owner',
              },
              {
                action: 'replace',
                regex: '(.*)',
                replacement: '$1',
                sourceLabels: ['label_meta_id'],
                targetLabel: 'metaID',
              },
              {
                action: 'labeldrop',
                regex: 'label_meta_id',
              },
            ],
          }
          , super.endpoints
        ),
      },
    },
  },

  nodeExporter+: {
    serviceMonitor+: {
      spec+: {
        endpoints: std.map(
          function(endpoint) endpoint {
            relabelings+: [
              {
                action: 'replace',
                regex: '(.*)',
                replacement: '$1',
                sourceLabels: ['__meta_kubernetes_pod_node_name'],
                targetLabel: 'node',
              },
            ],
          }
          , super.endpoints
        ),
      },
    },
  },
}
