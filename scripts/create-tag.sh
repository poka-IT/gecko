#!/bin/bash

set -e

# Get current directory (should be gecko root)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Parse arguments
BETA_MODE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --beta|-b)
            BETA_MODE="true"
            shift
            ;;
        --help|-h)
            echo "Create and push a version tag from pubspec.yaml"
            echo ""
            echo "USAGE:"
            echo "  $0              Create production tag (v1.1.4)"
            echo "  $0 --beta       Create beta tag (v1.1.4-beta)"
            echo "  $0 -b           Create beta tag (short form)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1 (use --help)"
            exit 1
            ;;
    esac
done

# Extract version (without build number) from pubspec.yaml
FULL_VERSION=$(grep "version:" "$REPO_DIR/pubspec.yaml" | cut -d ":" -f2 | tr -d " ")
VERSION_ONLY=$(echo "$FULL_VERSION" | cut -d "+" -f1)

if [[ ! $VERSION_ONLY ]]; then
    echo "Error: Could not find version in pubspec.yaml"
    exit 1
fi

# Build tag name
if [ "$BETA_MODE" = "true" ]; then
    TAG_NAME="v${VERSION_ONLY}-beta"
else
    TAG_NAME="v${VERSION_ONLY}"
fi

echo "pubspec.yaml version: $FULL_VERSION"
echo "Tag to create: $TAG_NAME"

# Navigate to repo directory
cd "$REPO_DIR"

# Check if tag already exists
if git tag -l "$TAG_NAME" | grep -q "$TAG_NAME"; then
    echo "Error: Tag $TAG_NAME already exists"
    exit 1
fi

# Get the last version tag for changelog
LAST_VERSION=$(git tag --sort=-v:refname | head -1)

if [[ $LAST_VERSION ]]; then
    TAG_MESSAGE="$(git log --pretty='format:- %s ([%h](https://git.duniter.org/clients/gecko/-/commit/%h)) ' HEAD...$LAST_VERSION --no-merges --reverse)"
else
    TAG_MESSAGE="Initial release"
fi

# Create and push the tag
echo "Creating tag $TAG_NAME..."
git tag -a "$TAG_NAME" -m "$TAG_MESSAGE"

echo "Pushing tag $TAG_NAME..."
git push --tags

echo "Tag $TAG_NAME created and pushed successfully!"
echo "GitLab: https://git.duniter.org/clients/gecko/-/tags/$TAG_NAME"
