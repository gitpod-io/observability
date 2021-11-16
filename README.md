# Observability

[![Build Status](https://github.com/gitpod-com/observability/workflows/ci/badge.svg)](https://github.com/gitpod-com/observability/actions)
[![Slack](https://img.shields.io/badge/join%20slack-%23observability-brightgreen.svg)](https://gitpod.slack.com/archives/C01KGM9D8LE)
[![Gitpod ready-to-code](https://img.shields.io/badge/Gitpod-ready--to--code-908a85?logo=gitpod)](https://gitpod.io/#https://github.com/gitpod-com/observability)

Set of Jsonnet files used to deploy customized [monitoring-satellites](#monitoring-satellite) and [monitoring-centrals](#monitoring-central) into different clusters.

## Table of contents

- [Applications](#applications)
  - [Monitoring-satellite](#monitoring-satellite)
  - [Monitoring-Central](#monitoring-central)
- [Workflows](#workflows)
  - [Development](#development)
  - [CI](#ci)
  - [Deployment](#deployment)

## Applications

### Monitoring-satellite

Monitoring-satellite is an application responsible for collecting observability signals from kubernetes clusters. Components included in monitoring-satellite:

* [Prometheus-Operator](https://github.com/prometheus-operator/prometheus-operator)
* [Prometheus](https://github.com/prometheus/prometheus)
* [Alertmanager](https://github.com/prometheus/alertmanager)
* [Node-exporter](https://github.com/prometheus/node_exporter)
* [Kube-State-Metrics](https://github.com/kubernetes/kube-state-metrics)
* [Grafana](https://github.com/grafana/grafana)
* Custom ServiceMonitors for [Gitpod](https://github.com/gitpod-io/gitpod)'s components

Monitoring-satellite can be customized by setting up jsonnet external-variables:

* `namespace` - changes the namespace where monitoring-satellite will be installed
* `cluster_name` - adds a external label named `cluster` to Prometheus. This label is extermelly important to differentiate metrics comming from multiple clusters after being stored in monitoring-central.
* `remote_write_url` - When defining this variable with something different from an empty string, Prometheus will send metrics to a Metrics backend, e.g. Thanos or Cortex, through Prometheus' Remote Write Protocol.
* `pagerduty_routing_key` - Used to route critical alerts to pagerduty.
* `slack_webhook_url_critical` - When defining this variable with something different from an empty string, Alertmanager will be configured to route alerts to Slack. **Careful:** When declaring this variable, you should also declare `slack_webhook_url_warning` and `slack_webhook_url_info`, which will route alerts from lower severities to different channels.
* `dns_name` - When defining this variable with something different from an empty string, a set of extra resources will be created to expose Grafana to the internet while keeping it secure. When defining this variable, be careful to also declare `grafana_ingress_node_port`, `gcp_external_ip_address`, `IAP_client_id` and `IAP_client_secret`. The components included are:
  * Ingress
  * SSL Certificate (Requires certmanager installed in the cluster)
  * Google Cloud Backend Config

#### Monitoring-satellite RoadMap

As you can see, Metrics is the only Observability signal being collected by monitoring satellite right now. To make it complete Observability signal collector, we'll extend this application to collect: 

* `Logs` - With [Promtail](https://grafana.com/docs/loki/latest/clients/promtail/) or [Fluentd](https://www.fluentd.org/)
* `Traces` - With [Jaeger Agent](https://www.jaegertracing.io/docs/1.22/deployment/) or [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector)
* `Profiles` - With [ConProf](https://github.com/conprof/conprof)

### Monitoring-Central

Monitoring-central is an application responsible for storing multiple signals collected by multiple monitoring-satellites for long term. Monitoring-central is the best place to analyze data during incidents or historical trend analisis. Components included in monitoring-central:

* [Grafana](https://github.com/grafana/grafana)
* [VictoriaMetrics](https://github.com/VictoriaMetrics/VictoriaMetrics)

Monitoring-central can be customized by setting up jsonnet external-variables:

* `dns_name` - When defining this variable with something different from an empty string, a set of extra resources will be created to expose Grafana to the internet while keeping it secure. When defining this variable, be careful to also declare `grafana_ingress_node_port`, `gcp_external_ip_address`, `IAP_client_id` and `IAP_client_secret`. The components included are:
  * Ingress
  * SSL Certificate (Requires certmanager installed in the cluster)
  * Google Cloud Backend Config

#### Monitoring-central RoadMap

Similarly to monitoring-satellite, monitoring-central only supports metric collection right now. To make it a complete Observability signal backend storage, we'll extend this application to store:

* `Logs` - With [Loki](https://github.com/grafana/loki)
* `Traces` - With [Jaeger](https://github.com/jaegertracing/jaeger) or [Tempo](https://github.com/grafana/tempo)
* `Profiles` - With [ConProf](https://github.com/conprof/conprof)

> To accelerate the development of monitoring-central, we are strongly considering teaming up with the Red Hat Monitoring Team to use [Observatorium](https://github.com/observatorium/observatorium) as our storage for all observability signals.

## Workflows

### Development

See [docs/code-design](./docs/code-design.md) for details on our folder structure.

During development we generate YAML files and Grafana dashboards based on our jsonnet templates.

**Notice**: These YAML files are only used during development and CI. For development/ci the entrypoints are `monitoring-*/manifests/*.jsonnet` whereas for ArgoCD the entrypoint is `monitoring-*/main.jsonnet`.

To generate the YAML files and Grafana dashboards run the command below.

```sh
make generate
```

The generated files are placed in `monitoring-*/manifests` - while working on the jsonnet templates it can sometimes be helpful to check out the generated YAML to see if everything looks the way you expected.

If you'd like to test Grafana dashboards during development, you can copy the content of the JSON files located at `components/gitpod/mixin/dashboard_out` and import it to Grafana using the import feature:

![image](https://user-images.githubusercontent.com/24193764/118832120-ba971200-b896-11eb-81aa-840dadecd21b.png)


To make sure that all our jsonnet templates can compile and are correctly formatted run:

```sh
make fmt
```

If you are changing Prometheus rules you can additionally run:

```sh
make promtool-lint
```

