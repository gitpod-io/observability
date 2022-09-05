local defaults = {
  local defaults = self,
  // Convention: Top-level fields related to CRDs are public, other fields are hidden
  // If there is no CRD for the component, everything is hidden in defaults.
  name:: 'kubescape',
  namespace:: error 'must provide namespace',
  version:: 'prometheus.v2',
  image:: 'quay.io/armosec/kubescape',
  resources:: {
    requests: { cpu: '10m', memory: '100Mi' },
    limits: { cpu: '500m', memory: '500Mi' },
  },
  commonLabels:: {
    'app.kubernetes.io/name': defaults.name,
    'app.kubernetes.io/version': defaults.version,
    'app.kubernetes.io/component': 'kubescape',
    'app.kubernetes.io/part-of': 'kube-prometheus',
  },
  selectorLabels:: {
    [labelName]: defaults.commonLabels[labelName]
    for labelName in std.objectFields(defaults.commonLabels)
    if !std.setMember(labelName, ['app.kubernetes.io/version'])
  },
  scrapeInterval: '60s',
  mixin: {
    ruleLabels: {},
    _config: {
      runbookURLPattern: 'https://runbooks.prometheus-operator.dev/runbooks/kubescape/%s',
    },
  },
};


function(params) {
  local k = self,
  local _config = defaults + params,
  local controlConfig =
    |||
      {
        "cpu_limit_max": [],
        "cpu_limit_min": [],
        "cpu_request_max": [],
        "cpu_request_min": [],
        "imageRepositoryAllowList": [
          "ecr.*amazonaws.com",
          ".*.gcr.io",
          ".*azurecr.io",
          "quay.io",
          "docker.io"
        ],
        "insecureCapabilities": [
          "SETPCAP",
          "NET_ADMIN",
          "NET_RAW",
          "SYS_MODULE",
          "SYS_RAWIO",
          "SYS_PTRACE",
          "SYS_ADMIN",
          "SYS_BOOT",
          "MAC_OVERRIDE",
          "MAC_ADMIN",
          "PERFMON",
          "ALL",
          "BPF"
        ],
        "k8sRecommendedLabels": [
          "app.kubernetes.io/name",
          "app.kubernetes.io/instance",
          "app.kubernetes.io/version",
          "app.kubernetes.io/component",
          "app.kubernetes.io/part-of",
          "app.kubernetes.io/managed-by",
          "app.kubernetes.io/created-by"
        ],
        "listOfDangerousArtifcats": [
          "bin/bash",
          "sbin/sh",
          "bin/ksh",
          "bin/tcsh",
          "bin/zsh",
          "usr/bin/scsh",
          "bin/csh",
          "bin/busybox",
          "usr/bin/busybox"
        ],
        "max_critical_vulnerabilities": [
          "5"
        ],
        "max_high_vulnerabilities": [
          "10"
        ],
        "memory_limit_max": [],
        "memory_limit_min": [],
        "memory_request_max": [],
        "memory_request_min": [],
        "publicRegistries": [
          "registry.hub.docker.com"
        ],
        "recommendedLabels": [
          "app",
          "tier",
          "phase",
          "version",
          "owner",
          "env"
        ],
        "sensitiveInterfaces": [
          "nifi",
          "argo-server",
          "weave-scope-app",
          "kubeflow",
          "kubernetes-dashboard"
        ],
        "sensitiveKeyNames": [
          "aws_access_key_id",
          "aws_secret_access_key",
          "azure_batchai_storage_account",
          "azure_batchai_storage_key",
          "azure_batch_account",
          "azure_batch_key",
          "secret",
          "key",
          "password",
          "pwd",
          "token",
          "jwt",
          "bearer",
          "credential"
        ],
        "sensitiveValues": [
          "BEGIN \\w+ PRIVATE KEY",
          "PRIVATE KEY",
          "eyJhbGciO",
          "JWT",
          "Bearer",
          "_key_",
          "_secret_"
        ],
        "sensitiveValuesAllowed": [],
        "servicesNames": [
          "nifi-service",
          "argo-server",
          "minio",
          "postgres",
          "workflow-controller-metrics",
          "weave-scope-app",
          "kubernetes-dashboard"
        ],
        "untrustedRegistries": [],
        "wlKnownNames": [
          "coredns",
          "kube-proxy",
          "event-exporter-gke",
          "kube-dns",
          "17-default-backend",
          "metrics-server",
          "ca-audit",
          "ca-dashboard-aggregator",
          "ca-notification-server",
          "ca-ocimage",
          "ca-oracle",
          "ca-posture",
          "ca-rbac",
          "ca-vuln-scan",
          "ca-webhook",
          "ca-websocket",
          "clair-clair"
        ]
      }
    |||,

  local exceptionConfig =
    |||
      [
        {
          "name": "exclude-allowed-privileged",
          "policyType": "postureExceptionPolicy",
          "actions": [
            "alertOnly"
          ],
          "resources": [
            {
              "designatorType": "Attributes",
              "attributes": {
                "kind": "DaemonSet",
                "name": "agent-smith"
              }
            },
            {
              "designatorType": "Attributes",
              "attributes": {
                "kind": "DaemonSet",
                "name": "ws-daemon"
              }
            },
            {
              "designatorType": "Attributes",
              "attributes": {
                "kind": "DaemonSet",
                "name": "falco"
              }
            },
            {
              "designatorType": "Attributes",
              "attributes": {
                "kind": "DaemonSet",
                "name": "calico-node"
              }
            },
            {
              "designatorType": "Attributes",
              "attributes": {
                "kind": "DaemonSet",
                "name": "ip-masq-agent"
              }
            },
            {
              "designatorType": "Attributes",
              "attributes": {
                "kind": "DaemonSet",
                "name": "kube-proxy"
              }
            },
          {
              "designatorType": "Attributes",
              "attributes": {
                "kind": "DaemonSet",
                "name": "metadata-proxy-v0.1"
              }
            },
          {
              "designatorType": "Attributes",
              "attributes": {
                "kind": "DaemonSet",
                "name": "nvidia-gpu-device-plugin"
              }
            },
          {
              "designatorType": "Attributes",
              "attributes": {
                "kind": "DaemonSet",
                "name": "pdcsi-node"
              }
            },
          ],
          "posturePolicies": [
            {
              "controlID": "C-0057"
            }
          ]
        },
      {
          "name": "exclude-allowed-hostPID",
          "policyType": "postureExceptionPolicy",
          "actions": [
            "alertOnly"
          ],
          "resources": [
            {
              "designatorType": "Attributes",
              "attributes": {
                "kind": "DaemonSet",
                "name": "node-exporter"
              }
            },
            {
              "designatorType": "Attributes",
              "attributes": {
                "kind": "DaemonSet",
                "name": "ws-daemon"
              }
            },
            {
              "designatorType": "Attributes",
              "attributes": {
                "kind": "DaemonSet",
                "name": "agent-smith"
              }
            }
          ],
          "posturePolicies": [
            {
              "controlID": "C-0038"
            }
          ]
        },
        {
          "name": "exclude-allowed-hostPath",
          "policyType": "postureExceptionPolicy",
          "actions": [
            "alertOnly"
          ],
          "resources": [
            {
              "designatorType": "Attributes",
              "attributes": {
                "kind": "DaemonSet",
                "name": "fluentbit-gke"
              }
            },
            {
              "designatorType": "Attributes",
              "attributes": {
                "kind": "DaemonSet",
                "name": "fluentbit-gke-256pd"
              }
            },
            {
              "designatorType": "Attributes",
              "attributes": {
                "kind": "DaemonSet",
                "name": "fluentbit-gke-max"
              }
            },
            {
              "designatorType": "Attributes",
              "attributes": {
                "kind": "DaemonSet",
                "name": "gke-metrics-agent"
              }
            },
            {
              "designatorType": "Attributes",
              "attributes": {
                "kind": "DaemonSet",
                "name": "gke-metrics-agent-scaling-10"
              }
            },
            {
              "designatorType": "Attributes",
              "attributes": {
                "kind": "DaemonSet",
                "name": "gke-metrics-agent-scaling-20"
              }
            },
            {
              "designatorType": "Attributes",
              "attributes": {
                "kind": "DaemonSet",
                "name": "kube-proxy"
              }
            },
            {
              "designatorType": "Attributes",
              "attributes": {
                "kind": "DaemonSet",
                "name": "network-metering-agent"
              }
            },
            {
              "designatorType": "Attributes",
              "attributes": {
                "kind": "DaemonSet",
                "name": "nvidia-gpu-device-plugin"
              }
            },
            {
              "designatorType": "Attributes",
              "attributes": {
                "kind": "DaemonSet",
                "name": "pdcsi-node"
              }
            },
            {
              "designatorType": "Attributes",
              "attributes": {
                "kind": "DaemonSet",
                "name": "pdcsi-node-windows"
              }
            },
            {
              "designatorType": "Attributes",
              "attributes": {
                "kind": "DaemonSet",
                "name": "node-exporter"
              }
            },
            {
              "designatorType": "Attributes",
              "attributes": {
                "kind": "DaemonSet",
                "name": "calico-node"
              }
            },
            {
              "designatorType": "Attributes",
              "attributes": {
                "kind": "DaemonSet",
                "name": "ws-daemon"
              }
            },
            {
              "designatorType": "Attributes",
              "attributes": {
                "kind": "DaemonSet",
                "name": "registry-facade"
              }
            },
            {
              "designatorType": "Attributes",
              "attributes": {
                "kind": "Deployment",
                "name": "event-exporter-gke"
              }
            },
          ],
          "posturePolicies": [
            {
              "controlID": "C-0006"
            },
            {
              "controlID": "C-0045"
            },
            {
              "controlID": "C-0048"
            },
            {
              "controlID": "C-0074"
            }
          ]
        }
      ]
    |||,
  // Safety check
  assert std.isObject(_config.resources),

  mixin:: (import 'mixin/mixin.libsonnet') {
    _config+:: k._config.mixin._config,
  },

  _metadata:: {
    name: _config.name,
    namespace: _config.namespace,
    labels: _config.commonLabels,
  },

  serviceAccount: {
    apiVersion: 'v1',
    kind: 'ServiceAccount',
    metadata: k._metadata,
  },

  clusterRole: {
    kind: 'ClusterRole',
    apiVersion: 'rbac.authorization.k8s.io/v1',
    metadata: k._metadata {
      namespace:: null,
    },
    rules: [{
      apiGroups: ['*'],
      resources: ['*'],
      verbs: ['get', 'list', 'describe'],
    }, {
      apiGroups: ['policy'],
      resources: ['podsecuritypolicies'],
      verbs: ['use'],
      resourceNames: [k._metadata.name],
    }],
  },

  clusterRoleBinding: {
    kind: 'ClusterRoleBinding',
    apiVersion: 'rbac.authorization.k8s.io/v1',
    metadata: k._metadata {
      namespace:: null,
    },
    roleRef: {
      apiGroup: 'rbac.authorization.k8s.io',
      kind: 'ClusterRole',
      name: k._metadata.name,
    },
    subjects: [{
      kind: 'ServiceAccount',
      name: k._metadata.name,
      namespace: k._metadata.namespace,
    }],
  },

  service: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: k._metadata,
    spec: {
      selector: _config.selectorLabels,
      type: 'NodePort',
      ports: [{
        name: 'metrics',
        port: 8080,
        targetPort: 8080,
        protocol: 'TCP',
      }],
    },
  },

  deployment: {
    local container = {
      name: _config.name,
      image: _config.image + ':' + _config.version,
      args: [
        '--controls-config',
        '/home/.kubescape/controls-input.json',
        '--exceptions',
        '/home/.kubescape/kubescape-exceptions.json',
      ],
      env: [
        {
          name: 'KS_SKIP_UPDATE_CHECK',
          value: 'true',
        },
        {
          name: 'KS_ENABLE_HOST_SCANNER',
          value: 'false',
        },
        {
          name: 'KS_DOWNLOAD_ARTIFACTS',
          value: 'false',
        },
        {
          name: 'KS_DEFAULT_CONFIGMAP_NAMESPACE',
          valueFrom: {
            fieldRef: {
              apiVersion: 'v1',
              fieldPath: 'metadata.namespace',
            },
          },
        },
      ],
      livenessProbe: {
        httpGet: {
          path: '/livez',
          port: 8080,
        },
        initialDelaySeconds: 3,
        periodSeconds: 3,
      },
      readinessProbe: {
        httpGet: {
          path: '/readyz',
          port: 8080,

        },
        initialDelaySeconds: 3,
        periodSeconds: 3,

      },
      ports: [{
        containerPort: 8080,
      }],
      command: ['kubescape'],
      resources: _config.resources,
      volumeMounts: [
        {
          name: 'config',
          mountPath: '/home/.kubescape',
          readOnly: true,
        },
      ],
    },

    apiVersion: 'apps/v1',
    kind: 'Deployment',
    metadata: k._metadata,
    spec: {
      replicas: 1,
      selector: {
        matchLabels: _config.selectorLabels,
      },
      template: {
        metadata: {
          labels: k._metadata.labels,
        },
        spec: {
          serviceAccountName: k._metadata.name,
          containers: [container],
          volumes: [
            {
              name: 'config',
              configMap: {
                name: k._metadata.name,
              },
            },
          ],
        },
      },
    },
  },

  configMap: {
    apiVersion: 'v1',
    kind: 'ConfigMap',
    metadata: k._metadata,
    data: {
      'controls-inputs.json': controlConfig,
      'kubescape-exceptions.json': exceptionConfig,
    },
  },

  serviceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: k._metadata,
    spec: {
      endpoints: [{
        interval: _config.scrapeInterval,
        scrapeTimeout: _config.scrapeInterval,
        port: 'metrics',
      }],
      selector: {
        matchLabels: _config.selectorLabels,
      },
    },
  },

  podSecurityPolicy: {
    apiVersion: 'policy/v1beta1',
    kind: 'PodSecurityPolicy',
    metadata: {
      name: k._metadata.name,
    },
    spec: {
      privileged: false,
      // Required to prevent escalations to root.
      allowPrivilegeEscalation: false,
      // This is redundant with non-root + disallow privilege escalation,
      // but we can provide it for defense in depth.
      requiredDropCapabilities: ['ALL'],
      // Allow core volume types.
      volumes: [
        'configMap',
        'emptyDir',
        'secret',
        'projected',
        // Assume that persistentVolumes set up by the cluster admin are safe to use.
        'persistentVolumeClaim',
      ],
      hostNetwork: false,
      hostIPC: false,
      hostPID: false,
      runAsUser: {
        // Require the container to run without root privileges.
        rule: 'RunAsAny',
      },
      seLinux: {
        // This policy assumes the nodes are using AppArmor rather than SELinux.
        rule: 'RunAsAny',
      },
      supplementalGroups: {
        rule: 'MustRunAs',
        ranges: [{
          // Forbid adding the root group.
          min: 1,
          max: 65535,
        }],
      },
      fsGroup: {
        rule: 'MustRunAs',
        ranges: [{
          // Forbid adding the root group.
          min: 1,
          max: 65535,
        }],
      },
      readOnlyRootFilesystem: false,
    },
  },

  networkPolicy: {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'NetworkPolicy',
    metadata: {
      name: k._metadata.name,
      namespace: k._metadata.namespace,
      labels: _config.commonLabels,
    },
    spec: {
      podSelector: {
        matchLabels: _config.selectorLabels,
      },
      policyTypes: ['Egress', 'Ingress'],
      egress: [{}],
      ingress: [{
        from: [{
          podSelector: {
            matchLabels: {
              'app.kubernetes.io/name': 'prometheus',
            },
          },
        }],
        ports: std.map(function(o) {
          port: o.port,
          protocol: 'TCP',
        }, k.service.spec.ports),
      }],
    },
  },
}
