function(config) {
  assert std.objectHas(config, 'prometheus') : 'prometheus required',
  assert std.objectHas(config.prometheus, 'DNS') : 'prometheus.DNS required',
  assert std.objectHas(config.prometheus, 'nodePort') : 'prometheus.nodePort required',
  assert std.isNumber(config.prometheus.nodePort) : 'prometheus.nodePort should be a number',
  assert std.objectHas(config.prometheus, 'GCPExternalIpAddress') : 'prometheus.GCPExternalIpAddress required',
  assert std.objectHas(config.prometheus, 'BasicAuthSecret') : 'prometheus.BasicAuthSecret required',


  prometheus+: {
    certificate: {
      apiVersion: 'cert-manager.io/v1',
      kind: 'Certificate',
      metadata: {
        name: 'prometheus-remote-write',
        namespace: config.namespace,
      },
      spec: {
        dnsNames: [
          config.prometheus.DNS,
        ],
        issuerRef: {
          kind: 'ClusterIssuer',
          name: 'letsencrypt-issuer-gitpod-core-dev',
        },
        secretName: 'prometheus-remote-write-certificate',
      },
    },

    secret: {
      apiVersion: 'v1',
      kind: 'Secret',
      metadata: {
        name: 'prometheus-remote-write-basic-auth',
        namespace: config.namespace,
        labels: $.prometheus.service.metadata.labels,
      },
      spec: {
        auth: std.base64(config.prometheus.BasicAuthSecret),
      },
    },

    service+: {
      spec+: {
        type: 'NodePort',
        ports: std.map(
          function(p) p {
            nodePort: config.prometheus.nodePort,
          }
          , super.ports
        ),
      },
    },

    ingress: {
      apiVersion: 'extensions/v1beta1',
      kind: 'Ingress',
      metadata: {
        annotations: {
          'kubernetes.io/ingress.global-static-ip-name': config.prometheus.GCPExternalIpAddress,
          'kubernetes.io/ingress.class': 'nginx',
          'cert-manager.io/cluster-issuer': $.prometheus.certificate.spec.issuerRef.name,
          'nginx.ingress.kubernetes.io/auth-type': 'basic',
          'nginx.ingress.kubernetes.io/auth-secret': $.prometheus.secret.metadata.name,
        },
        labels: $.prometheus.service.metadata.labels,
        name: 'prometheus-remote-write',
        namespace: config.namespace,
      },
      spec: {
        rules: [{
          host: config.prometheus.DNS,
          http: {
            paths: [{
              backend: {
                serviceName: $.prometheus.service.metadata.name,
                servicePort: 9090,
              },
              path: '/api/v1/write',
            }],
          },

        }],
        tls: [{
          hosts: [
            config.prometheus.DNS,
          ],
          secretName: $.prometheus.certificate.spec.secretName,
        }],
      },
    },
  },
}
