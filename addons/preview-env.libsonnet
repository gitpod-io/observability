// The preview-environment addon provides json snippets that are specific for preview environment installations.
function(config) {

  assert std.objectHas(config.previewEnvironment, 'nodeExporterPort') && std.isNumber(config.previewEnvironment.nodeExporterPort) : (
    "If 'previewEnvironment' is set, 'nodeExporterPort' should be declared and it should be a number"
  ),

  values+:: {
    // On preview env, Gitpod and monitoring satellite are installed in the same namespace.
    gitpodParams+: {
      gitpodNamespace: config.namespace,
    },

    nodeExporter+: {
      port: config.previewEnvironment.nodeExporterPort,
    },

    prometheusOperator+: {
      resources+: {
        limits+: {
          memory: '1000Mi',
        },
      },
    },
  },

  prometheus+: {
    prometheus+: {
      spec+: {
        serviceMonitorNamespaceSelector: {
          matchLabels: {
            // Each Prometheus should only monitor its own preview environment.
            namespace: config.namespace,
          },
        },
        ruleNamespaceSelector: {
          matchLabels: {
            // Each Prometheus should only monitor its own preview environment.
            namespace: config.namespace,
          },
        },
      },
    },
  },
}
