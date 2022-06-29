local defaults = {
  local defaults = self,

  name: 'gitpod',
  namespace: error 'must provide namespace',
  // Used by pod network policies
  prometheusLabels: error 'must provide prometheus labels',
  gitpodNamespace: error 'must provide gitpod namespace',
  // Remember to add 'app.kubernetes.io/component' to each component
  commonLabels: {
    'app.kubernetes.io/name': defaults.name,
    'app.kubernetes.io/part-of': 'kube-prometheus',
  },
  // Used to override default mixin configs
  mixin: {
    ruleLabels: {},
    _config: {},
  },
};

function(params) {
  local g = self,
  _config:: defaults + params,

  assert std.isObject(g._config.mixin._config),
  crossTeamsMixin:: (import 'gitpod/cross-teams/mixin.libsonnet') {
    _config+::
      g._config.mixin._config,
  },

  ideMixin:: (import 'gitpod/IDE/mixin.libsonnet') {
    _config+::
      g._config.mixin._config,
  },

  webappMixin:: (import 'gitpod/meta/mixin.libsonnet') {
    _config+::
      g._config.mixin._config,
  },

  workspaceMixin:: (import 'gitpod/workspace/mixin.libsonnet') {
    _config+::
      g._config.mixin._config,
  },

  selfhostedMixin:: (import 'gitpod/self-hosted/mixin.libsonnet') {
    _config+::
      g._config.mixin._config,
  },

  platformMixin:: (import 'gitpod/platform/mixin.libsonnet') {
    _config+::
      g._config.mixin._config,
  },

  mixin:: $.crossTeamsMixin + $.ideMixin + $.webappMixin + $.workspaceMixin + $.selfhostedMixin + $.platformMixin,

  prometheusRule: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'PrometheusRule',
    metadata: {
      name: 'gitpod-monitoring-rules',
      namespace: $._config.namespace,
      labels: $._config.commonLabels + $._config.mixin.ruleLabels,
    },
    spec: {
      groups: $.mixin.prometheusRules.groups + $.mixin.prometheusAlerts.groups,
    },
  },

  // Service can only find pods within the same namespace, so it gotta be the same where gitpod was deployed.
  agentSmithService: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: $._config.name + '-agent-smith',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels {
        'app.kubernetes.io/component': 'agent-smith',
      },
    },
    spec: {
      selector: {
        component: 'agent-smith',
      },
      ports: [{
        name: 'metrics',
        port: 9500,
      }],
    },
  },

  agentSmithServiceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: $._config.name + '-agent-smith',
      namespace: $._config.namespace,
      labels: $._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/component',
      selector: {
        matchLabels: $._config.commonLabels {
          'app.kubernetes.io/component': 'agent-smith',
        },
      },
      namespaceSelector: {
        matchNames: [
          $._config.gitpodNamespace,
        ],
      },
      endpoints: [{
        bearerTokenFile: '/var/run/secrets/kubernetes.io/serviceaccount/token',
        port: 'metrics',
        interval: '30s',
      }],
    },
  },

  agentSmithNetworkPolicy: {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'NetworkPolicy',
    metadata: {
      name: 'agent-smith-allow-kube-prometheus',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels,
    },
    spec: {
      podSelector: {
        matchLabels: {
          component: 'agent-smith',
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

  blobserveService: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: $._config.name + '-blobserve',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels {
        'app.kubernetes.io/component': 'blobserve',
      },
    },
    spec: {
      selector: {
        component: 'blobserve',
      },
      ports: [{
        name: 'metrics',
        port: 9500,
      }],
    },
  },

  blobserveServiceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: $._config.name + '-blobserve',
      namespace: $._config.namespace,
      labels: $._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/component',
      selector: {
        matchLabels: $._config.commonLabels {
          'app.kubernetes.io/component': 'blobserve',
        },
      },
      namespaceSelector: {
        matchNames: [
          $._config.gitpodNamespace,
        ],
      },
      endpoints: [{
        bearerTokenFile: '/var/run/secrets/kubernetes.io/serviceaccount/token',
        port: 'metrics',
        interval: '30s',
      }],
    },
  },

  blobserveNetworkPolicy: {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'NetworkPolicy',
    metadata: {
      name: 'blobserve-allow-kube-prometheus',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels,
    },
    spec: {
      podSelector: {
        matchLabels: {
          component: 'blobserve',
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

  containerdMetricsService: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: $._config.name + '-containerd-metrics',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels {
        'app.kubernetes.io/component': 'containerd-metrics',
      },
    },
    spec: {
      selector: {
        component: 'containerd-metrics',
      },
      ports: [{
        name: 'metrics',
        port: 9500,
      }],
    },
  },

  containerdMetricsServiceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: $._config.name + '-containerd-metrics',
      namespace: $._config.namespace,
      labels: $._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/component',
      selector: {
        matchLabels: $._config.commonLabels {
          'app.kubernetes.io/component': 'containerd-metrics',
        },
      },
      namespaceSelector: {
        matchNames: [
          $._config.gitpodNamespace,
        ],
      },
      endpoints: [{
        port: 'metrics',
        interval: '30s',
      }],
    },
  },

  containerdMetricsNetworkPolicy: {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'NetworkPolicy',
    metadata: {
      name: 'containerd-metrics-allow-kube-prometheus',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels,
    },
    spec: {
      podSelector: {
        matchLabels: {
          component: 'containerd-metrics',
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

  contentServiceService: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: $._config.name + '-content-service',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels {
        'app.kubernetes.io/component': 'content-service',
      },
    },
    spec: {
      selector: {
        component: 'content-service',
      },
      ports: [{
        name: 'metrics',
        port: 9500,
      }],
    },
  },

  contentServiceServiceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: $._config.name + '-content-service',
      namespace: $._config.namespace,
      labels: $._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/component',
      selector: {
        matchLabels: $._config.commonLabels {
          'app.kubernetes.io/component': 'content-service',
        },
      },
      namespaceSelector: {
        matchNames: [
          $._config.gitpodNamespace,
        ],
      },
      endpoints: [{
        port: 'metrics',
        interval: '30s',
      }],
    },
  },

  contentServiceNetworkPolicy: {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'NetworkPolicy',
    metadata: {
      name: 'content-service-allow-kube-prometheus',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels,
    },
    spec: {
      podSelector: {
        matchLabels: {
          component: 'content-service',
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

  // Not necessary as credit-watcher doesn't expose metrics
  creditWatcherService:: {},
  creditWatcherServiceMonitor:: {},
  creditWatcherNetworkPolicy:: {},

  // Not necessary as dashboard doesn't expose metrics
  dashboardService:: {},
  dashboardServiceMonitor:: {},
  dashboardNetworkPolicy:: {},

  // Not necessary as db doesn't expose metrics
  dbService:: {},
  dbServiceMonitor:: {},
  dbNetworkPolicy:: {},

  // Not necessary as db-sync doesn't expose metrics
  dbSyncService:: {},
  dbSyncServiceMonitor:: {},
  dbSyncNetworkPolicy:: {},

  imageBuilderService: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: $._config.name + '-image-builder',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels {
        'app.kubernetes.io/component': 'image-builder-mk3',
      },
    },
    spec: {
      selector: {
        component: 'image-builder-mk3',
      },
      ports: [{
        name: 'metrics',
        port: 9500,
      }],
    },
  },

  imageBuilderServiceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: $._config.name + '-image-builder',
      namespace: $._config.namespace,
      labels: $._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/component',
      selector: {
        matchLabels: $._config.commonLabels {
          'app.kubernetes.io/component': 'image-builder-mk3',
        },
      },
      namespaceSelector: {
        matchNames: [
          $._config.gitpodNamespace,
        ],
      },
      endpoints: [{
        bearerTokenFile: '/var/run/secrets/kubernetes.io/serviceaccount/token',
        port: 'metrics',
        interval: '30s',
      }],
    },
  },

  imageBuilderNetworkPolicy: {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'NetworkPolicy',
    metadata: {
      name: 'image-builder-allow-kube-prometheus',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels,
    },
    spec: {
      podSelector: {
        matchLabels: {
          component: 'image-builder-mk3',
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

  messagebusService: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: $._config.name + '-messagebus',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels {
        'app.kubernetes.io/component': 'messagebus',
      },
    },
    spec: {
      selector: {
        'app.kubernetes.io/name': 'rabbitmq',
      },
      ports: [{
        name: 'metrics',
        port: 9419,
      }],
    },
  },

  messagebusServiceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: $._config.name + '-messagebus',
      namespace: $._config.namespace,
      labels: $._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/component',
      selector: {
        matchLabels: $._config.commonLabels {
          'app.kubernetes.io/component': 'messagebus',
        },
      },
      namespaceSelector: {
        matchNames: [
          $._config.gitpodNamespace,
        ],
      },
      endpoints: [{
        port: 'metrics',
        interval: '30s',
      }],
    },
  },

  messagebusNetworkPolicy: {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'NetworkPolicy',
    metadata: {
      name: 'messagebus-allow-kube-prometheus',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels,
    },
    spec: {
      podSelector: {
        matchLabels: {
          component: 'messagebus',
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

  openVSXProxyService: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: $._config.name + '-openvsx-proxy',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels {
        'app.kubernetes.io/component': 'openvsx-proxy',
      },
    },
    spec: {
      selector: {
        component: 'openvsx-proxy',
      },
      ports: [{
        name: 'metrics',
        port: 9500,
      }],
    },
  },

  openVSXProxyServiceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: $._config.name + '-openvsx-proxy',
      namespace: $._config.namespace,
      labels: $._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/component',
      selector: {
        matchLabels: $._config.commonLabels {
          'app.kubernetes.io/component': 'openvsx-proxy',
        },
      },
      namespaceSelector: {
        matchNames: [
          $._config.gitpodNamespace,
        ],
      },
      endpoints: [{
        port: 'metrics',
        interval: '30s',
      }],
    },
  },

  openVSXProxyNetworkPolicy: {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'NetworkPolicy',
    metadata: {
      name: 'openvsx-proxy-allow-kube-prometheus',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels,
    },
    spec: {
      podSelector: {
        matchLabels: {
          component: 'openvsx-proxy',
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

  // Not necessary as proxy doesn't expose metrics
  // Do not confuse with caddy, which runs inside the proxy component.
  proxyService:: {},
  proxyServiceMonitor:: {},
  proxyNetworkPolicy:: {},

  proxyCaddyService: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: $._config.name + '-proxy-caddy',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels {
        'app.kubernetes.io/component': 'proxy-caddy',
      },
    },
    spec: {
      selector: {
        component: 'proxy',
      },
      ports: [{
        name: 'caddy-metrics',
        port: 8003,
      }],
    },
  },

  proxyCaddyServiceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: $._config.name + '-proxy-caddy',
      namespace: $._config.namespace,
      labels: $._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/component',
      selector: {
        matchLabels: $._config.commonLabels {
          'app.kubernetes.io/component': 'proxy-caddy',
        },
      },
      namespaceSelector: {
        matchNames: [
          $._config.gitpodNamespace,
        ],
      },
      endpoints: [{
        bearerTokenFile: '/var/run/secrets/kubernetes.io/serviceaccount/token',
        port: 'metrics',
        interval: '30s',
      }],
    },
  },

  proxyCaddyNetworkPolicy: {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'NetworkPolicy',
    metadata: {
      name: 'proxy-caddy-allow-kube-prometheus',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels,
    },
    spec: {
      podSelector: {
        matchLabels: {
          component: 'proxy',
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

  publicAPIService: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: $._config.name + '-public-api-server',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels {
        'app.kubernetes.io/component': 'public-api-server',
      },
    },
    spec: {
      selector: {
        component: 'public-api-server',
      },
      ports: [{
        name: 'metrics',
        port: 9500,
      }],
    },
  },

  publicAPIServiceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: $._config.name + '-public-api-server',
      namespace: $._config.namespace,
      labels: $._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/component',
      selector: {
        matchLabels: $._config.commonLabels {
          'app.kubernetes.io/component': 'public-api-server',
        },
      },
      namespaceSelector: {
        matchNames: [
          $._config.gitpodNamespace,
        ],
      },
      endpoints: [{
        bearerTokenFile: '/var/run/secrets/kubernetes.io/serviceaccount/token',
        port: 'metrics',
        interval: '30s',
      }],
    },
  },

  publicAPINetworkPolicy: {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'NetworkPolicy',
    metadata: {
      name: 'public-api-server-allow-kube-prometheus',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels,
    },
    spec: {
      podSelector: {
        matchLabels: {
          component: 'public-api-server',
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

  usageService: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: $._config.name + '-usage',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels {
        'app.kubernetes.io/component': 'usage',
      },
    },
    spec: {
      selector: {
        component: 'usage',
      },
      ports: [{
        name: 'metrics',
        port: 9500,
      }],
    },
  },

  usageServiceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: $._config.name + '-usage',
      namespace: $._config.namespace,
      labels: $._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/component',
      selector: {
        matchLabels: $._config.commonLabels {
          'app.kubernetes.io/component': 'usage',
        },
      },
      namespaceSelector: {
        matchNames: [
          $._config.gitpodNamespace,
        ],
      },
      endpoints: [{
        bearerTokenFile: '/var/run/secrets/kubernetes.io/serviceaccount/token',
        port: 'metrics',
        interval: '30s',
      }],
    },
  },

  usageNetworkPolicy: {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'NetworkPolicy',
    metadata: {
      name: 'usage-allow-kube-prometheus',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels,
    },
    spec: {
      podSelector: {
        matchLabels: {
          component: 'usage',
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

  registryFacadeService: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: $._config.name + '-registry-facade',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels {
        'app.kubernetes.io/component': 'registry-facade',
      },
    },
    spec: {
      selector: {
        component: 'registry-facade',
      },
      ports: [{
        name: 'metrics',
        port: 9500,
      }],
    },
  },

  registryFacadeServiceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: $._config.name + '-registry-facade',
      namespace: $._config.namespace,
      labels: $._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/component',
      selector: {
        matchLabels: $._config.commonLabels {
          'app.kubernetes.io/component': 'registry-facade',
        },
      },
      namespaceSelector: {
        matchNames: [
          $._config.gitpodNamespace,
        ],
      },
      endpoints: [{
        bearerTokenFile: '/var/run/secrets/kubernetes.io/serviceaccount/token',
        port: 'metrics',
        interval: '30s',
      }],
    },
  },

  registryFacadeNetworkPolicy: {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'NetworkPolicy',
    metadata: {
      name: 'registry-facade-allow-kube-prometheus',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels,
    },
    spec: {
      podSelector: {
        matchLabels: {
          component: 'registry-facade',
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

  serverService: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: $._config.name + '-server',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels {
        'app.kubernetes.io/component': 'server',
      },
    },
    spec: {
      selector: {
        component: 'server',
      },
      ports: [{
        name: 'metrics',
        port: 9500,
      }],
    },
  },

  serverServiceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: $._config.name + '-server',
      namespace: $._config.namespace,
      labels: $._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/component',
      selector: {
        matchLabels: $._config.commonLabels {
          'app.kubernetes.io/component': 'server',
        },
      },
      namespaceSelector: {
        matchNames: [
          $._config.gitpodNamespace,
        ],
      },
      endpoints: [{
        bearerTokenFile: '/var/run/secrets/kubernetes.io/serviceaccount/token',
        port: 'metrics',
        interval: '1m',
        scrapeTimeout: '50s',
      }],
    },
  },

  serverNetworkPolicy: {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'NetworkPolicy',
    metadata: {
      name: 'server-allow-kube-prometheus',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels,
    },
    spec: {
      podSelector: {
        matchLabels: {
          component: 'server',
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

  workspacePodMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'PodMonitor',
    metadata: {
      name: 'workspace',
      namespace: $._config.namespace,
      labels: $._config.commonLabels,
    },
    spec: {
      selector: {
        matchLabels: {
          component: 'workspace',
          workspaceType: 'regular',
        },
      },
      namespaceSelector: {
        matchNames: [
          $._config.gitpodNamespace,
        ],
      },
      podMetricsEndpoints: [{
        port: 'supervisor',
        interval: '60s',
        scrapeTimeout: '5s',
        metricRelabelings: [{
          sourceLabels: ['__name__'],
          regex: 'gitpod_(.*)',
          action: 'keep',
        }],
      }],
    },
  },

  workspaceNetworkPolicy: {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'NetworkPolicy',
    metadata: {
      name: 'workspace-allow-kube-prometheus',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels,
    },
    spec: {
      podSelector: {
        matchLabels: {
          component: 'workspace',
        },
      },
      policyTypes: ['Ingress'],
      ingress: [{
        ports: [{
          protocol: 'TCP',
          port: 22999,
        }],
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

  wsDaemonService: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: $._config.name + '-ws-daemon',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels {
        'app.kubernetes.io/component': 'ws-daemon',
      },
    },
    spec: {
      selector: {
        component: 'ws-daemon',
      },
      ports: [{
        name: 'metrics',
        port: 9500,
      }],
    },
  },

  wsDaemonServiceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: $._config.name + '-ws-daemon',
      namespace: $._config.namespace,
      labels: $._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/component',
      selector: {
        matchLabels: $._config.commonLabels {
          'app.kubernetes.io/component': 'ws-daemon',
        },
      },
      namespaceSelector: {
        matchNames: [
          $._config.gitpodNamespace,
        ],
      },
      endpoints: [{
        bearerTokenFile: '/var/run/secrets/kubernetes.io/serviceaccount/token',
        port: 'metrics',
        interval: '30s',
      }],
    },
  },

  wsDaemonNetworkPolicy: {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'NetworkPolicy',
    metadata: {
      name: 'ws-daemon-allow-kube-prometheus',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels,
    },
    spec: {
      podSelector: {
        matchLabels: {
          component: 'ws-daemon',
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

  wsManagerService: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: $._config.name + '-ws-manager',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels {
        'app.kubernetes.io/component': 'ws-manager',
      },
    },
    spec: {
      selector: {
        component: 'ws-manager',
      },
      ports: [{
        name: 'metrics',
        port: 9500,
      }],
    },
  },

  wsManagerServiceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: $._config.name + '-ws-manager',
      namespace: $._config.namespace,
      labels: $._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/component',
      selector: {
        matchLabels: $._config.commonLabels {
          'app.kubernetes.io/component': 'ws-manager',
        },
      },
      namespaceSelector: {
        matchNames: [
          $._config.gitpodNamespace,
        ],
      },
      endpoints: [{
        bearerTokenFile: '/var/run/secrets/kubernetes.io/serviceaccount/token',
        port: 'metrics',
        interval: '30s',
      }],
    },
  },

  wsManagerNetworkPolicy: {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'NetworkPolicy',
    metadata: {
      name: 'ws-manager-allow-kube-prometheus',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels,
    },
    spec: {
      podSelector: {
        matchLabels: {
          component: 'ws-manager',
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

  wsManagerBridgeService: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: $._config.name + '-ws-manager-bridge',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels {
        'app.kubernetes.io/component': 'ws-manager-bridge',
      },
    },
    spec: {
      selector: {
        component: 'ws-manager-bridge',
      },
      ports: [{
        name: 'metrics',
        port: 9500,
      }],
    },
  },

  wsManagerBridgeServiceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: $._config.name + '-ws-manager-bridge',
      namespace: $._config.namespace,
      labels: $._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/component',
      selector: {
        matchLabels: $._config.commonLabels {
          'app.kubernetes.io/component': 'ws-manager-bridge',
        },
      },
      namespaceSelector: {
        matchNames: [
          $._config.gitpodNamespace,
        ],
      },
      endpoints: [{
        bearerTokenFile: '/var/run/secrets/kubernetes.io/serviceaccount/token',
        port: 'metrics',
        interval: '30s',
      }],
    },
  },

  wsManagerBridgeNetworkPolicy: {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'NetworkPolicy',
    metadata: {
      name: 'ws-manager-bridge-allow-kube-prometheus',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels,
    },
    spec: {
      podSelector: {
        matchLabels: {
          component: 'ws-manager-bridge',
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

  wsProxyService: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: $._config.name + '-ws-proxy',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels {
        'app.kubernetes.io/component': 'ws-proxy',
      },
    },
    spec: {
      selector: {
        component: 'ws-proxy',
      },
      ports: [{
        name: 'metrics',
        port: 9500,
      }],
    },
  },
  wsProxyServiceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: $._config.name + '-ws-proxy',
      namespace: $._config.namespace,
      labels: $._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/component',
      selector: {
        matchLabels: $._config.commonLabels {
          'app.kubernetes.io/component': 'ws-proxy',
        },
      },
      namespaceSelector: {
        matchNames: [
          $._config.gitpodNamespace,
        ],
      },
      endpoints: [{
        bearerTokenFile: '/var/run/secrets/kubernetes.io/serviceaccount/token',
        port: 'metrics',
        interval: '30s',
        metricRelabelings: [{
          sourceLabels: ['__name__'],
          regex: 'gitpod_(.*)',
          action: 'keep',
        }],
      }],
    },
  },
  wsProxyNetworkPolicy: {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'NetworkPolicy',
    metadata: {
      name: 'ws-proxy-allow-kube-prometheus',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels,
    },
    spec: {
      podSelector: {
        matchLabels: {
          component: 'ws-proxy',
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

  wsSchedulerService: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: $._config.name + '-ws-scheduler',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels {
        'app.kubernetes.io/component': 'ws-scheduler',
      },
    },
    spec: {
      selector: {
        component: 'ws-scheduler',
      },
      ports: [{
        name: 'metrics',
        port: 9500,
      }],
    },
  },

  wsSchedulerServiceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: $._config.name + '-ws-scheduler',
      namespace: $._config.namespace,
      labels: $._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/component',
      selector: {
        matchLabels: $._config.commonLabels {
          'app.kubernetes.io/component': 'ws-scheduler',
        },
      },
      namespaceSelector: {
        matchNames: [
          $._config.gitpodNamespace,
        ],
      },
      endpoints: [{
        bearerTokenFile: '/var/run/secrets/kubernetes.io/serviceaccount/token',
        port: 'metrics',
        interval: '30s',
      }],
    },
  },

  wsSchedulerNetworkPolicy: {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'NetworkPolicy',
    metadata: {
      name: 'ws-scheduler-allow-kube-prometheus',
      namespace: $._config.gitpodNamespace,
      labels: $._config.commonLabels,
    },
    spec: {
      podSelector: {
        matchLabels: {
          component: 'ws-scheduler',
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
