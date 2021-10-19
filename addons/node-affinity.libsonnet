local affinityLabel = std.extVar('node_affinity_label');

if affinityLabel != '' then
  {
    prometheus+: {
      prometheus+: {
        spec+: {
          nodeSelector+: {
            [affinityLabel]: 'true',
          },
        },
      },
    },

    alertmanager+: {
      alertmanager+: {
        spec+: {
          nodeSelector+: {
            [affinityLabel]: 'true',
          },
        },
      },
    },

    grafana+: {
      deployment+: {
        spec+: {
          template+: {
            spec+: {
              nodeSelector+: {
                [affinityLabel]: 'true',
              },
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
              nodeSelector+: {
                [affinityLabel]: 'true',
              },
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
              nodeSelector+: {
                [affinityLabel]: 'true',
              },
            },
          },
        },
      },
    },
  }
else {}
