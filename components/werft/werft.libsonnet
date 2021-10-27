local defaults = {
  local defaults = self,

  name: 'werft',
  namespace: error 'must provide namespace',
  // Used by pod network policies
  werftNamespace: error 'must provide werft namespace',
  // Remember to add 'app.kubernetes.io/component' to each component
  commonLabels: {
    'app.kubernetes.io/name': defaults.name,
    'app.kubernetes.io/part-of': 'kube-prometheus',
  },
};

function(params) {
  local w = self,
  _config:: defaults + params,

  service: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: w._config.name + '-metrics',
      namespace: w._config.werftNamespace,
      labels: w._config.commonLabels {
        'app.kubernetes.io/component': 'werft',
      },
    },
    spec: {
      selector: {
        component: 'werft',
      },
      ports: [{
        name: 'metrics',
        port: 9500,
      }],
    },
  },

  serviceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: w._config.name,
      namespace: w._config.namespace,
      labels: w._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/component',
      selector: {
        matchLabels: w._config.commonLabels {
          'app.kubernetes.io/component': 'werft',
        },
      },
      namespaceSelector: {
        matchNames: [
          w._config.werftNamespace,
        ],
      },
      endpoints: [{
        bearerTokenFile: '/var/run/secrets/kubernetes.io/serviceaccount/token',
        port: 'metrics',
        interval: '30s',
      }],
    },
  },

  networkPolicy: {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'NetworkPolicy',
    metadata: {
      name: 'werft-allow-kube-prometheus',
      namespace: w._config.werftNamespace,
      labels: w._config.commonLabels,
    },
    spec: {
      podSelector: {
        matchLabels: {
          component: 'werft',
        },
      },
      policyTypes: ['Ingress'],
      ingress: [{
        from: [{
          podSelector: {
            matchLabels: w._config.prometheusLabels,
          },
          namespaceSelector: {
            matchLabels: {
              namespace: w._config.namespace,
            },
          },
        }],
      }],
    },
  },
}
