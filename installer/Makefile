all: build

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