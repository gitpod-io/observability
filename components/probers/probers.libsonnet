local config = std.extVar('config');
local defaults = {
  defaults: self,
  name: 'blackbox-exporter',
  namespace: error 'must provide namespace',
  commonLabels: {
    'app.kubernetes.io/name': defaults.name,
    'app.kubernetes.io/part-of': 'kube-prometheus',
  },
  blackboxExporterName: error 'must provide blackbox-exporter name',
  blackboxExporterNamespace: error 'must provide blackbox-exporter namespace',
  targets: error 'must provide targets',
};

function(params) {
  local prober = self,
  _config:: defaults + params,


  probe: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'Probe',
    metadata: {
      name: prober._config.name,
      namespace: prober._config.namespace,
      labels: prober._config.commonLabels,
    },
    spec: {
      jobName: 'probe',
      prober: {
        url: prober._config.blackboxExporterName + '.' + prober._config.blackboxExporterNamespace + '.svc:19115',
        scheme: 'http',
        path: '/probe',
      },
      interval: '30s',
      module: 'http_2xx',
      targets: {
        staticConfig: {
          static: prober._config.targets,
        },
      },
    },
  },
}
