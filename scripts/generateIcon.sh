#!/bin/bash

set -e

# Check for necessary assets
if [ ! -f "assets/icon/gecko_flat.png" ]; then
    echo "Error: gecko_flat.png not found in assets/icon/"
    exit 1
fi

# Generate icons (with remove_alpha for the App Store)
fvm flutter pub get
fvm flutter pub run flutter_launcher_icons

# For the Launch Screen, we keep transparency
LAUNCH_IMAGE="assets/icon/gecko_flat_background.png"
IOS_ASSETS="ios/Runner/Assets.xcassets/LaunchImage.imageset"

# Create the folder if it does not exist
mkdir -p "$IOS_ASSETS"

# Create Contents.json for LaunchImage
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

# For the Launch Screen only, we keep transparency
if [[ "$(uname)" == "Darwin" ]]; then
  # macOS, use sips
  sips -z 400 400 "$LAUNCH_IMAGE" --out "$IOS_ASSETS/LaunchImage.png"
  sips -z 800 800 "$LAUNCH_IMAGE" --out "$IOS_ASSETS/LaunchImage@2x.png"
  sips -z 1200 1200 "$LAUNCH_IMAGE" --out "$IOS_ASSETS/LaunchImage@3x.png"
else
  # Linux/other, use magick
  magick "$LAUNCH_IMAGE" -background none -alpha set -resize 400x400 "$IOS_ASSETS/LaunchImage.png"
  magick "$LAUNCH_IMAGE" -background none -alpha set -resize 800x800 "$IOS_ASSETS/LaunchImage@2x.png"
  magick "$LAUNCH_IMAGE" -background none -alpha set -resize 1200x1200 "$IOS_ASSETS/LaunchImage@3x.png"
fi

# Check that the LaunchScreen.storyboard exists
if [ ! -f "ios/Runner/Base.lproj/LaunchScreen.storyboard" ]; then
    echo "Error: LaunchScreen.storyboard not found"
    exit 1
fi

echo "Launch screen assets generated successfully!"

exit 0
