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
      },
      kubescape: {},
      pyrra: {},
      probe: {
        targets: ['http://google.com'],
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
    },
    prometheus: {
        externalLabels: {
            environment: 'test',
        },
        DNS: 'prometheus.fake.dns.com',
        nodePort: 32164,
        GCPExternalIpAddress: 'external-ip-name',
        BasicAuthSecret: '4b9d9f94715581fed0c7:$apr1$t7yWb1qu$1OgkmI30xEnR4tbAI0hQy0',
        enableFeatures: ['remote-write-receiver'],
    },
    remoteWrite: {
        username: 'user',
        password: 'p@ssW0rd',
        urls: ['http://victoriametrics.monitoring-central.svc:8480/insert/0/prometheus'],
        writeRelabelConfigs: [
          {
            sourceLabels: ['__name__'],
            targetLabel: '__name__',
            regex: 'up',
            action: 'replace',
            replacement: 'relabeled_up'
          }
        ],
    },
    previewEnvironment: {
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
    },
    stackdriver: {
        clientEmail: 'fake@email.com',
        defaultProject: 'google-project',
        privateKey: 
|||
  multiline
  fake
  key
|||,
    },
    kubescape: {},
    pyrra: {},
    probe: {
        targets: ['http://google.com'],
    },
}" \
monitoring-satellite/manifests/yaml-generator.jsonnet | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml' -- {}

# Generate monitoring-central YAML files
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
    stackdriver: {
        clientEmail: 'fake@email.com',
        defaultProject: 'google-project',
        privateKey: 
|||
  multiline
  fake
  key
|||,
    },
}" \
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
