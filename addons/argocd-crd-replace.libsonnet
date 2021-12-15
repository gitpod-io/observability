// Some CRDs are failing to be applied by argo with the following error:
// CustomResourceDefinition.apiextensions.k8s.io "prometheuses.monitoring.coreos.com" is invalid: metadata.annotations: Too long: must have at most 262144 bytes
//
// This can be fixed by forcing the use of 'kubectl replace' when being synced by ArgoCD
{
  prometheusOperator+: {
    '0alertmanagerConfigCustomResourceDefinition'+: {
      metadata+: {
        annotations+: {
          'argocd.argoproj.io/sync-options': 'Replace=true',
        },
      },
    },

    '0alertmanagerCustomResourceDefinition'+: {
      metadata+: {
        annotations+: {
          'argocd.argoproj.io/sync-options': 'Replace=true',
        },
      },
    },

    '0podmonitorCustomResourceDefinition'+: {
      metadata+: {
        annotations+: {
          'argocd.argoproj.io/sync-options': 'Replace=true',
        },
      },
    },

    '0probeCustomResourceDefinition'+: {
      metadata+: {
        annotations+: {
          'argocd.argoproj.io/sync-options': 'Replace=true',
        },
      },
    },

    '0prometheusCustomResourceDefinition'+: {
      metadata+: {
        annotations+: {
          'argocd.argoproj.io/sync-options': 'Replace=true',
        },
      },
    },

    '0prometheusruleCustomResourceDefinition'+: {
      metadata+: {
        annotations+: {
          'argocd.argoproj.io/sync-options': 'Replace=true',
        },
      },
    },

    '0servicemonitorCustomResourceDefinition'+: {
      metadata+: {
        annotations+: {
          'argocd.argoproj.io/sync-options': 'Replace=true',
        },
      },
    },

    '0thanosrulerCustomResourceDefinition'+: {
      metadata+: {
        annotations+: {
          'argocd.argoproj.io/sync-options': 'Replace=true',
        },
      },
    },
  },
}
