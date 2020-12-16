#!/bin/bash

# [[ -z $1 ]] && echo "Please choose a version." && exit 1

fVersion=$(grep "version: " pubspec.yaml | awk '{ print $2 }')

APPNAME="gecko"
VERSION=$(awk -F '+' '{ print $1 }' <<<$fVersion)
BUILD=$(awk -F '+' '{ print $2 }' <<<$fVersion)
ori_app="app.apk"

echo "Nom du build final: ${APPNAME}-${VERSION}+${BUILD}.apk"

flutter build apk --split-per-abi --build-name $VERSION --build-number $BUILD

if [[ -d $HOME/Téléchargements ]]; then
    DL="$HOME/Téléchargements"
elif [[ -d $HOME/Downloads ]]; then
    DL="$HOME/Downloads"
else
    DL="/tmp"
fi

appPath="$DL/${APPNAME}-${VERSION}+${BUILD}.apk"
mv build/app/outputs/flutter-apk/$ori_app "$appPath" && echo "$appPath" || exit 1

exit 0
