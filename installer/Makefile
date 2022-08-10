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

monitoring-satellite.yaml: generate

generate: installer
	./installer init > config.yaml
	./installer render --config config.yaml > monitoring-satellite.yaml

.PHONY: deploy-satellite
apply-satellite: monitoring-satellite.yaml
	kubectl create ns monitoring-satellite || true
	kubectl apply -f monitoring-satellite.yaml