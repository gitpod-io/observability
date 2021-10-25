// The preview-environment addon provides json snippets that are specific for preview environment installations.
local otelCollector = import '../components/open-telemetry-collector/open-telemetry-collector.libsonnet';

{
  values+:: {
    // On preview env, Gitpod and monitoring satellite are installed in the same namespace.
    gitpodParams+: {
      gitpodNamespace: std.extVar('namespace'),
    },

    otelCollectorParams: {
      namespace: std.extVar('namespace'),
    },

    nodeExporter+: {
      port: std.parseInt(std.extVar('node_exporter_port')),
    },
  },

  otelCollector: otelCollector($.values.otelCollectorParams),

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

    certificate: {
      apiVersion: 'cert-manager.io/v1',
      kind: 'Certificate',
      metadata: {
        name: 'prometheus',
        namespace: std.extVar('namespace'),
      },
      spec: {
        dnsNames: [
          std.extVar('prometheus_dns_name'),
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
          'external-dns.alpha.kubernetes.io/hostname': std.extVar('prometheus_dns_name'),
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
          secretName: $.prometheus.certificate.spec.secretName,
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

    certificate: {
      apiVersion: 'cert-manager.io/v1',
      kind: 'Certificate',
      metadata: {
        name: 'grafana',
        namespace: std.extVar('namespace'),
      },
      spec: {
        dnsNames: [
          std.extVar('grafana_dns_name'),
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
          'external-dns.alpha.kubernetes.io/hostname': std.extVar('grafana_dns_name'),
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
          secretName: $.grafana.certificate.spec.secretName,
        }],
      },
    },

  },
}
