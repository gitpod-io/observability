all: installer monitoring-satellite.yaml

installer: build

build: lint
	CGO_ENABLED=0 go build .

# Run code linters
lint: fmt vet

# Run go fmt against code
fmt:
	go fmt ./...

# Run go vet against code
vet:
	go vet ./...

monitoring-satellite.yaml: generate-full

generate: installer
	./installer init > examples/default-config.yaml
	./installer render --config examples/default-config.yaml --app monitoring-satellite > monitoring-satellite.yaml

generate-full: installer
	./installer render --config examples/full-config.yaml --app monitoring-satellite > monitoring-satellite.yaml

.PHONY: deploy-satellite
apply-satellite: monitoring-satellite.yaml
	kubectl create ns monitoring-satellite || true
	kubectl apply -f monitoring-satellite.yaml
