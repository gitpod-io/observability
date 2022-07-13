function(config) {
  assert std.objectHas(config.pyrra, 'DNS') : 'pyrra.DNS required',
  assert std.objectHas(config.pyrra, 'nodePort') : 'pyrra.nodePort required',
  assert std.isNumber(config.pyrra.nodePort) : 'pyrra.nodePort should be a number',
  assert std.objectHas(config.pyrra, 'GCPExternalIpAddress') : 'pyrra.GCPExternalIpAddress required',
  assert std.objectHas(config.grafana, 'IAPClientID') : 'grafana.IAPClientID required',
  assert std.objectHas(config.grafana, 'IAPClientSecret') : 'grafana.IAPClientSecret required',


  pyrra+: {
    certificate: {
      apiVersion: 'cert-manager.io/v1',
      kind: 'Certificate',
      metadata: {
        name: 'pyrra',
        namespace: config.namespace,
      },
      spec: {
        dnsNames: [
          config.pyrra.DNS,
        ],
        issuerRef: {
          kind: 'ClusterIssuer',
          name: 'letsencrypt-issuer-gitpod-191109',
        },
        secretName: 'pyrra',
      },
    },

    apiService+: {
      metadata+: {
        annotations+: {
          'cloud.google.com/backend-config': '{"ports": {"9099":"' + $.pyrra.backendOAuth.metadata.name + '"}}',  // same name as backend-config
        },
      },
      spec+: {
        type: 'NodePort',
        ports: std.map(
          function(p)
            if p.name == 'http' then
              p {
                nodePort: config.pyrra.nodePort,
              }
            else p
          , super.ports
        ),
      },
    },

    ingress: {
      apiVersion: 'extensions/v1beta1',
      kind: 'Ingress',
      metadata: {
        annotations: {
          'kubernetes.io/ingress.global-static-ip-name': config.pyrra.GCPExternalIpAddress,
          'kubernetes.io/ingress.class': 'gce',
          'cert-manager.io/cluster-issuer': $.pyrra.certificate.spec.issuerRef.name,
          'networking.gke.io/v1beta1.FrontendConfig': $.pyrra.frontendConfig.metadata.name,
        },
        labels: $.pyrra.apiService.metadata.labels,
        name: 'pyrra',
        namespace: config.namespace,
      },
      spec: {
        rules: [{
          host: config.pyrra.DNS,
          http: {
            paths: [{
              backend: {
                serviceName: $.pyrra.apiService.metadata.name,
                servicePort: 9099,
              },
              path: '/*',
            }],
          },

        }],
        tls: [{
          hosts: [
            config.pyrra.DNS,
          ],
          secretName: $.pyrra.certificate.spec.secretName,
        }],
      },
    },

    backendOAuthSecret: {
      apiVersion: 'v1',
      kind: 'Secret',
      metadata: {
        name: 'pyrra-oauth',
        namespace: config.namespace,
        labels: $.pyrra.apiService.metadata.labels,
      },
      data: {
        client_id: std.base64(config.pyrra.IAPClientID),
        client_secret: std.base64(config.pyrra.IAPClientSecret),
      },
    },

    backendOAuth: {
      apiVersion: 'cloud.google.com/v1',
      kind: 'BackendConfig',
      metadata: {
        name: 'pyrra',
        namespace: config.namespace,
      },
      spec: {
        iap: {
          enabled: true,
          oauthclientCredentials: {
            secretName: $.pyrra.backendOAuthSecret.metadata.name,
          },
        },
      },
    },

    frontendConfig: {
      apiVersion: 'networking.gke.io/v1beta1',
      kind: 'FrontendConfig',
      metadata: {
        name: 'pyrra',
        namespace: config.namespace,
      },
      spec: {
        sslPolicy: 'pyrra-ssl-policy',
        redirectToHttps: {
          enabled: true,
          responseCodeName: '301',
        },
      },
    },
  },
}
