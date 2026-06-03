#!/bin/bash
# Inject the GPU->software rendering fallback launcher into a built Flutter Linux
# bundle. The real executable is renamed to `gecko.bin` and replaced by the
# `gecko` wrapper (see scripts/gecko-linux-launcher.sh).
#
# Usage: ./scripts/package-linux-bundle.sh <bundle_dir>
#   e.g. ./scripts/package-linux-bundle.sh build/linux/x64/release/bundle

set -e

BUNDLE="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -z "$BUNDLE" ] || [ ! -d "$BUNDLE" ]; then
  echo "Error: bundle directory '$BUNDLE' not found" >&2
  exit 1
fi

if [ ! -f "$BUNDLE/gecko" ]; then
  echo "Error: '$BUNDLE/gecko' executable not found" >&2
  exit 1
fi

mv "$BUNDLE/gecko" "$BUNDLE/gecko.bin"
cp "$SCRIPT_DIR/gecko-linux-launcher.sh" "$BUNDLE/gecko"
chmod +x "$BUNDLE/gecko" "$BUNDLE/gecko.bin"

echo "Injected software-rendering fallback launcher into $BUNDLE"
