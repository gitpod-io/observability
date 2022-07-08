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
        pagerdutyRoutingKey: 'global-pd-routing-key',

        IDE: {
            pagerdutyRoutingKey: 'fake-pd-key',
            slackWebhookURL: 'https://hooks.slack.com/services/fake-url',
        },
        webapp: {
            pagerdutyRoutingKey: 'fake-pd-key',
            slackWebhookURL: 'https://hooks.slack.com/services/fake-url',
        },
        platform: {
            pagerdutyRoutingKey: 'fake-pd-key',
            slackWebhookURL: 'https://hooks.slack.com/services/fake-url',
        },
        workspace: {
            pagerdutyRoutingKey: 'fake-pd-key',
            slackWebhookURL: 'https://hooks.slack.com/services/fake-url',
        },

        generic: {
            name:            'generic',
            slackWebhookURL: 'https://hooks.slack.com/services/fake-url',
        },
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
        BasicAuthSecretBase64: 'NGI5ZDlmOTQ3MTU1ODFmZWQwYzc6JGFwcjEkdDd5V2IxcXUkMU9na21JMzB4RW5SNHRiQUkwaFF5MA==',
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
    pyrra: {
        prometheusURL: 'http://victoriametrics.monitoring-central.svc.cluster.local:8428',
        DNS: 'http://fake.pyrra.url',
        nodePort: 32164,
        GCPExternalIpAddress: 'fake_external_ip_address',
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
