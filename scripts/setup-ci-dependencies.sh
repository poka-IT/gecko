#!/bin/bash

# Script to setup dependencies for CI environment
# Removes local path overrides to use pub.dev versions

set -e

echo "🔧 Setting up dependencies for CI environment..."

# Check if we're in CI environment
if [ "$CI" = "true" ]; then
    echo "📦 CI detected - removing local path overrides"
    
    # Remove the local durt2 override from dependency_overrides section
    # This will make it fall back to the pub.dev version in dependencies
    sed -i.backup \
        -e '/# Local development override - use local durt2 when available/,+2d' \
        pubspec.yaml
    
    echo "✅ Local overrides removed - using pub.dev dependencies"
    echo "📋 Remaining dependency_overrides:"
    sed -n '/dependency_overrides:/,/^[a-zA-Z]/p' pubspec.yaml | head -n -1
else
    echo "🏠 Local environment detected - keeping local overrides"
fi

echo "🚀 Running flutter pub get..."
flutter pub get
