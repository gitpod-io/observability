BIN_DIR?=$(shell pwd)/tmp/bin
JB_BIN=$(BIN_DIR)/jb
GOJSONTOYAML_BIN=$(BIN_DIR)/gojsontoyaml
JSONNET_BIN=$(BIN_DIR)/jsonnet
JSONNETFMT_BIN=$(BIN_DIR)/jsonnetfmt
TOOLING=$(JSONNETFMT_BIN) $(JSONNET_BIN) $(GOJSONTOYAML_BIN) $(JB_BIN)

JSONNET_FMT := $(JSONNETFMT_BIN) -n 2 --max-blank-lines 2 --string-style s --comment-style s

all: fmt lint generate

.PHONY: clean
clean:
    # Delete files marked in .gitignore
	git clean -Xfd .

.PHONY: generate
generate: $(JSONNET_BIN)
	./hack/generate.sh

.PHONY: generate-ci
generate-ci: $(JSONNET_BIN)
	./hack/generate.sh -e CI

.PHONY: fmt
fmt: $(JSONNETFMT_BIN)
	find . -name 'vendor' -prune -o -name '*.libsonnet' -print -o -name '*.jsonnet' -print | \
		xargs -n 1 -- $(JSONNET_FMT) -i

.PHONY: lint
lint: $(JSONNETFMT_BIN)
	find . -name 'vendor' -prune -o -name '*.libsonnet' -print -o -name '*.jsonnet' -print | \
		while read f; do \
			$(JSONNET_FMT) "$$f" | diff -u "$$f" -; \
		done

.PHONY: promtool-lint
promtool-lint:
	promtool check rules monitoring-satellite/manifests/ci_prometheus_rules.yaml

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(TOOLING): $(BIN_DIR)
	@echo Installing tools from tools.go
	@cd hack && cat tools.go | grep _ | awk -F'"' '{print $$2}' | xargs -tI % go build -modfile=go.mod -o $(BIN_DIR) %

.PHONY: update
update: $(JB_BIN)
	$(JB_BIN) update

.PHONY: deploy-satellite
deploy-satellite: generate
	./hack/prepare-kind.sh
	./hack/deploy-satellite.sh

.PHONY: deploy-satellite-go
deploy-satellite-go: generate
	./hack/prepare-kind.sh
	./hack/deploy-crds.sh
	@cd installer && $(MAKE) apply-satellite

.PHONY: deploy-central
deploy-central: generate
	./hack/prepare-kind.sh
	./hack/deploy-central.sh

.PHONY: test-e2e
test-e2e:
	@cd tests/e2e && go test -timeout 55m -v . -count=1
