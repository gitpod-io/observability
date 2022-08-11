# Observability

[![Build Status](https://github.com/gitpod-com/observability/workflows/ci/badge.svg)](https://github.com/gitpod-com/observability/actions)
[![Slack](https://img.shields.io/badge/join%20slack-%23observability-brightgreen.svg)](https://gitpod.slack.com/archives/C01KGM9D8LE)
[![Gitpod ready-to-code](https://img.shields.io/badge/Gitpod-ready--to--code-908a85?logo=gitpod)](https://gitpod.io/#https://github.com/gitpod-com/observability)

Set of Jsonnet files used to deploy customized [monitoring-satellites](#monitoring-satellite) and [monitoring-centrals](#monitoring-central) into different clusters.

## Table of contents

- [Applications](#applications)
  - [Monitoring-satellite](#monitoring-satellite)
  - [Monitoring-central](#monitoring-central)

## Applications

### Monitoring-satellite

Monitoring-satellite is composed by a set of components responsible for collecting and pushing observability signals from a Kubernetes cluster to a remote location (usually monitoring-central) while also being responsible for the alerting evaluation and alert routing.

#### Components

* [Alertmanager](https://github.com/prometheus/alertmanager)
* [Grafana](https://github.com/grafana/grafana)
* [Kube-State-Metrics](https://github.com/kubernetes/kube-state-metrics)
* [Node-exporter](https://github.com/prometheus/node_exporter)
* [Prometheus](https://github.com/prometheus/prometheus)
* [Prometheus-Operator](https://github.com/prometheus-operator/prometheus-operator)
* [OpenTelemetry-Collector](https://github.com/open-telemetry/opentelemetry-collector) (If tracing support is enabled)

To customize the stack, we make use of Jsonnet's [external-variables feature](https://jsonnet.org/ref/stdlib.html). We expect one single external variable called `config` which is loaded and merged with monitoring-satellite to customize the stack.

We expect `config` to be a JSON object, where extra configuration can be added as we develop new features for monitoring-satellite. For more details, please check [monitoring-satellite data schema](docs/monitoring-satellite.proto).

A minimal example would be:
```bash
jsonnet -c -J vendor -m monitoring-satellite/manifests \
--ext-code config="{
    namespace: 'monitoring-satellite',
    clusterName: 'fake-cluster',
}" \
monitoring-satellite/manifests/yaml-generator.jsonnet | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml' -- {}
```

### Monitoring-central

#### Components

* [Grafana](https://github.com/grafana/grafana)
* [VictoriaMetrics](https://github.com/VictoriaMetrics/VictoriaMetrics)

To customize the stack, we make use of Jsonnet's [external-variables feature](https://jsonnet.org/ref/stdlib.html). We expect one single external variable called `config` which is loaded and merged with monitoring-satellite to customize the stack.

We expect `config` to be a JSON object, where extra configuration can be added as we develop new features for monitoring-central. For more details, please check [monitoring-central data schema](docs/monitoring-central.proto).

A minimal example would be:
```bash
jsonnet -c -J vendor -m monitoring-central/manifests \
--ext-code config="{
    namespace: 'monitoring-central',
    grafana: {
        nodePort: 32164,
        DNS: 'http://fake.grafana.url',
        GCPExternalIpAddress: 'fake_external_ip_address',
        IAPClientID: 'fakeIAP_ID',
        IAPClientSecret: 'fakeIAP_secret',
    },
    victoriametrics: {
        DNS: 'http://fake.victoriametrics.url',
        authKey: 'random-key',
        username: 'p@ssW0rd',
        password: 'user',
        GCPExternalIpAddress: 'fake_external_ip_address',
    },
}" \
monitoring-central/manifests/yaml-generator.jsonnet | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml' -- {}
```
