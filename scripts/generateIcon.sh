#!/bin/bash

set -e

# Vérifier la présence des assets nécessaires
if [ ! -f "assets/icon/gecko_flat.png" ]; then
    echo "Error: gecko_flat.png not found in assets/icon/"
    exit 1
fi

# Générer les icônes (avec remove_alpha pour l'App Store)
fvm flutter pub get
fvm flutter pub run flutter_launcher_icons

# Pour le Launch Screen, on garde la transparence
LAUNCH_IMAGE="assets/icon/gecko_flat_background.png"
IOS_ASSETS="ios/Runner/Assets.xcassets/LaunchImage.imageset"

# Créer le dossier s'il n'existe pas
mkdir -p "$IOS_ASSETS"

# Créer le Contents.json pour LaunchImage
cat > "$IOS_ASSETS/Contents.json" << EOL
{
  "images" : [
    {
      "filename" : "LaunchImage.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "LaunchImage@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "filename" : "LaunchImage@3x.png",
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  },
  "properties" : {
    "preserves-vector-representation" : true,
    "template-rendering-intent" : "original"
  }
}
EOL

# Pour le Launch Screen uniquement, on garde la transparence
magick "$LAUNCH_IMAGE" -background none -alpha set -resize 400x400 "$IOS_ASSETS/LaunchImage.png"
magick "$LAUNCH_IMAGE" -background none -alpha set -resize 800x800 "$IOS_ASSETS/LaunchImage@2x.png"
magick "$LAUNCH_IMAGE" -background none -alpha set -resize 1200x1200 "$IOS_ASSETS/LaunchImage@3x.png"

# Vérifier que le LaunchScreen.storyboard existe
if [ ! -f "ios/Runner/Base.lproj/LaunchScreen.storyboard" ]; then
    echo "Error: LaunchScreen.storyboard not found"
    exit 1
fi

echo "Launch screen assets generated successfully!"

exit 0
