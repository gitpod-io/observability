// FIXME(arthursens):
// This addon should be removed after https://github.com/prometheus-operator/kube-prometheus/pull/1724 is merged

// Disables creation of NetworkPolicies
{
  blackboxExporter+: {
    networkPolicy:: {},
  },

  kubeStateMetrics+: {
    networkPolicy:: {},
  },

  nodeExporter+: {
    networkPolicy:: {},
  },

  prometheusAdapter+: {
    networkPolicy:: {},
  },

  alertmanager+: {
    networkPolicy:: {},
  },

  grafana+: {
    networkPolicy:: {},
  },

  prometheus+: {
    networkPolicy:: {},
  },

  prometheusOperator+: {
    networkPolicy:: {},
  },
}
