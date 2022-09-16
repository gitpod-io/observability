#!/bin/bash

# shellcheck disable=SC2034

set -euo pipefail

SCRIPT_PATH=$(realpath "$(dirname "$0")")
PROJECT_ROOT=$(realpath "${SCRIPT_PATH}/../")

INSTALLER_DIR="${PROJECT_ROOT}/installer"
BINARY_NAME="obs-installer"

if [ -z ${VERSION+x} ]; then
  echo "Must supply VERSION"
fi

pushd "${INSTALLER_DIR}"

for GOOS in darwin linux; do
  for GOARCH in arm64 amd64; do
    export GOOS=$GOOS
    export GOARCH=$GOARCH

    RELEASE_NAME="${BINARY_NAME}_${VERSION}_${GOOS}_${GOARCH}.tar.gz"
    echo "Building ${RELEASE_NAME}"

    go build -o ${BINARY_NAME} .
    tar cf "${RELEASE_NAME}" ${BINARY_NAME}
    rm "${BINARY_NAME}"
  done
done

popd
