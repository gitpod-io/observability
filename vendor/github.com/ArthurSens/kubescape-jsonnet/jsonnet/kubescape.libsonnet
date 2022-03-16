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
        },
      },
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
