#!/bin/bash

flutter build apk --split-per-abi

APPNAME = "gecko"
VERSION="dev1"
ori_app="app.apk"

if [[ -d $HOME/Téléchargements ]]; then
    DL="$HOME/Téléchargements"
elif [[ -d $HOME/Downloads ]]; then
    DL="$HOME/Downloads"
else
    DL="/tmp"
fi

mv build/app/outputs/flutter-apk/$ori_app "$DL/gecko-$VERSION" && echo "L'app se trouve ici: $DL/${APPNAME}-${VERSION}.apk" || exit 1

exit 0
