#!/usr/bin/env bash

set -e
set -x
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

# Make sure to use project tooling
PATH="$(pwd)/tmp/bin:${PATH}"


[[ ! -e diff ]] || rm -rf diff

# Generate monitoring-satellite YAML files
jsonnet -c -J vendor -m diff/jsonnet-tmp \
--ext-code config="{
    namespace: 'monitoring-satellite',
    clusterName: 'fake-cluster',
    alerting: {
        pagerdutyRoutingKey: 'pd-routing-key',
        slackOAuthToken: 'fake-key',

        ide: {},
        webapp: {},
        platform: {},
        workspace: {},

        generic: {
            slackChannel: '#a_generic_channel',
        }
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
monitoring-satellite/manifests/yaml-generator.jsonnet | xargs -I{} sh -c 'cat {} | gojsontoyaml >> diff/jsonnet-unsorted.yaml; echo "---" >> diff/jsonnet-unsorted.yaml' -- {}
rm -rf diff/jsonnet-tmp

function normalize() {
    IN=$1
    OUT=$2

    # ensure directory exists and is empty
    [[ ! -e "$OUT" ]] || rm -rf "$OUT"
    mkdir -p "$OUT"

    # iterate through all documents from the YAML
    documentIndex=0
    while [ ! -z $(yq e "select(documentIndex == $documentIndex) | .apiVersion" $IN) ]; do

        # extract the component name from the label. If the label is not set, the result will be 'null'.
        COMP=$(yq e "select(documentIndex == $documentIndex) | .metadata.labels.\"app.kubernetes.io/component\"" $IN)
        TMP="$OUT/$COMP.tmp"

        # add a YAML document separator ("---") to the file if the file already exists.
        [[ ! -e "$TMP" ]] || echo "---" >> "$TMP"

        # extract the document from the large input file and append it to the file that's named after the component.
        yq e "select(documentIndex == $documentIndex)" $IN >> "$TMP"

        documentIndex=$((documentIndex + 1))
    done

    # sort the documents in the YAML by .kind (first) and .metadata.name. (second)
    for I in `find $OUT -iname *.tmp`; do
        yq ea '[.] | sort_by(.kind + .metadata.name) | .[] | splitDoc' $I > ${I/tmp/yaml}
    done

    # delete TMP files.
    rm $OUT/*.tmp
}

normalize diff/jsonnet-unsorted.yaml diff/jsonnet

#####  go-based installer

(cd installer/; go run main.go render -c - <<< "
alerting:
  config: {}
gitpod:
  installServiceMonitors: true
namespace: monitoring-satellite
prober:
  install: false
pyrra:
  install: false
tracing:
  install: false
werft:
  installServiceMonitors: false
prometheus:
  enableFeatures: 
    - foo
") > diff/go-unsorted.yaml

normalize diff/go-unsorted.yaml diff/go
