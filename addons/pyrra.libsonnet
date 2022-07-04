function(params) (import 'kube-prometheus/addons/pyrra.libsonnet') {

  pyrra+: {
    'slo-apiserver-read-response-errors':: {},
    'slo-apiserver-write-response-errors':: {},
    'slo-apiserver-read-resource-latency':: {},
    'slo-apiserver-read-namespace-latency':: {},
    'slo-apiserver-read-cluster-latency':: {},
    'slo-kubelet-request-errors':: {},
    'slo-kubelet-runtime-errors':: {},
    'slo-coredns-response-errors':: {},
    'slo-prometheus-operator-reconcile-errors':: {},
    'slo-prometheus-operator-http-errors':: {},
    'slo-prometheus-rule-evaluation-failures':: {},
    'slo-prometheus-sd-kubernetes-errors':: {},
    'slo-prometheus-query-errors':: {},
    'slo-prometheus-notification-errors':: {},
  },
}
