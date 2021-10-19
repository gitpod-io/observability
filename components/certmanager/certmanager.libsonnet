local defaults = {
  local defaults = self,

  name: 'certmanager',
  namespace: error 'must provide namespace',
  // Used by pod network policies
  prometheusLabels: error 'must provide prometheus labels',
  certmanagerNamespace: 'cert-manager',
  commonLabels: {
    'app.kubernetes.io/name': defaults.name,
    'app.kubernetes.io/part-of': 'kube-prometheus',
  },

  // Used to override default mixin configs
  mixin: {
    ruleLabels: {},
    _config: {
      certManagerJobLabel: 'certmanager',
    },
  },
};

function(params) {
  local c = self,
  _config:: defaults + params,

  assert std.isObject(c._config.mixin._config),
  mixin:: (import 'cert-manager-mixin/mixin.libsonnet') {
    _config+::
      c._config.mixin._config,
  },

  prometheusRule: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'PrometheusRule',
    metadata: {
      name: 'certmanager-monitoring-rules',
      namespace: $._config.namespace,
      labels: $._config.commonLabels + $._config.mixin.ruleLabels,
    },
    spec: {
      groups: $.mixin.prometheusRules.groups + $.mixin.prometheusAlerts.groups,
    },
  },

  // Service can only find pods within the same namespace, so it gotta be the same where certmanager was deployed.
  service: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: $._config.name + '-metrics',
      namespace: $._config.certmanagerNamespace,
      labels: $._config.commonLabels {
        'app.kubernetes.io/component': 'certmanager',
      },
    },
    spec: {
      selector: {
        app: 'cert-manager',
        'app.kubernetes.io/component': 'controller',
      },
      ports: [{
        name: 'metrics',
        port: 9402,
      }],
    },
  },

  serviceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: $._config.name,
      namespace: $._config.namespace,
      labels: $._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/name',
      selector: {
        matchLabels: $._config.commonLabels {
          'app.kubernetes.io/component': 'certmanager',
        },
      },
      namespaceSelector: {
        matchNames: [
          $._config.certmanagerNamespace,
        ],
      },
      endpoints: [{
        port: 'metrics',
        interval: '30s',
        honorLabels: true,
      }],
    },
  },

  networkPolicy: {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'NetworkPolicy',
    metadata: {
      name: 'certmanager-allow-kube-prometheus',
      namespace: $._config.certmanagerNamespace,
      labels: $._config.commonLabels,
    },
    spec: {
      podSelector: {
        matchLabels: {
          app: 'cert-manager',
          'app.kubernetes.io/component': 'controller',
        },
      },
      policyTypes: ['Ingress'],
      ingress: [{
        from: [{
          podSelector: {
            matchLabels: $._config.prometheusLabels,
          },
          namespaceSelector: {
            matchLabels: {
              namespace: $._config.namespace,
            },
          },
        }],
      }],
    },
  },
}
