#!/usr/bin/env bash

set -e
set -x
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

# Make sure to use project tooling
PATH="$(pwd)/tmp/bin:${PATH}"

# Generate monitoring-satellite YAML files
jsonnet -c -J vendor -m monitoring-satellite/manifests \
--ext-code config="{
    namespace: 'monitoring-satellite',
    # clusterName: 'fake-cluster',
    nodeAffinity: {
        nodeSelector: {
            'gitpod.io/workload_services': 'true',
            'kubernetes.io/os': 'linux',
        },
    },
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
        issuer: 'issuer-123',
    },
    victoriametrics: {
        DNS: 'http://fake.victoriametrics.url',
        authKey: 'random-key',
        username: 'p@ssW0rd',
        password: 'user',
        GCPExternalIpAddress: 'fake_external_ip_address',
        issuer: 'issuer-123',
        cpu: 5,
        memory: '20Gi',
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
        IAPClientID: 'fakeIAP_ID',
        IAPClientSecret: 'fakeIAP_secret',
    },
}" \
monitoring-central/manifests/yaml-generator.jsonnet | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml' -- {}

# Generate monitoring-satellite prometheus rules
jsonnet -c -J vendor -m monitoring-satellite/manifests \
--ext-code config="{}" \
monitoring-satellite/manifests/rules.jsonnet | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml' -- {}

# Make sure to remove json files
find monitoring-satellite/manifests -type f ! -name '*.yaml' ! -name '*.jsonnet'  -delete
find monitoring-central/manifests -type f ! -name '*.yaml' ! -name '*.jsonnet'  -delete
