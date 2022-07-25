local config = std.extVar('config');
local defaults = {
  defaults: self,
  name: 'http-prober',
  namespace: error 'must provide namespace',
  image: 'ghcr.io/arthursens/http-prober',
  version: 'v0.0.2',
  commonLabels: {
    'app.kubernetes.io/name': defaults.name,
    'app.kubernetes.io/part-of': 'kube-prometheus',
  },
};

function(params) {
  local prober = self,
  _config:: defaults + params,

  deployment: {
    apiVersion: 'apps/v1',
    kind: 'Deployment',
    metadata: {
      name: prober._config.name,
      namespace: prober._config.namespace,
      labels: prober._config.commonLabels,
    },
    spec: {
      replicas: 1,
      selector: {
        matchLabels: prober._config.commonLabels,
      },
      template: {
        metadata: {
          labels: prober._config.commonLabels,
        },
        spec: {
          containers: [
            {
              name: prober._config.name,
              image: prober._config.image + ':' + prober._config.version,
            },
          ],
        },
      },
    },
  },

  service: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: prober._config.name,
      namespace: prober._config.namespace,
      labels: prober._config.commonLabels,
    },
    spec: {
      ports: [
        {
          name: 'metrics',
          port: 8080,
          protocol: 'TCP',
          targetPort: 8080,
        },
      ],
      selector: prober._config.commonLabels,
      type: 'ClusterIP',
    },
  },

  serviceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: prober._config.name,
      namespace: prober._config.namespace,
      labels: prober._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/name',
      selector: {
        matchLabels: prober._config.commonLabels,
      },
      namespaceSelector: {
        matchNames: [
          prober._config.namespace,
        ],
      },
      endpoints: [{
        bearerTokenFile: '/var/run/secrets/kubernetes.io/serviceaccount/token',
        port: 'metrics',
        interval: '60s',
      }],
    },
  },
}
