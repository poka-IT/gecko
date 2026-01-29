#!/bin/bash
# Build a Dart script to native executable
# Usage: ./scripts/build_dart.sh <path/to/script.dart>
#
# The executable will be created at the same location with the same name (no .dart extension)

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <path/to/script.dart>"
    echo ""
    echo "Example: $0 scripts/show_cert_queue.dart"
    exit 1
fi

SCRIPT_PATH="$1"

# Check if file exists
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "❌ Error: File not found: $SCRIPT_PATH"
    exit 1
fi

# Check if it's a .dart file
if [[ "$SCRIPT_PATH" != *.dart ]]; then
    echo "❌ Error: File must have .dart extension"
    exit 1
fi

# Get the directory and filename
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
SCRIPT_NAME=$(basename "$SCRIPT_PATH" .dart)
OUTPUT_PATH="$SCRIPT_DIR/$SCRIPT_NAME"

echo "🔨 Building $SCRIPT_PATH..."

# Create bin directory if needed
mkdir -p bin

# Copy script to bin/
cp "$SCRIPT_PATH" "bin/$SCRIPT_NAME.dart"

# Build
echo "   Compiling to native executable..."
dart build cli 2>&1 | grep -v "^The \`dart build cli\` command is in preview" | grep -v "^See documentation" || true

# Find the built executable
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    BUILD_PATH="build/cli/macos_arm64/bundle/bin/$SCRIPT_NAME"
elif [ "$ARCH" = "x86_64" ]; then
    BUILD_PATH="build/cli/macos_x64/bundle/bin/$SCRIPT_NAME"
else
    # Linux
    BUILD_PATH="build/cli/linux_x64/bundle/bin/$SCRIPT_NAME"
fi

if [ ! -f "$BUILD_PATH" ]; then
    # Try alternate path
    BUILD_PATH=$(find build/cli -name "$SCRIPT_NAME" -type f 2>/dev/null | head -1)
fi

if [ -z "$BUILD_PATH" ] || [ ! -f "$BUILD_PATH" ]; then
    echo "❌ Error: Build failed - executable not found"
    rm -f "bin/$SCRIPT_NAME.dart"
    rmdir bin 2>/dev/null || true
    exit 1
fi

# Copy to output location
cp "$BUILD_PATH" "$OUTPUT_PATH"
chmod +x "$OUTPUT_PATH"

# Cleanup
rm -f "bin/$SCRIPT_NAME.dart"
rmdir bin 2>/dev/null || true

# Show result
SIZE=$(du -h "$OUTPUT_PATH" | cut -f1)
echo ""
echo "✅ Built successfully!"
echo "   Output: $OUTPUT_PATH ($SIZE)"
echo ""
echo "   Run with: $OUTPUT_PATH"
