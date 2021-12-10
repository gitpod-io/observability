local config = std.extVar('config');

{
  prometheus+: {
    prometheus+: {
      spec+: {
        nodeSelector+: config.nodeAffinity.nodeSelector,
      },
    },
  },

  alertmanager+: {
    alertmanager+: {
      spec+: {
        nodeSelector+: config.nodeAffinity.nodeSelector,
      },
    },
  },

  grafana+: {
    deployment+: {
      spec+: {
        template+: {
          spec+: {
            nodeSelector+: config.nodeAffinity.nodeSelector,
          },
        },
      },
    },
  },

  prometheusOperator+: {
    deployment+: {
      spec+: {
        template+: {
          spec+: {
            nodeSelector+: config.nodeAffinity.nodeSelector,
          },
        },
      },
    },
  },

  kubeStateMetrics+: {
    deployment+: {
      spec+: {
        template+: {
          spec+: {
            nodeSelector+: config.nodeAffinity.nodeSelector,
          },
        },
      },
    },
  },
} +
(if std.objectHas(config, 'tracing') then {
   otelCollector+: {
     deployment+: {
       spec+: {
         template+: {
           spec+: {
             nodeSelector+: config.nodeAffinity.nodeSelector,
           },
         },
       },
     },
   },
 } else {})
