{

  alertmanager+: {
    role: {
      apiVersion: 'rbac.authorization.k8s.io/v1',
      kind: 'Role',
      metadata: {
        name: 'alertmanager-' + $.values.alertmanager.name,
        namespace: $.values.alertmanager.namespace,
      },
      rules: [],
    },

    roleBinding: {
      apiVersion: 'rbac.authorization.k8s.io/v1',
      kind: 'RoleBinding',
      metadata: {
        name: 'alertmanager-' + $.values.alertmanager.name,
        namespace: $.values.alertmanager.namespace,
      },
      roleRef: {
        apiGroup: 'rbac.authorization.k8s.io',
        kind: 'Role',
        name: 'alertmanager-' + $.values.alertmanager.name,
      },
      subjects: [{
        kind: 'ServiceAccount',
        name: 'alertmanager-' + $.values.alertmanager.name,
        namespace: $.values.alertmanager.namespace,
      }],
    },
  },

  grafana+: {
    role: {
      apiVersion: 'rbac.authorization.k8s.io/v1',
      kind: 'Role',
      metadata: {
        name: 'grafana',
        namespace: $.values.grafana.namespace,
      },
      rules: [],
    },

    roleBinding: {
      apiVersion: 'rbac.authorization.k8s.io/v1',
      kind: 'RoleBinding',
      metadata: {
        name: 'grafana',
        namespace: $.values.grafana.namespace,
      },
      roleRef: {
        apiGroup: 'rbac.authorization.k8s.io',
        kind: 'Role',
        name: 'grafana',
      },
      subjects: [{
        kind: 'ServiceAccount',
        name: $.grafana.serviceAccount.metadata.name,
        namespace: $.grafana.serviceAccount.metadata.namespace,
      }],
    },
  },

}