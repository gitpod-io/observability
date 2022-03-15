local defaults = {
  local defaults = self,
  // Convention: Top-level fields related to CRDs are public, other fields are hidden
  // If there is no CRD for the component, everything is hidden in defaults.
  name:: 'kubescape',
  namespace:: error 'must provide namespace',
  version:: 'prometheus.v1',
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
          name: 'KS_RUN_PROMETHEUS_SERVER',
          value: 'true',
        },
        {
          name: 'KS_DEFAULT_CONFIGMAP_NAMESPACE',
          value: k._metadata.namespace,
        },
      ],
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
        interval: '120s',
        scrapeTimeout: '120s',
        port: 'metrics',
      }],
      selector: {
        matchLabels: _config.selectorLabels,
      },
    },
  },
}
