#!/bin/bash

# Build and push specialized Gecko CI Docker images to Docker Hub
# Usage: ./scripts/build-and-push-ci-image.sh [image-name]
# Examples:
#   ./scripts/build-and-push-ci-image.sh          # Build all images
#   ./scripts/build-and-push-ci-image.sh android   # Build only android image
#   ./scripts/build-and-push-ci-image.sh format    # Build only format image

set -e

REPO="poka"
IMAGES=("format" "android" "deploy" "publish")

build_and_push() {
    local name="$1"
    local image="${REPO}/gecko-ci-${name}"
    local dockerfile="docker/${name}.Dockerfile"

    if [ ! -f "$dockerfile" ]; then
        echo "Error: $dockerfile not found"
        exit 1
    fi

    echo "Building ${image}..."
    docker build --provenance=false -f "$dockerfile" -t "${image}:latest" .
    docker push "${image}:latest"
    echo "Pushed ${image}:latest"
    echo ""
}

if [ -n "$1" ]; then
    build_and_push "$1"
else
    for img in "${IMAGES[@]}"; do
        build_and_push "$img"
    done
fi

echo "Done!"
