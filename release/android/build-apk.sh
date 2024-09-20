#!/bin/bash

if [[ -z "${1}" ]]; then
	echo "Fatal: no version given to build script"
	exit 1
fi

APPNAME="gecko"
VERSION=$(awk -F '+' '{ print $1 }' <<<${1})
BUILD=$(awk -F '+' '{ print $2 }' <<<${1})
ORI_APP="app-arm64-v8a-release.apk"
APK_FILENAME="${APPNAME}-${VERSION}+${BUILD}.apk"

echo "artifact name: ${APK_FILENAME}"

# Build APK
echo "Build APK..."
#flutter clean
flutter build apk --release --build-name $VERSION --build-number $BUILD

# Create artifacts folder
ARTIFACTS_FOLDER="work/bin"
mkdir -p ${ARTIFACTS_FOLDER}

# Move APK in artifacts folder
APK_PATH="${ARTIFACTS_FOLDER}/${APK_FILENAME}"
mv build/app/outputs/flutter-apk/$ORI_APP "$APK_PATH" || exit 1

exit 0
