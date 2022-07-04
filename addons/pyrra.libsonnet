function(config)
  (import 'kube-prometheus/addons/pyrra.libsonnet') +
  (if std.objectHas(config.pyrra, 'DNS') then (import '../addons/pyrra-ingress.libsonnet')(config) else {}) +
  {
    local defaults = {
      prometheusURL: 'http://prometheus-k8s.%s.svc.cluster.local:9090' % config.namespace,
    },

    local pyrra = self,
    _config:: defaults + config.pyrra,

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

      apiDeployment+: {

        spec+: {
          template+: {
            spec+: {
              containers: std.map(
                function(c) c {
                  args:
                    if c.name == 'pyrra' then
                      [
                        'api',
                        '--api-url=http://%s.%s.svc.cluster.local:9444' % [$.pyrra.kubernetesService.metadata.name, $.pyrra.kubernetesService.metadata.namespace],
                        '--prometheus-url=%s' % pyrra._config.prometheusURL,
                      ]
                    else
                      [],
                },
                super.containers
              ),
            },
          },
        },
      },
    },
  }
