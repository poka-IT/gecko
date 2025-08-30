#!/bin/bash

# Helper script to create a new release tag and trigger CI/CD pipeline
# Usage: ./scripts/create-release.sh [version] [--push]

set -e

# Function to show usage
show_usage() {
    echo "Usage: $0 [version] [--push]"
    echo ""
    echo "Creates a new release tag for Gecko"
    echo ""
    echo "Arguments:"
    echo "  version    Version number (e.g., 1.2.3). If not provided, extracts from pubspec.yaml"
    echo "  --push     Automatically push the tag to trigger CI/CD"
    echo ""
    echo "Examples:"
    echo "  $0                    # Use version from pubspec.yaml"
    echo "  $0 1.2.3              # Create tag v1.2.3"
    echo "  $0 1.2.3 --push       # Create and push tag v1.2.3"
}

# Parse arguments
VERSION=""
PUSH_TAG=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --push)
            PUSH_TAG=true
            shift
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            if [ -z "$VERSION" ]; then
                VERSION=$1
            else
                echo "Error: Unknown argument '$1'"
                show_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# If no version provided, extract from pubspec.yaml
if [ -z "$VERSION" ]; then
    if [ ! -f "pubspec.yaml" ]; then
        echo "Error: pubspec.yaml not found. Are you in the project root?"
        exit 1
    fi
    
    FULL_VERSION=$(grep "version: " pubspec.yaml | awk '{ print $2 }')
    VERSION=$(echo $FULL_VERSION | awk -F '+' '{ print $1 }')
    BUILD=$(echo $FULL_VERSION | awk -F '+' '{ print $2 }')
    
    echo "Extracted version from pubspec.yaml: ${VERSION}+${BUILD}"
fi

# Validate version format
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid version format. Expected: X.Y.Z (e.g., 1.2.3)"
    exit 1
fi

TAG_NAME="v${VERSION}"

# Check if tag already exists
if git tag | grep -q "^${TAG_NAME}$"; then
    echo "Error: Tag ${TAG_NAME} already exists"
    echo ""
    echo "Existing tags:"
    git tag --sort=-v:refname | head -10
    exit 1
fi

# Ensure working directory is clean
if [ -n "$(git status --porcelain)" ]; then
    echo "Error: Working directory is not clean. Commit or stash your changes first."
    git status --short
    exit 1
fi

# Create the tag
echo "Creating tag ${TAG_NAME}..."
git tag -a "${TAG_NAME}" -m "Release ${VERSION}"

echo "✅ Tag ${TAG_NAME} created successfully"

# Show tag info
echo ""
echo "Tag information:"
git show "${TAG_NAME}" --no-patch

# Push if requested
if [ "$PUSH_TAG" = true ]; then
    echo ""
    echo "Pushing tag to origin..."
    git push origin "${TAG_NAME}"
    echo "✅ Tag pushed successfully"
    echo ""
    echo "🚀 CI/CD pipeline should start automatically at:"
    echo "   ${CI_PROJECT_URL:-https://gitlab.com/your-project}/-/pipelines"
else
    echo ""
    echo "📝 To push this tag and trigger CI/CD, run:"
    echo "   git push origin ${TAG_NAME}"
fi

# Show next steps
echo ""
echo "📋 Next steps after CI/CD completes:"
echo "   1. Check the pipeline status"
echo "   2. Manually trigger Play Store deployment (if needed)"
echo "   3. Manually trigger App Store deployment (if needed)"
echo "   4. Manually trigger forum announcement (if needed)"
echo "   5. Verify the GitLab release page"

# Optional: Open GitLab pipelines page
if command -v xdg-open >/dev/null 2>&1; then
    echo ""
    read -p "Open GitLab pipelines page in browser? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        xdg-open "${CI_PROJECT_URL:-https://gitlab.com/your-project}/-/pipelines"
    fi
elif command -v open >/dev/null 2>&1; then
    echo ""
    read -p "Open GitLab pipelines page in browser? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open "${CI_PROJECT_URL:-https://gitlab.com/your-project}/-/pipelines"
    fi
fi
