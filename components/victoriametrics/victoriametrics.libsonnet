local defaults = {
  local defaults = self,


  name: 'victoriametrics',
  namespace: 'monitoring-central',
  version: 'v1.47.0',
  port: 8428,
  vmAuthPort: 8427,
  internalLoadBalancerIP: error 'must provide internal load balancer ip address',
  commonLabels: {
    'app.kubernetes.io/name': defaults.name,
    'app.kubernetes.io/part-of': 'monitoring-central',
  },
};

function(params) {
  local v = self,
  _config:: defaults + params,

  clusterRole: {
    apiVersion: 'rbac.authorization.k8s.io/v1beta1',
    kind: 'ClusterRole',
    metadata: {
      labels: $._config.commonLabels,
      name: $._config.name,
    },
    rules: [{
      apiGroups: ['policy'],
      resources: ['podsecuritypolicies'],
      verbs: ['use'],
      resourceNames: [v.podSecurityPolicy.metadata.name],
    }],
  },

  clusterRoleBinding: {
    apiVersion: 'rbac.authorization.k8s.io/v1beta1',
    kind: 'ClusterRoleBinding',
    metadata: {
      labels: $._config.commonLabels,
      name: $._config.name,
    },
    subjects: [{
      kind: 'ServiceAccount',
      name: v.serviceAccount.metadata.name,
      namespace: $._config.namespace,
    }],
    roleRef: {
      apiGroup: 'rbac.authorization.k8s.io',
      kind: 'ClusterRole',
      name: v.clusterRole.metadata.name,
    },
  },

  podSecurityPolicy: {
    apiVersion: 'policy/v1beta1',
    kind: 'PodSecurityPolicy',
    metadata: {
      labels: $._config.commonLabels,
      name: $._config.name,
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
      labels: $._config.commonLabels,
      name: $._config.name,
      namespace: $._config.namespace,
    },
  },

  statefulSet: {
    apiVersion: 'apps/v1',
    kind: 'StatefulSet',
    metadata: {
      labels: $._config.commonLabels,
      name: $._config.name,
      namespace: $._config.namespace,
    },
    spec: {
      selector: {
        matchLabels: $._config.commonLabels,
      },
      serviceName: $._config.name,
      replicas: 1,
      template: {
        metadata: {
          labels: $._config.commonLabels,
        },
        spec: {
          securityContext: {
            fsGroup: 65534,
            runAsGroup: 65534,
            runAsNonRoot: true,
            runAsUser: 65534,
          },
          terminationGracePeriodSeconds: 300,
          serviceAccountName: v.serviceAccount.metadata.name,
          containers: [
            {
              name: $._config.name,
              image: 'victoriametrics/victoria-metrics:' + $._config.version,
              imagePullPolicy: 'IfNotPresent',
              args: ['-search.maxUniqueTimeseries=3000000'],
              ports: [{
                containerPort: $._config.port,
              }],
              readinessProbe: {
                httpGet: {
                  path: '/metrics',
                  port: $._config.port,
                },
                initialDelaySeconds: 30,
                timeoutSeconds: 30,
                failureThreshold: 3,
                successThreshold: 1,
              },
              livenessProbe: {
                httpGet: {
                  path: '/metrics',
                  port: $._config.port,
                },
                initialDelaySeconds: 30,
                timeoutSeconds: 30,
                failureThreshold: 3,
                successThreshold: 1,
              },
              resources: {},
              volumeMounts: [{
                name: 'storage-volume',
                mountPath: '/victoria-metrics-data',
                subPath: '',
              }],
            },
            {
              name: $._config.name + '-vmauth',
              image: 'victoriametrics/vmauth:v1.62.0',
              imagePullPolicy: 'IfNotPresent',
              args: [
                '-auth.config=/vmauth/vmauth-config.yml',
                '-pprofAuthKey=' + std.extVar('vmauth_auth_key'),
                '-reloadAuthKey=' + std.extVar('vmauth_auth_key'),
              ],
              ports: [{
                containerPort: $._config.vmAuthPort,
              }],
              resources: {},
              volumeMounts: [{
                name: 'vmauth-config',
                mountPath: '/vmauth',
              }],
            },
          ],
          volumes: [{
            name: 'vmauth-config',
            configMap: {
              name: $.vmAuthConfigMap.metadata.name,
            },
          }],
        },
      },
      volumeClaimTemplates: [{
        metadata: {
          name: 'storage-volume',
        },
        spec: {
          accessModes: ['ReadWriteOnce'],
          resources: {
            requests: {
              storage: '500Gi',
            },
          },
        },
      }],
    },
  },

  serviceVmAuth: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      labels: $._config.commonLabels,
      name: $._config.name + '-vmauth',
      namespace: $._config.namespace,
      annotations+: {
        'cloud.google.com/backend-config': '{"ports": {"' + $._config.vmAuthPort + '":"' + $.backendConfig.metadata.name + '"}}',  // same name as backend-config
      },
    },
    spec: {
      type: 'LoadBalancer',
      ports: [{
        port: $._config.vmAuthPort,
        targetPort: $._config.vmAuthPort,
        protocol: 'TCP',
        name: 'http',
      }],
      selector: $._config.commonLabels,
    },
  },

  service: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      labels: $._config.commonLabels,
      name: $._config.name,
      namespace: $._config.namespace,
      annotations: {
        // Needed to automatically create a global load balancer on GKE.
        'networking.gke.io/load-balancer-type': 'Internal',
        'networking.gke.io/internal-load-balancer-allow-global-access': 'true',
      },
    },
    spec: {
      type: 'LoadBalancer',
      loadBalancerIP: $._config.internalLoadBalancerIP,
      ports: [{
        port: $._config.port,
        targetPort: $._config.port,
        protocol: 'TCP',
        name: 'http',
      }],
      selector: $._config.commonLabels,
    },
  },

  vmAuthIngress: {
    apiVersion: 'extensions/v1beta1',
    kind: 'Ingress',
    metadata: {
      annotations: {
        'kubernetes.io/ingress.global-static-ip-name': std.extVar('vmauth_gcp_external_ip_address'),
        'kubernetes.io/ingress.class': 'gce',
        'networking.gke.io/v1beta1.FrontendConfig': $.frontendConfig.metadata.name,
        'cert-manager.io/cluster-issuer': $.certificate.spec.issuerRef.name,
      },
      labels: $._config.commonLabels,
      name: $._config.name + '-vmauth',
      namespace: std.extVar('namespace'),
    },
    spec: {
      rules: [{
        host: std.extVar('victoriametrics_dns_name'),  // gcp's external ip address
        http: {
          paths: [{
            backend: {
              serviceName: $.serviceVmAuth.metadata.name,  // same name put on service resource
              servicePort: $._config.vmAuthPort,
            },
            path: '/*',
          }],
        },
      }],
      tls: [{
        hosts: [
          std.extVar('victoriametrics_dns_name'),
        ],
        secretName: $.certificate.spec.secretName,
      }],
    },
  },

  certificate: {
    apiVersion: 'cert-manager.io/v1',
    kind: 'Certificate',
    metadata: {
      name: $._config.name + '-vmauth',
      namespace: std.extVar('namespace'),
      labels: $._config.commonLabels,
    },
    spec: {
      dnsNames: [
        std.extVar('victoriametrics_dns_name'),
      ],
      issuerRef: {
        kind: 'ClusterIssuer',
        name: 'letsencrypt-issuer',
      },
      secretName: 'victoriametrics-certificate',
    },
  },

  local authConfig =
    'users:\n' +
    '- username: "' + std.extVar('remote_write_username') + '"\n' +
    '  password: "' + std.extVar('remote_write_password') + '"\n' +
    '  url_prefix:\n' +
    '  - http://localhost:8428',

  vmAuthConfigMap: {
    apiVersion: 'v1',
    kind: 'ConfigMap',
    metadata: {
      labels: $._config.commonLabels,
      name: $._config.name + '-vmauth',
      namespace: $._config.namespace,
    },
    data: {
      'vmauth-config.yml': authConfig,
    },
  },

  backendConfig: {
    apiVersion: 'cloud.google.com/v1',
    kind: 'BackendConfig',
    metadata: {
      name: $._config.name + '-vmauth',
      namespace: std.extVar('namespace'),
    },
    spec: {
      healthCheck: {
        requestPath: '/health',
      },
    },
  },

  frontendConfig: {
    apiVersion: 'networking.gke.io/v1beta1',
    kind: 'FrontendConfig',
    metadata: {
      name: $._config.name + '-vmauth',
      namespace: std.extVar('namespace'),
    },
    spec: {
      sslPolicy: 'victoriametrics-ssl-policy',
      redirectToHttps: {
        enabled: true,
        responseCodeName: '301',
      },
    },
  },
}
