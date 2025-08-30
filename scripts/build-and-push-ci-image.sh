#!/bin/bash

# Script to build and push Gecko CI Docker image to Docker Hub
# Usage: ./scripts/build-and-push-ci-image.sh <version>
# Example: ./scripts/build-and-push-ci-image.sh 1.0.0

set -e

# Check if version argument is provided
if [ -z "$1" ]; then
    echo "❌ Error: Version number is required"
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.0"
    exit 1
fi

VERSION="$1"
IMAGE_NAME="poka/gecko-ci"
FULL_IMAGE_NAME="${IMAGE_NAME}:${VERSION}"
LATEST_IMAGE_NAME="${IMAGE_NAME}:latest"

echo "🐳 Building Gecko CI Docker image..."
echo "📦 Image: ${FULL_IMAGE_NAME}"
echo "📦 Latest: ${LATEST_IMAGE_NAME}"

# Build the Docker image using buildx for multi-platform support
echo "🔨 Building Docker image..."
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    -f Dockerfile.ci \
    -t "${FULL_IMAGE_NAME}" \
    -t "${LATEST_IMAGE_NAME}" \
    --push \
    .

echo "✅ Docker image built and pushed successfully!"
echo "🚀 Image available at: https://hub.docker.com/r/${IMAGE_NAME}"
echo ""
echo "📋 To use this image in CI, update your .gitlab-ci.yml with:"
echo "   image: ${FULL_IMAGE_NAME}"
echo "   or"
echo "   image: ${LATEST_IMAGE_NAME}"
echo ""

# Update the GitLab CI configuration
echo "🔧 Updating .gitlab-ci.yml to use the new image..."

# Replace gecko-ci:latest with the Docker Hub image
sed -i.backup "s|gecko-ci:latest|${LATEST_IMAGE_NAME}|g" .gitlab-ci.yml

echo "✅ GitLab CI configuration updated!"
echo "📝 Backup saved as .gitlab-ci.yml.backup"
echo ""
echo "🎉 All done! Your CI will now use the optimized Docker image from Docker Hub."
