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

# Images that need multi-arch builds (used by runners of different architectures).
# Everything except "android" is built for amd64 + arm64 so the images run on CI
# runners and local dev machines of either architecture. "android" is intentionally
# excluded: it is pinned to linux/amd64 (Flutter ships no gen_snapshot for
# linux-arm64 Android targets — see docker/android.Dockerfile).
MULTIARCH_IMAGES=("format" "linux" "deploy" "publish")

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
        # Push architecture-specific tags for explicit use in CI
        for plat in linux/amd64 linux/arm64; do
            arch_tag="${plat#linux/}"
            echo "  Building ${image}:${arch_tag}..."
            docker buildx build \
                --platform "$plat" \
                --provenance=false \
                -f "$dockerfile" \
                -t "${image}:${arch_tag}" \
                --push \
                .
        done
        # Also push multi-arch :latest manifest
        docker buildx build \
            --platform linux/amd64,linux/arm64 \
            --provenance=false \
            -f "$dockerfile" \
            -t "${image}:latest" \
            --push \
            .
    else
        # Single-arch image (currently only "android"): pinned to linux/amd64
        # because Flutter ships no gen_snapshot for linux-arm64 Android targets.
        # Built via buildx and pushed directly so it works regardless of which
        # buildx builder is active (the docker-container builder used for the
        # multi-arch images does not load into the local image store).
        echo "Building ${image} (linux/amd64)..."
        ensure_buildx_builder
        docker buildx build \
            --platform linux/amd64 \
            --provenance=false \
            -f "$dockerfile" \
            -t "${image}:latest" \
            --push \
            .
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
