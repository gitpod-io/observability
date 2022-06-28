function(config) {
  assert std.objectHas(config, 'grafana') : 'grafana required',
  assert std.objectHas(config.grafana, 'DNS') : 'grafana.DNS required',
  assert std.objectHas(config.grafana, 'nodePort') : 'grafana.nodePort required',
  assert std.isNumber(config.grafana.nodePort) : 'grafana.nodePort should be a number',
  assert std.objectHas(config.grafana, 'GCPExternalIpAddress') : 'grafana.GCPExternalIpAddress required',
  assert std.objectHas(config.grafana, 'IAPClientID') : 'grafana.IAPClientID required',
  assert std.objectHas(config.grafana, 'IAPClientSecret') : 'grafana.IAPClientSecret required',

  grafana+: {
    // Certmanager must be installed in the cluster already!
    certificate: {
      apiVersion: 'cert-manager.io/v1',
      kind: 'Certificate',
      metadata: {
        name: 'grafana',
        namespace: config.namespace,
      },
      spec: {
        dnsNames: [
          config.grafana.DNS,
        ],
        issuerRef: {
          kind: 'ClusterIssuer',
          name: 'letsencrypt-issuer',
        },
        secretName: 'grafana-certificate',
      },
    },

    service+: {
      metadata+: {
        annotations+: {
          'cloud.google.com/backend-config': '{"ports": {"3000":"' + $.grafana.backendOAuth.metadata.name + '"}}',  // same name as backend-config
        },
      },
      spec+: {
        type: 'NodePort',
        ports: std.map(
          function(p) p {
            nodePort: config.grafana.nodePort,
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
          'kubernetes.io/ingress.global-static-ip-name': config.grafana.GCPExternalIpAddress,
          'kubernetes.io/ingress.class': 'gce',
          'cert-manager.io/cluster-issuer': $.grafana.certificate.spec.issuerRef.name,
          'networking.gke.io/v1beta1.FrontendConfig': $.grafana.frontendConfig.metadata.name,
        },
        labels: $.grafana.service.metadata.labels,
        name: 'grafana',
        namespace: config.namespace,
      },
      spec: {
        rules: [{
          host: config.grafana.DNS,  // gcp's external ip address
          http: {
            paths: [{
              backend: {
                serviceName: $.grafana.service.metadata.name,  // same name put on service resource
                servicePort: 3000,
              },
              path: '/*',
            }],
          },

        }],
        tls: [{
          hosts: [
            config.grafana.DNS,
          ],
          secretName: $.grafana.certificate.spec.secretName,
        }],
      },
    },

    backendOAuthSecret: {
      apiVersion: 'v1',
      kind: 'Secret',
      metadata: {
        name: 'grafana-oauth',
        namespace: config.namespace,
        labels: $.grafana.service.metadata.labels,
      },
      data: {
        client_id: std.base64(config.grafana.IAPClientID),
        client_secret: std.base64(config.grafana.IAPClientSecret),
      },
    },

    backendOAuth: {
      apiVersion: 'cloud.google.com/v1',
      kind: 'BackendConfig',
      metadata: {
        name: 'grafana',
        namespace: config.namespace,
      },
      spec: {
        iap: {
          enabled: true,
          oauthclientCredentials: {
            secretName: $.grafana.backendOAuthSecret.metadata.name,
          },
        },
      },
    },

    frontendConfig: {
      apiVersion: 'networking.gke.io/v1beta1',
      kind: 'FrontendConfig',
      metadata: {
        name: 'grafana',
        namespace: config.namespace,
      },
      spec: {
        sslPolicy: 'grafana-ssl-policy',
        redirectToHttps: {
          enabled: true,
          responseCodeName: '301',
        },
      },
    },
  },
}
