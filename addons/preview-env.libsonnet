// The preview-environment addon provides json snippets that are specific for preview environment installations.
function(config) {

  assert std.objectHas(config.previewEnvironment, 'prometheusDNS') && std.objectHas(config.previewEnvironment, 'grafanaDNS') : (
    "If 'previewEnvironment' is set, 'prometheusDNS' and 'grafanaDNS' should be declared"
  ),

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

    certificate: {
      apiVersion: 'cert-manager.io/v1',
      kind: 'Certificate',
      metadata: {
        name: 'prometheus',
        namespace: config.namespace,
      },
      spec: {
        dnsNames: [
          config.previewEnvironment.prometheusDNS,
        ],
        issuerRef: {
          kind: 'ClusterIssuer',
          name: 'letsencrypt-issuer-core-dev',
        },
        secretName: 'prometheus-certificate',
      },
    },

    ingress: {
      apiVersion: 'extensions/v1beta1',
      kind: 'Ingress',
      metadata: {
        annotations: {
          'kubernetes.io/ingress.class': 'gce',
          'cert-manager.io/cluster-issuer': $.prometheus.certificate.spec.issuerRef.name,
          'external-dns.alpha.kubernetes.io/hostname': config.previewEnvironment.prometheusDNS,
        },
        labels: $.prometheus.service.metadata.labels,
        name: 'prometheus',
        namespace: config.namespace,
      },
      spec: {
        rules: [{
          host: config.previewEnvironment.prometheusDNS,
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
            config.previewEnvironment.prometheusDNS,
          ],
          secretName: $.prometheus.certificate.spec.secretName,
        }],
      },
    },

    backendConfig: {
      apiVersion: 'cloud.google.com/v1',
      kind: 'BackendConfig',
      metadata: {
        name: 'prometheus',
        namespace: config.namespace,
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

    certificate: {
      apiVersion: 'cert-manager.io/v1',
      kind: 'Certificate',
      metadata: {
        name: 'grafana',
        namespace: config.namespace,
      },
      spec: {
        dnsNames: [
          config.previewEnvironment.grafanaDNS,
        ],
        issuerRef: {
          kind: 'ClusterIssuer',
          name: 'letsencrypt-issuer-core-dev',
        },
        secretName: 'grafana-certificate',
      },
    },

    ingress: {
      apiVersion: 'extensions/v1beta1',
      kind: 'Ingress',
      metadata: {
        annotations: {
          'kubernetes.io/ingress.class': 'gce',
          'cert-manager.io/cluster-issuer': $.grafana.certificate.spec.issuerRef.name,
          'external-dns.alpha.kubernetes.io/hostname': config.previewEnvironment.grafanaDNS,
        },
        labels: $.grafana.service.metadata.labels,
        name: 'grafana',
        namespace: config.namespace,
      },
      spec: {
        rules: [{
          host: config.previewEnvironment.grafanaDNS,
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
            config.previewEnvironment.grafanaDNS,
          ],
          secretName: $.grafana.certificate.spec.secretName,
        }],
      },
    },

  },
}
