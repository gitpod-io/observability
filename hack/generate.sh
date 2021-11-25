#!/usr/bin/env bash

set -e
set -x
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

while getopts ":e:" option; do
   case $option in
      e) 
         environment=$OPTARG;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

# Make sure to use project tooling
PATH="$(pwd)/tmp/bin:${PATH}"

if [[ $environment == "CI" ]]; then
    echo 'Generating YAML manifests for continuous integration'

    jsonnet -c -J vendor -m monitoring-satellite/manifests \
    --ext-str namespace="monitoring-satellite" \
    --ext-str cluster_name="fake-cluster" \
    --ext-str alerting_enabled="true" \
    --ext-str slack_webhook_url_critical="http://fake.url.critical" \
    --ext-str slack_webhook_url_warning="http://fake.url.warning" \
    --ext-str slack_webhook_url_info="http://fake.url.info" \
    --ext-str slack_channel_prefix="#fake_channel" \
    --ext-str pagerduty_routing_key="fakeR0uT1GNKEY" \
    --ext-str node_affinity_label='' \
    --ext-str is_preview="true" \
    --ext-str node_exporter_port="9100" \
    --ext-str remote_write_enabled="true" \
    --ext-str remote_write_password="p@ssW0rd" \
    --ext-str remote_write_username="user" \
    --ext-str prometheus_dns_name="prometheus.fake.preview.io" \
    --ext-str grafana_dns_name="grafana.fake.preview.io" \
    --ext-str tracing_enabled="true" \
    --ext-str honeycomb_api_key="fake-key" \
    --ext-str honeycomb_dataset="fake-dataset" \
    --ext-str jaeger_endpoint="http://jaeger:14268/api/traces" \
    --ext-code remote_write_urls="['http://victoriametrics-vmauth.monitoring-central.svc:8427/api/v1/write']" \
    monitoring-satellite/manifests/continuous_integration.jsonnet | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml' -- {}

    # Make sure to remove json files
    find monitoring-satellite/manifests -type f ! -name '*.yaml' ! -name '*.jsonnet'  -delete
    find monitoring-central/manifests -type f ! -name '*.yaml' ! -name '*.jsonnet'  -delete

    exit 0
fi

# Generate monitoring-satellite YAML files
jsonnet -c -J vendor -m monitoring-satellite/manifests \
--ext-str namespace="monitoring-satellite" \
--ext-str cluster_name="fake-cluster" \
--ext-str alerting_enabled="true" \
--ext-str slack_webhook_url_critical="http://fake.url.critical" \
--ext-str slack_webhook_url_warning="http://fake.url.warning" \
--ext-str slack_webhook_url_info="http://fake.url.info" \
--ext-str slack_channel_prefix="#fake_channel" \
--ext-str pagerduty_routing_key="fakeR0uT1GNKEY" \
--ext-str node_affinity_label='' \
--ext-str is_preview="true" \
--ext-str node_exporter_port="9100" \
--ext-str remote_write_enabled="true" \
--ext-str remote_write_password="p@ssW0rd" \
--ext-str remote_write_username="user" \
--ext-str prometheus_dns_name="prometheus.fake.preview.io" \
--ext-str grafana_dns_name="grafana.fake.preview.io" \
--ext-str tracing_enabled="true" \
--ext-str honeycomb_api_key="fake-key" \
--ext-str honeycomb_dataset="fake-dataset" \
--ext-str jaeger_endpoint="http://jaeger:14268/api/traces" \
--ext-code remote_write_urls="['http://victoriametrics-vmauth.monitoring-central.svc:8427/api/v1/write']" \
monitoring-satellite/manifests/yaml-generator.jsonnet | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml' -- {}

# Generate monitoring-central YAML files
jsonnet -c -J vendor -m monitoring-central/manifests \
--ext-str namespace="monitoring-central" \
--ext-str grafana_ingress_node_port=32164 \
--ext-str grafana_dns_name="http://fake.grafana.url" \
--ext-str gcp_external_ip_address="fake_external_ip_address" \
--ext-str IAP_client_id="fakeIAP_ID" \
--ext-str IAP_client_secret="fakeIAP_secret" \
--ext-str victoriametrics_dns_name="http://fake.victoriametrics.url" \
--ext-str vmauth_auth_key="random-key" \
--ext-str remote_write_password="p@ssW0rd" \
--ext-str remote_write_username="user" \
--ext-str vmauth_gcp_external_ip_address="fake_external_ip_address" \
--ext-str stackdriver_datasource_enabled="false" \
monitoring-central/manifests/yaml-generator.jsonnet | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml' -- {}

# Generate monitoring-satellite prometheus rules
jsonnet -c -J vendor -m monitoring-satellite/manifests \
--ext-str namespace="monitoring-satellite" \
--ext-str cluster_name="fake-cluster" \
--ext-str slack_webhook_url_critical="http://fake.url.critical" \
--ext-str slack_webhook_url_warning="http://fake.url.warning" \
--ext-str slack_webhook_url_info="http://fake.url.info" \
--ext-str slack_channel_prefix="#fake_channel" \
--ext-str pagerduty_routing_key="fakeR0uT1GNKEY" \
--ext-str node_affinity_label='' \
--ext-str alerting_enabled="false" \
--ext-str remote_write_enabled="false" \
--ext-str is_preview="false" \
--ext-str tracing_enabled="true" \
--ext-str honeycomb_api_key="fake-key" \
--ext-str honeycomb_dataset="fake-dataset" \
--ext-str jaeger_endpoint="http://jaeger:14268/api/traces" \
monitoring-satellite/manifests/rules.jsonnet | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml' -- {}

# Make sure to remove json files
find monitoring-satellite/manifests -type f ! -name '*.yaml' ! -name '*.jsonnet'  -delete
find monitoring-central/manifests -type f ! -name '*.yaml' ! -name '*.jsonnet'  -delete
