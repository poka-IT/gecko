#!/bin/bash

# Script to build and push multi-architecture Docker image for Gecko Linux builds
# Usage: ./scripts/build-docker-linux.sh <version>
# Example: ./scripts/build-docker-linux.sh 1.2.3

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if version argument is provided
if [ $# -ne 1 ]; then
    echo -e "${RED}❌ Error: Version number is required${NC}"
    echo -e "${YELLOW}Usage: $0 <version>${NC}"
    echo -e "${YELLOW}Example: $0 1.2.3${NC}"
    exit 1
fi

VERSION=$1
IMAGE_NAME="poka/gecko-linux-builder"
DOCKERFILE_PATH="Dockerfile.linux"

# Validate version format (basic semver check)
if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}❌ Error: Invalid version format. Use semantic versioning (e.g., 1.2.3)${NC}"
    exit 1
fi

echo -e "${BLUE}🐳 Building multi-architecture Docker image for Gecko Linux builder${NC}"
echo -e "${BLUE}📦 Image: ${IMAGE_NAME}:${VERSION}${NC}"
echo -e "${BLUE}🏗️  Dockerfile: ${DOCKERFILE_PATH}${NC}"

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: Docker is not running${NC}"
    exit 1
fi

# Check if buildx is available
if ! docker buildx version >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: Docker buildx is not available${NC}"
    exit 1
fi

# Check if Dockerfile exists
if [ ! -f "$DOCKERFILE_PATH" ]; then
    echo -e "${RED}❌ Error: Dockerfile not found at ${DOCKERFILE_PATH}${NC}"
    exit 1
fi

# Login to Docker Hub (will prompt for credentials if not logged in)
echo -e "${YELLOW}🔐 Checking Docker Hub authentication...${NC}"
if ! docker info | grep -q "Username:"; then
    echo -e "${YELLOW}Please login to Docker Hub:${NC}"
    docker login
fi

# Create and use buildx builder if it doesn't exist
BUILDER_NAME="gecko-multiarch-builder"
if ! docker buildx ls | grep -q "$BUILDER_NAME"; then
    echo -e "${YELLOW}🔧 Creating multi-architecture builder...${NC}"
    docker buildx create --name "$BUILDER_NAME" --driver docker-container --bootstrap
fi

echo -e "${YELLOW}🔧 Using builder: ${BUILDER_NAME}${NC}"
docker buildx use "$BUILDER_NAME"

# Build and push multi-architecture image
echo -e "${GREEN}🚀 Building and pushing multi-architecture image...${NC}"
echo -e "${BLUE}Platforms: linux/amd64, linux/arm64${NC}"

docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --tag "${IMAGE_NAME}:${VERSION}" \
    --tag "${IMAGE_NAME}:latest" \
    --file "$DOCKERFILE_PATH" \
    --push \
    .

# Verify the push
echo -e "${GREEN}✅ Build and push completed successfully!${NC}"
echo -e "${BLUE}📋 Image details:${NC}"
echo -e "   🏷️  Tagged as: ${IMAGE_NAME}:${VERSION}"
echo -e "   🏷️  Tagged as: ${IMAGE_NAME}:latest"
echo -e "   🌍 Platforms: linux/amd64, linux/arm64"
echo -e "   🔗 Docker Hub: https://hub.docker.com/r/${IMAGE_NAME}"

# Show image manifest (optional verification)
echo -e "${YELLOW}🔍 Verifying multi-architecture manifest...${NC}"
docker buildx imagetools inspect "${IMAGE_NAME}:${VERSION}" || true

echo -e "${GREEN}🎉 All done! Your multi-architecture image is ready to use.${NC}"
echo -e "${BLUE}💡 To use in CI: docker run --rm ${IMAGE_NAME}:${VERSION}${NC}"
