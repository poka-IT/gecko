#!/bin/bash

set -e

fVersion=$(grep "version: " pubspec.yaml | awk '{ print $2 }')

withPush=$1

APPNAME="gecko"
VERSION=$(awk -F '+' '{ print $1 }' <<<$fVersion)
BUILD=$(awk -F '+' '{ print $2 }' <<<$fVersion)
v7_app="app-armeabi-v7a-release.apk"
v8_app="app-arm64-v8a-release.apk"
x86_64_app="app-x86_64-release.apk"

echo "Nom du build final: ${APPNAME}-${VERSION}+${BUILD}.apk"
[[ $withPush == "withPush" ]] && echo "Publish after build"

## To build Rust dependancies
# cargo br

fvm flutter clean
fvm flutter pub get
if [[ $1 == "bundle" ]]; then
	fvm flutter build appbundle --release --build-name $VERSION --build-number $BUILD
	exit 0
else
#	fvm flutter build apk --release --split-per-abi --target-platform android-arm,android-arm64 --build-name $VERSION --build-number $BUILD
	fvm flutter build apk --release --split-per-abi --build-name $VERSION --build-number $BUILD
#	fvm flutter build apk --release --build-name $VERSION --build-number $BUILD
fi

DL="/tmp"
appPathV7="$DL/${APPNAME}-${VERSION}+${BUILD}-v7a.apk"
appPathV8="$DL/${APPNAME}-${VERSION}+${BUILD}-v8a.apk"
appPathX84_64="$DL/${APPNAME}-${VERSION}+${BUILD}-x86_64.apk"
mv build/app/outputs/flutter-apk/$v7_app "$appPathV7" || exit 1
mv build/app/outputs/flutter-apk/$v8_app "$appPathV8" || exit 1
mv build/app/outputs/flutter-apk/$x86_64_app "$appPathX84_64" || exit 1

[[ $withPush == "withPush" ]] && /home/poka/scripts/link/pushGecko $VERSION+$BUILD

exit 0
