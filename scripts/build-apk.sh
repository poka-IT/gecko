#!/bin/bash

[[ -z $1 ]] && echo "Please choose a version." && exit 1

flutter build apk --split-per-abi

APPNAME="gecko"
VERSION="$1"
ori_app="app.apk"

if [[ -d $HOME/Téléchargements ]]; then
    DL="$HOME/Téléchargements"
elif [[ -d $HOME/Downloads ]]; then
    DL="$HOME/Downloads"
else
    DL="/tmp"
fi

appPath="$DL/${APPNAME}-${VERSION}.apk"
mv build/app/outputs/flutter-apk/$ori_app "$appPath" && echo "$appPath" || exit 1

exit 0
