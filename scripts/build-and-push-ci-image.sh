#!/bin/bash

# Build and push specialized Gecko CI Docker images to Docker Hub
# Usage: ./scripts/build-and-push-ci-image.sh [image-name]
# Examples:
#   ./scripts/build-and-push-ci-image.sh          # Build all images
#   ./scripts/build-and-push-ci-image.sh android   # Build only android image
#   ./scripts/build-and-push-ci-image.sh format    # Build only format image
#
# Multi-arch images (linux) are built for both amd64 and arm64.
# Other images are built for the host architecture only.

set -e

REPO="poka"
IMAGES=("format" "android" "linux" "deploy" "publish")

# Images that need multi-arch builds (used by runners of different architectures)
MULTIARCH_IMAGES=("linux")

is_multiarch() {
    local name="$1"
    for ma in "${MULTIARCH_IMAGES[@]}"; do
        if [ "$ma" = "$name" ]; then
            return 0
        fi
    done
    return 1
}

ensure_buildx_builder() {
    if ! docker buildx inspect gecko-multiarch &>/dev/null; then
        echo "Creating buildx builder 'gecko-multiarch'..."
        docker buildx create --name gecko-multiarch --use
    else
        docker buildx use gecko-multiarch
    fi
}

build_and_push() {
    local name="$1"
    local image="${REPO}/gecko-ci-${name}"
    local dockerfile="docker/${name}.Dockerfile"

    if [ ! -f "$dockerfile" ]; then
        echo "Error: $dockerfile not found"
        exit 1
    fi

    if is_multiarch "$name"; then
        echo "Building ${image} (multi-arch: amd64 + arm64)..."
        ensure_buildx_builder
        docker buildx build \
            --platform linux/amd64,linux/arm64 \
            --provenance=false \
            -f "$dockerfile" \
            -t "${image}:latest" \
            --push \
            .
    else
        echo "Building ${image}..."
        local provenance_flag=""
        if docker buildx version &>/dev/null; then
            provenance_flag="--provenance=false"
        fi
        docker build $provenance_flag -f "$dockerfile" -t "${image}:latest" .
        docker push "${image}:latest"
    fi

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
