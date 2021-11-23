local defaults = {
  defaults: self,

  name: 'otel-collector',
  namespace: error 'must provide namespace',
  version: '0.38.0',
  commonLabels: {
    'app.kubernetes.io/name': defaults.name,
    'app.kubernetes.io/part-of': 'kube-prometheus',
  },
};

function(params) {
  local otel = self,
  _config:: defaults + params,

  local receiversConfig =
    |||
      receivers:
        jaeger:
          protocols:
            thrift_http:
              endpoint: "0.0.0.0:14268"
        otlp:
          protocols:
            grpc: # on port 4317
            http: # on port 4318
    |||,

  local processorsConfig =
    |||
      processors:
    |||,

  local exportersConfig =
    |||
      exporters:
        otlp:
          endpoint: "api.honeycomb.io:443"
          headers:
            "x-honeycomb-team": "%(honeycomb_api_key)s"
            "x-honeycomb-dataset": "%(honeycomb_dataset)s"
    ||| % {
      honeycomb_api_key: std.extVar('honeycomb_api_key'),
      honeycomb_dataset: std.extVar('honeycomb_dataset'),
    },

  local extensionsConfig =
    |||
      extensions:
        health_check:
        pprof:
        zpages:
    |||,

  local serviceConfig =
    |||
      service:
        telemetry:
          logs:
            level: "debug"
        extensions: [health_check, pprof,  zpages]
        pipelines:
          traces:
            receivers: [jaeger, otlp]
            processors: []
            exporters: [otlp]
    |||,

  configMap: {
    apiVersion: 'v1',
    kind: 'ConfigMap',
    metadata: {
      name: otel._config.name,
      namespace: otel._config.namespace,
      labels: otel._config.commonLabels,
    },
    data: {
      'collector.yaml':
        receiversConfig +
        processorsConfig +
        exportersConfig +
        extensionsConfig +
        serviceConfig,
    },
  },

  deployment: {
    apiVersion: 'apps/v1',
    kind: 'Deployment',
    metadata: {
      name: otel._config.name,
      namespace: otel._config.namespace,
      labels: otel._config.commonLabels,
    },
    spec: {
      replicas: 1,
      selector: {
        matchLabels: otel._config.commonLabels,
      },
      template: {
        metadata: {
          labels: otel._config.commonLabels,
        },
        spec: {
          serviceAccountName: otel.serviceAccount.metadata.name,
          containers: [
            {
              name: 'otelcol',
              args: [
                '--config=/conf/collector.yaml',
              ],
              image: 'otel/opentelemetry-collector:' + otel._config.version,
              volumeMounts: [
                {
                  mountPath: '/conf',
                  name: otel.configMap.metadata.name,
                },
              ],
            },
          ],
          volumes: [
            {
              name: otel.configMap.metadata.name,
              configMap: {
                items: [
                  {
                    key: 'collector.yaml',
                    path: 'collector.yaml',
                  },
                ],
                name: otel.configMap.metadata.name,
              },
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
      name: otel._config.name,
      namespace: otel._config.namespace,
      labels: otel._config.commonLabels,
    },
    spec: {
      ports: [
        {
          name: 'jaeger',
          port: 14268,
          protocol: 'TCP',
          targetPort: 14268,
        },
        {
          name: 'grpc-otlp',
          port: 4317,
          protocol: 'TCP',
          targetPort: 4317,
        },
        {
          name: 'metrics',
          port: 8888,
          protocol: 'TCP',
          targetPort: 8888,
        },
      ],
      selector: otel._config.commonLabels,
      type: 'ClusterIP',
    },
  },

  clusterRole: {
    apiVersion: 'rbac.authorization.k8s.io/v1beta1',
    kind: 'ClusterRole',
    metadata: {
      name: otel._config.name,
      labels: otel._config.commonLabels,
    },
    rules: [{
      apiGroups: ['policy'],
      resources: ['podsecuritypolicies'],
      verbs: ['use'],
      resourceNames: [otel.podSecurityPolicy.metadata.name],
    }],
  },

  clusterRoleBinding: {
    apiVersion: 'rbac.authorization.k8s.io/v1beta1',
    kind: 'ClusterRoleBinding',
    metadata: {
      name: otel._config.name,
      labels: otel._config.commonLabels,
    },
    subjects: [{
      kind: 'ServiceAccount',
      name: otel.serviceAccount.metadata.name,
      namespace: otel._config.namespace,
    }],
    roleRef: {
      apiGroup: 'rbac.authorization.k8s.io',
      kind: 'ClusterRole',
      name: otel.clusterRole.metadata.name,
    },
  },

  podSecurityPolicy: {
    apiVersion: 'policy/v1beta1',
    kind: 'PodSecurityPolicy',
    metadata: {
      name: otel._config.name,
      labels: otel._config.commonLabels,
    },
    spec: {
      privileged: false,
      seLinux: {
        rule: 'RunAsAny',
      },
      supplementalGroups: {
        rule: 'RunAsAny',
      },
      runAsUser: {
        rule: 'RunAsAny',
      },
      fsGroup: {
        rule: 'RunAsAny',
      },
      volumes: ['*'],
    },
  },

  serviceAccount: {
    apiVersion: 'v1',
    kind: 'ServiceAccount',
    metadata: {
      name: otel._config.name,
      namespace: otel._config.namespace,
      labels: otel._config.commonLabels,
    },
  },

  serviceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: {
      name: otel._config.name,
      namespace: otel._config.namespace,
      labels: otel._config.commonLabels,
    },
    spec: {
      jobLabel: 'app.kubernetes.io/name',
      selector: {
        matchLabels: otel._config.commonLabels,
      },
      namespaceSelector: {
        matchNames: [
          otel._config.namespace,
        ],
      },
      endpoints: [{
        bearerTokenFile: '/var/run/secrets/kubernetes.io/serviceaccount/token',
        port: 'metrics',
        interval: '30s',
      }],
    },
  },
}
