#!/bin/bash
# [[ -z $1 ]] && echo "Please choose a version." && exit 1

fVersion=$(grep "version: " pubspec.yaml | awk '{ print $2 }')

withPush=$1

APPNAME="gecko"
VERSION=$(awk -F '+' '{ print $1 }' <<<$fVersion)
BUILD=$(awk -F '+' '{ print $2 }' <<<$fVersion)
ori_app="app.apk"

echo "Nom du build final: ${APPNAME}-${VERSION}+${BUILD}.apk"

## To build Rust dependancies
# cargo br

flutter clean
if [[ $1 == "bundle" ]]; then
	flutter build appbundle --release --target-platform android-arm,android-arm64 --build-name $VERSION --build-number $BUILD
else
#	flutter build apk --release --split-per-abi --target-platform android-arm,android-arm64 --build-name $VERSION --build-number $BUILD
	flutter build apk --release --split-per-abi --build-name $VERSION --build-number $BUILD
#	flutter build apk --release --build-name $VERSION --build-number $BUILD
fi

if [[ -d $HOME/kDrive/Gecko-APK ]]; then
    DL="$HOME/kDrive/Gecko-APK"
elif [[ -d $HOME/Téléchargements ]]; then
    DL="$HOME/Téléchargements"
elif [[ -d $HOME/Downloads ]]; then
    DL="$HOME/Downloads"
else
    DL="/tmp"
fi

appPath="$DL/${APPNAME}-${VERSION}+${BUILD}.apk"
mv build/app/outputs/flutter-apk/$ori_app "$appPath" && echo "$appPath" || exit 1

[[ $withPush == "withPush" ]] && /home/poka/scripts/link/pushGecko $VERSION

exit 0
