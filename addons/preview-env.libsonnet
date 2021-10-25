// The preview-environment addon provides json snippets that are specific for preview environment installations.
{
  values+:: {
    // On preview env, Gitpod and monitoring satellite are installed in the same namespace.
    gitpodParams+: {
      gitpodNamespace: std.extVar('namespace'),
    },

    nodeExporter+: {
      port: std.parseInt(std.extVar('node_exporter_port')),
    },
  },

  prometheus+: {
    prometheus+: {
      spec+: {
        serviceMonitorNamespaceSelector: {
          matchLabels: {
            // Each Prometheus should only monitor its own preview environment.
            namespace: std.extVar('namespace'),
          },
        },
        ruleNamespaceSelector: {
          matchLabels: {
            // Each Prometheus should only monitor its own preview environment.
            namespace: std.extVar('namespace'),
          },
        },
      },
    },

    service+: {
      metadata+: {
        annotations+: {
          'cloud.google.com/backend-config': '{"ports": {"9090":"' + $.prometheus.backendConfig.metadata.name + '"}}',  // same name as backend-config
        },
      },
      spec+: {
        type: 'LoadBalancer',
      },
    },

    ingress: {
      apiVersion: 'extensions/v1beta1',
      kind: 'Ingress',
      metadata: {
        annotations: {
          'kubernetes.io/ingress.class': 'gce',
        },
        labels: $.prometheus.service.metadata.labels,
        name: 'prometheus',
        namespace: std.extVar('namespace'),
      },
      spec: {
        rules: [{
          host: std.extVar('prometheus_dns_name'),
          http: {
            paths: [{
              backend: {
                serviceName: $.prometheus.service.metadata.name,
                servicePort: 9090,
              },
              path: '/*',
            }],
          },

        }],
        tls: [{
          hosts: [
            std.extVar('prometheus_dns_name'),
          ],
          secretName: 'proxy-config-certificates',
        }],
      },
    },

    backendConfig: {
      apiVersion: 'cloud.google.com/v1',
      kind: 'BackendConfig',
      metadata: {
        name: 'prometheus',
        namespace: std.extVar('namespace'),
      },
      spec: {
        healthCheck: {
          requestPath: '/-/ready',
        },
      },
    },
  },

  grafana+: {
    service+: {
      spec+: {
        type: 'LoadBalancer',
      },
    },

    ingress: {
      apiVersion: 'extensions/v1beta1',
      kind: 'Ingress',
      metadata: {
        annotations: {
          'kubernetes.io/ingress.class': 'gce',
        },
        labels: $.grafana.service.metadata.labels,
        name: 'grafana',
        namespace: std.extVar('namespace'),
      },
      spec: {
        rules: [{
          host: std.extVar('grafana_dns_name'),
          http: {
            paths: [{
              backend: {
                serviceName: $.grafana.service.metadata.name,
                servicePort: 3000,
              },
              path: '/*',
            }],
          },

        }],
        tls: [{
          hosts: [
            std.extVar('grafana_dns_name'),
          ],
          secretName: 'proxy-config-certificates',
        }],
      },
    },

  },
}
