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

The monitoring-satellite's components can be customized by setting up different values for several Jsonnet external-variables. Some of those external variables are required (even if left empty), and other can become required depending on the values of other variables. The complete list can be seen below:

| External Variable          	| Required                                                                              	| Description                                                                                                                                                    	|
|----------------------------	|---------------------------------------------------------------------------------------	|----------------------------------------------------------------------------------------------------------------------------------------------------------------	|
| namespace                  	| Yes                                                                                   	| Namespace where all components will be deployed                                                                                                                	|
| cluster_name               	| Yes                                                                                   	| Value of the Prometheus' external label `cluster`.                                                                                                             	|
| is_preview                 	| Yes                                                                                   	| If set to `true`, will make several changes required to run monitoring-satellite in preview environments. See `addons/preview-env.libsonnet` for more details. 	|
| remote_write_enabled       	| Yes                                                                                   	| If set to `true`, will configure Prometheus to send metrics to a remote-backend.                                                                               	|
| alerting_enabled           	| Yes                                                                                   	| If set to `true`, will configure alert routing to slack/pagerduty.                                                                                             	|
| tracing_enabled            	| Yes                                                                                   	| If set to `true`, will add OpenTelemetry-Collector to monitoring-satellite. The collector can be configure to send traces to Honeycomb and/or Jaeger.          	|
| node_affinity_label        	| Yes                                                                                   	| If different from an empty string, will set up node affinity to all components of monitoring-satellite.                                                        	|
| remote_write_urls          	| If `remote_write_enabled` is set to `true`                                            	| URLs where prometheus will send metrics to.                                                                                                                    	|
| remote_write_username      	| If `remote_write_enabled` is set to `true`                                            	| Username used to authenticate against the remote-write endpoint.                                                                                               	|
| remote_write_password      	| If `remote_write_enabled` is set to `true`                                            	| Password used to authenticate against the remote-write endpoint.                                                                                               	|
| pagerduty_routing_key      	| If `alerting_enabled` is set to `true`                                                	| Pagerduty Routing key used to route `critical` alerts. If set to an empty string, `slack_webhook_url_critical` will take preference.                           	|
| slack_webhook_url_critical 	| If `alerting_enabled` is set to `true` and `pagerduty_routing_key` is an empty string 	| Slack webhook URL used to route `critical` alerts.                                                                                                             	|
| slack_webhook_url_warning  	| If `alerting_enabled` is set to `true`                                                	| Slack webhook URL used to route `warning` alerts.                                                                                                              	|
| slack_webhook_url_info     	| If `alerting_enabled` is set to `true`                                                	| Slack webhook URL used to route `info` alerts.                                                                                                                 	|
| slack_channel_prefix       	| If `alerting_enabled` is set to `true`                                                	| Prefix of the slack channels where alerts are being routed to.                                                                                                 	|
| honeycomb_api_key          	| If `tracing_enabled` is set to `true`                                                 	| Honeycomb API key used to push traces to honeycomb. Leave as an empty string to not send traces to Honeycomb.                                                  	|
| honeycomb_dataset          	| If `tracing_enabled` is set to `true` and `honeycomb_api_key` is not an empty string  	| Dataset where traces are going to be stored.                                                                                                                   	|
| jaeger_endpoint            	| If `tracing_enabled` is set to `true`                                                 	| Jaeger HTTP endpoint where traces are going to be pushed to. Leave as an empty string to not send traces to Jaeger.                                            	|
| node_exporter_port         	| If `is_preview` is set to `true`                                                      	| Port used by the node-exporter daemonset.                                                                                                                      	|
| prometheus_dns_name        	| If `is_preview` is set to `true`                                                      	| DNS used to configure Prometheus's certificate and ingress.                                                                                                    	|
| grafana_dns_name           	| If `is_preview` is set to `true`                                                      	| DNS used to configure Grafanas's certificate and ingress.                                                                                                      	|


Therefore, the simplest command that can be used to generate monitoring-satellite manifests would be:
```bash
jsonnet -c -J vendor -m monitoring-satellite/manifests \
--ext-str namespace="monitoring-satellite" \
--ext-str cluster_name="my-cluster" \
--ext-str alerting_enabled="false" \
--ext-str node_affinity_label='' \
--ext-str is_preview="false" \
--ext-str remote_write_enabled="false" \
--ext-str tracing_enabled="false" \
monitoring-satellite/manifests/yaml-generator.jsonnet | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml' -- {}
```

### Monitoring-central

#### Components

* [Grafana](https://github.com/grafana/grafana)
* [VictoriaMetrics](https://github.com/VictoriaMetrics/VictoriaMetrics) 

Monitoring-central is composed by a set of components responsible for receiving observability signals(usually from monitoring-satellite) and storing them for long term. At the same time, it provides a stable URL where one can access Grafana's UI with all datasources already configured.

The monitoring-central's components can be customized by setting up different values for several Jsonnet external-variables. Some of those external variables are required (even if left empty), and other can become required depending on the values of other variables. The complete list can be seen below:

| External Variable              	| Required 	| Description                                                                  	|
|--------------------------------	|----------	|------------------------------------------------------------------------------	|
| namespace                      	| Yes      	| Namespace where all components will be deployed.                             	|
| grafana_dns_name               	| Yes      	| DNS used to configure Grafanas's certificate and ingress.                    	|
| grafana_ingress_node_port      	| Yes      	| Port used by Grafana's ingress.                                              	|
| gcp_external_ip_address        	| Yes      	| Name of GCP static external-ip resource, used by Grafana's ingress.          	|
| IAP_client_id                  	| Yes      	| Identity Aware Proxy client ID used to create google managed authentication. 	|
| victoriametrics_dns_name       	| Yes      	| DNS used to configure VictoriaMetrics' certificate and ingress.              	|
| remote_write_username          	| Yes      	| Username required to authenticate against the remote-write endpoint.         	|
| remote_write_password          	| Yes      	| Password required to authenticate against the remote-write endpoint.         	|
| vmauth_auth_key                	| Yes      	| Random string used to protect VictoriaMetrics' reload and debug endpoints.   	|
| vmauth_gcp_external_ip_address 	| Yes      	| Name of GCP static external-ip resource, used by VictoriaMetrics's ingress.  	|

Therefore, the simplest command that can be used to generate monitoring-central manifests would be:
```bash
jsonnet -c -J vendor -m monitoring-central/manifests \
--ext-str namespace="monitoring-central" \
--ext-str grafana_dns_name="http://my.grafana.url" \
--ext-str grafana_ingress_node_port=32164 \
--ext-str gcp_external_ip_address="my_external_ip_address" \
--ext-str IAP_client_id="myIAP_ID" \
--ext-str IAP_client_secret="myIAP_secret" \
--ext-str victoriametrics_dns_name="http://my.victoriametrics.url" \
--ext-str vmauth_auth_key="random-key" \
--ext-str remote_write_password="password" \
--ext-str remote_write_username="user" \
--ext-str vmauth_gcp_external_ip_address="my_other_external_ip_address" \
monitoring-central/manifests/yaml-generator.jsonnet | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml' -- {}
```