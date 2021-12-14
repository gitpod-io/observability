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
    --ext-code config="{
      namespace: 'monitoring-satellite',
      clusterName: 'fake-cluster',
      tracing: {
        honeycombAPIKey: 'fake-key',
        honeycombDataset: 'fake-dataset',
        jaegerEndpoint: 'http://jaeger:14250',
      },
      continuousIntegration: true,
    }" \
    monitoring-satellite/manifests/yaml-generator.jsonnet | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml' -- {}

    # Make sure to remove json files
    find monitoring-satellite/manifests -type f ! -name '*.yaml' ! -name '*.jsonnet'  -delete
    find monitoring-central/manifests -type f ! -name '*.yaml' ! -name '*.jsonnet'  -delete

    exit 0
fi

# Generate monitoring-satellite YAML files
jsonnet -c -J vendor -m monitoring-satellite/manifests \
--ext-code config="{
    namespace: 'monitoring-satellite',
    clusterName: 'fake-cluster',
    alerting: {
        slackWebhookURLCritical: 'http://fake.url.critical',
        slackWebhookURLWarning: 'http://fake.url.warning',
        slackWebhookURLInfo: 'http://fake.url.info',
        slackChannelPrefix: '#fake_channel',
        pagerdutyRoutingKey: 'fakeR0uT1GNKEY',
    },
    tracing: {
        honeycombAPIKey: 'fake-key',
        honeycombDataset: 'fake-dataset',
        jaegerEndpoint: 'http://jaeger:14250',
    },
    remoteWrite: {
        username: 'user',
        password: 'p@ssW0rd',
        urls: ['http://victoriametrics-vmauth.monitoring-central.svc:8427/api/v1/write'],
    },
    previewEnvironment: {
        prometheusDNS: 'prometheus.fake.preview.io',
        grafanaDNS: 'grafana.fake.preview.io',
        nodeExporterPort: 9100
    },
    nodeAffinity: {
        nodeSelector: {
            nodepool: 'monitoring',
            'kubernetes.io/os': 'linux',
        },
    },
    werft: {
        namespace: 'werft',
    }
}" \
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
monitoring-central/manifests/yaml-generator.jsonnet | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml' -- {}

# Generate monitoring-satellite prometheus rules
jsonnet -c -J vendor -m monitoring-satellite/manifests \
--ext-code config="{
    namespace: 'monitoring-satellite',
    clusterName: 'fake-cluster',
}" \
monitoring-satellite/manifests/rules.jsonnet | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml' -- {}

# Make sure to remove json files
find monitoring-satellite/manifests -type f ! -name '*.yaml' ! -name '*.jsonnet'  -delete
find monitoring-central/manifests -type f ! -name '*.yaml' ! -name '*.jsonnet'  -delete
