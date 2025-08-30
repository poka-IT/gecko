#!/bin/bash

set -e

# Get current directory (should be gecko root)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Get version with build number from pubspec.yaml
VERSION=$(grep "version:" "$REPO_DIR/pubspec.yaml" | cut -d ":" -f2 | tr -d " ")

# Check if version was found
if [[ ! $VERSION ]]; then
    echo "Error: Could not find version in pubspec.yaml"
    exit 1
fi

echo "Found version: $VERSION"

# Navigate to repo directory
cd "$REPO_DIR"

# Check if tag already exists
if git tag -l "v$VERSION" | grep -q "v$VERSION"; then
    echo "Tag v$VERSION already exists"
    exit 1
fi

# Get the last version tag for changelog
LAST_VERSION=$(git tag | grep '^v' | sort -V | tail -1)

if [[ $LAST_VERSION ]]; then
    # Generate tag message with commits since last version
    TAG_MESSAGE="$(git log --pretty='format:- %s ([%h](https://git.duniter.org/clients/gecko/-/commit/%h)) ' HEAD...$LAST_VERSION --no-merges --reverse)"
else
    # If no previous tag, just use a simple message
    TAG_MESSAGE="Initial release"
fi

# Create and push the tag
echo "Creating tag v$VERSION..."
git tag -a "v$VERSION" -m "$TAG_MESSAGE"

echo "Pushing tag v$VERSION..."
git push --tags

echo "✅ Tag v$VERSION created and pushed successfully!"
echo "GitLab: https://git.duniter.org/clients/gecko/-/tags/v$VERSION"
