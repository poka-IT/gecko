#!/bin/bash

set -e

# Function to clean up Info.plist
cleanup() {
    echo "Cleaning up Info.plist..."
    git checkout ios/Runner/Info.plist
}

# Trap ERR and EXIT signals to ensure cleanup
trap cleanup ERR EXIT

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | sed 's/#.*//g' | xargs)
else
    echo "Please create a .env file with required credentials"
    exit 1
fi

# Get version from pubspec.yaml
fVersion=$(grep "version: " pubspec.yaml | awk '{ print $2 }')
VERSION=$(awk -F '+' '{ print $1 }' <<<$fVersion)
BUILD=$(awk -F '+' '{ print $2 }' <<<$fVersion)

echo "Building Gecko iOS v${VERSION}+${BUILD}"

# Temporarily replace build name and number in Info.plist
echo "Updating Info.plist with version ${VERSION} and build number ${BUILD}"
sed -i '' "s|\$(FLUTTER_BUILD_NAME)|${VERSION}|g" ios/Runner/Info.plist
sed -i '' "s|\$(FLUTTER_BUILD_NUMBER)|${BUILD}|g" ios/Runner/Info.plist

# get dependencies
fvm flutter pub get

# Build iOS archive
fvm flutter build ipa \
    --release \
    --build-name=$VERSION \
    --build-number=$BUILD \
    --export-options-plist=ios/ExportOptions.plist

# Path to the built IPA
IPA_PATH="build/ios/ipa/gecko.ipa"
if [ ! -f "$IPA_PATH" ]; then
    echo "IPA file not found at $IPA_PATH"
    exit 1
fi

# Upload to App Store using altool
echo "Uploading to App Store..."
xcrun altool --upload-app \
    --type ios \
    --file "$IPA_PATH" \
    --username "$APPLE_ID" \
    --password "$APP_SPECIFIC_PASSWORD" \
    --bundle-id "$BUNDLE_ID"

if [ $? -eq 0 ]; then
    echo "Successfully uploaded to App Store"
else
    echo "Failed to upload to App Store"
    exit 1
fi
