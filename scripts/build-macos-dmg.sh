#!/bin/bash

# Gecko - macOS DMG Build Script
# Automatically builds and packages Gecko for macOS distribution
# Usage: ./scripts/build-macos-dmg.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DATE=$(date +"%Y%m%d_%H%M%S")

# Get version from pubspec.yaml
VERSION=$(grep "^version:" "$PROJECT_ROOT/pubspec.yaml" | cut -d' ' -f2 | cut -d'+' -f1)
BUILD_NUMBER=$(grep "^version:" "$PROJECT_ROOT/pubspec.yaml" | cut -d'+' -f2)

# Paths
RELEASE_DIR="$PROJECT_ROOT/release/macos"
TEMP_DMG_DIR="$PROJECT_ROOT/temp_dmg_$BUILD_DATE"
APP_NAME="gecko"
DMG_NAME="Gecko-v${VERSION}-macos.dmg"
APP_PATH="$PROJECT_ROOT/build/macos/Build/Products/Release/${APP_NAME}.app"

# Code signing & notarization (distribution outside the Mac App Store).
# Requires a "Developer ID Application" certificate and a stored notarytool
# credentials profile. Override via env vars if needed.
#   xcrun notarytool store-credentials "gecko-notary" \
#     --apple-id <APPLE_ID> --team-id 2P2PNF45VD --password <APP_SPECIFIC_PASSWORD>
TEAM_ID="${MACOS_TEAM_ID:-2P2PNF45VD}"
SIGN_IDENTITY="${MACOS_SIGN_IDENTITY:-Developer ID Application: Axiom-Team (${TEAM_ID})}"
NOTARY_PROFILE="${MACOS_NOTARY_PROFILE:-gecko-notary}"
ENTITLEMENTS="$PROJECT_ROOT/macos/Runner/Release.entitlements"

echo -e "${CYAN}🦎 Gecko macOS DMG Build Script${NC}"
echo -e "${CYAN}=================================${NC}"
echo -e "${BLUE}Version: ${VERSION}+${BUILD_NUMBER}${NC}"
echo -e "${BLUE}Build Date: $(date)${NC}"
echo -e "${BLUE}Project: ${PROJECT_ROOT}${NC}"
echo ""

# Function to print step headers
print_step() {
    echo -e "${YELLOW}📋 $1${NC}"
}

# Function to print success messages
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to print error messages and exit
print_error() {
    echo -e "${RED}❌ Error: $1${NC}"
    exit 1
}

# Function to cleanup temporary files
cleanup() {
    if [[ -d "$TEMP_DMG_DIR" ]]; then
        print_step "Cleaning up temporary files..."
        rm -rf "$TEMP_DMG_DIR"
        print_success "Temporary files cleaned"
    fi
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Step 1: Verify environment
print_step "Verifying build environment..."

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script must be run on macOS"
fi

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
fi

# Check if we're in the correct directory
if [[ ! -f "$PROJECT_ROOT/pubspec.yaml" ]]; then
    print_error "pubspec.yaml not found. Are you in the correct directory?"
fi

# Check if durt2 dependency exists
if [[ ! -d "$PROJECT_ROOT/../durt2" ]]; then
    print_error "durt2 dependency not found at ../durt2"
fi

# Check the Developer ID signing identity is available in the keychain
if ! security find-identity -v -p codesigning 2>/dev/null | grep -qF "$SIGN_IDENTITY"; then
    echo -e "${RED}Available signing identities:${NC}"
    security find-identity -v -p codesigning 2>/dev/null | grep -o '"[^"]*"' || true
    print_error "Signing identity not found: '$SIGN_IDENTITY'. A 'Developer ID Application' certificate is required for distribution outside the App Store."
fi

# Check the notarization credentials profile is configured
if ! xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1; then
    print_error "Notary profile '$NOTARY_PROFILE' not configured. Run once:
   xcrun notarytool store-credentials \"$NOTARY_PROFILE\" --apple-id <APPLE_ID> --team-id $TEAM_ID --password <APP_SPECIFIC_PASSWORD>"
fi

print_success "Environment verified (signing identity + notary profile OK)"

# Step 2: Clean previous builds
print_step "Cleaning previous builds..."
cd "$PROJECT_ROOT"
flutter clean > /dev/null 2>&1
print_success "Previous builds cleaned"

# Step 3: Get dependencies
print_step "Getting Flutter dependencies..."
flutter pub get > /dev/null 2>&1
print_success "Dependencies updated"

# Step 4: Round macOS icons
print_step "Rounding macOS app icon corners..."
if command -v python3 &> /dev/null; then
    if python3 -c "import PIL" 2>/dev/null; then
        python3 "$SCRIPT_DIR/round_macos_icons.py" > /dev/null 2>&1
        print_success "Icon corners rounded"
    else
        echo -e "${YELLOW}⚠️  Pillow not installed, skipping icon rounding${NC}"
        echo -e "${BLUE}   Install with: pip3 install Pillow${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Python3 not found, skipping icon rounding${NC}"
fi

# Step 5: Build macOS release
print_step "Building macOS release (this may take a few minutes)..."
flutter build macos --release --split-debug-info=build/sentry-symbols

# Verify build success
if [[ ! -d "$APP_PATH" ]]; then
    print_error "macOS build failed - application not found at $APP_PATH"
fi

print_success "macOS build completed"

# Step 6: Verify binary architecture
print_step "Verifying binary architecture..."
BINARY_PATH="$APP_PATH/Contents/MacOS/$APP_NAME"
if [[ -f "$BINARY_PATH" ]]; then
    ARCH_INFO=$(file "$BINARY_PATH")
    if [[ "$ARCH_INFO" == *"universal binary"* ]]; then
        print_success "Universal binary created (Intel + Apple Silicon)"
    else
        echo -e "${YELLOW}⚠️  Warning: Not a universal binary${NC}"
        echo "   Architecture: $ARCH_INFO"
    fi
else
    print_error "Binary not found at $BINARY_PATH"
fi

# Step 6b: Code signing with Developer ID + Hardened Runtime
# Required to distribute outside the App Store. Without this the app is signed
# with a development certificate (+ provisioning profile + get-task-allow) and
# will be killed by Gatekeeper on any machine other than the build machine.
print_step "Signing with Developer ID (Hardened Runtime)..."

# Development provisioning profile is invalid for Developer ID distribution.
rm -f "$APP_PATH/Contents/embedded.provisionprofile"

# Build a distribution entitlements file from Release.entitlements, resolving the
# Xcode build variables that Xcode would normally expand at sign time. This keeps
# the entitlements in sync with the project while dropping the dev-only flags.
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP_PATH/Contents/Info.plist")
DIST_ENTITLEMENTS=$(mktemp -t gecko_entitlements_XXXXXX.plist)
sed -e "s|\$(AppIdentifierPrefix)|${TEAM_ID}.|g" \
    -e "s|\$(CFBundleIdentifier)|${BUNDLE_ID}|g" \
    "$ENTITLEMENTS" > "$DIST_ENTITLEMENTS"

# keychain-access-groups is a provisioning-restricted entitlement: it is only
# authorized when an embedded provisioning profile grants it (development/App
# Store builds). With Developer ID distribution there is no profile, so AMFI
# kills the app at launch ("Launchd job spawn failed"). Removing it makes the
# app fall back to the default keychain access group (TeamID.BundleID), which is
# the exact same value — flutter_secure_storage keeps working and previously
# stored secrets stay accessible.
/usr/libexec/PlistBuddy -c "Delete :keychain-access-groups" "$DIST_ENTITLEMENTS" 2>/dev/null || true

# Sign inner code first, then the app bundle (inside-out). --deep is intentionally
# NOT used (Apple-discouraged); each nested component is signed explicitly.
while IFS= read -r -d '' dylib; do
    codesign --force --timestamp --options runtime --sign "$SIGN_IDENTITY" "$dylib"
done < <(find "$APP_PATH/Contents/Frameworks" -type f -name "*.dylib" -print0 2>/dev/null)

while IFS= read -r -d '' framework; do
    codesign --force --timestamp --options runtime --sign "$SIGN_IDENTITY" "$framework"
done < <(find "$APP_PATH/Contents/Frameworks" -type d -name "*.framework" -print0 2>/dev/null)

# Sign the main bundle last, with Hardened Runtime and the resolved entitlements.
codesign --force --timestamp --options runtime \
    --entitlements "$DIST_ENTITLEMENTS" \
    --sign "$SIGN_IDENTITY" "$APP_PATH"

rm -f "$DIST_ENTITLEMENTS"

# Verify the signature is well-formed and valid.
codesign --verify --deep --strict --verbose=2 "$APP_PATH" \
    || print_error "Code signature verification failed"

# Guard: the dev-only get-task-allow entitlement must be gone, and we must be on
# a Developer ID certificate (not Apple Development).
if codesign -d --entitlements - --xml "$APP_PATH" 2>/dev/null | grep -q "get-task-allow"; then
    print_error "get-task-allow still present after signing (would be rejected for distribution)"
fi
SIGN_AUTH=$(codesign -dvv "$APP_PATH" 2>&1 | grep -m1 "Authority=" | sed 's/Authority=//')
if [[ "$SIGN_AUTH" != "Developer ID Application"* ]]; then
    print_error "Unexpected signing authority: '$SIGN_AUTH' (expected Developer ID Application)"
fi
print_success "Signed with: $SIGN_AUTH"

# Smoke test: AMFI kills apps that carry unauthorized entitlements at spawn time
# (exit 137 / SIGKILL), even when the signature itself is valid and the app is
# notarizable. Catch that here, before spending minutes on notarization.
print_step "Launch smoke test (AMFI spawn check)..."
"$BINARY_PATH" >/dev/null 2>&1 &
SMOKE_PID=$!
sleep 2
if kill -0 "$SMOKE_PID" 2>/dev/null; then
    kill -9 "$SMOKE_PID" 2>/dev/null
    print_success "App launches (not killed by AMFI)"
else
    wait "$SMOKE_PID" 2>/dev/null; SMOKE_RC=$?
    if [[ $SMOKE_RC -eq 137 ]]; then
        print_error "App killed by AMFI at launch (exit 137). Almost always a provisioning-restricted entitlement (e.g. keychain-access-groups) that Developer ID signing cannot authorize. Fix the distribution entitlements."
    fi
    echo -e "${YELLOW}⚠️  Smoke test: app exited on its own (code $SMOKE_RC). Verify manually that it is not crashing.${NC}"
fi

# Step 7: Create release directory
print_step "Preparing release directory..."
mkdir -p "$RELEASE_DIR"
print_success "Release directory ready"

# Step 8: Create temporary DMG structure
print_step "Creating DMG structure..."
mkdir -p "$TEMP_DMG_DIR"
cp -R "$APP_PATH" "$TEMP_DMG_DIR/"
ln -s /Applications "$TEMP_DMG_DIR/Applications"

# Create installation instructions
cat > "$TEMP_DMG_DIR/INSTALL.txt" << EOF
GECKO - Installation Instructions
==================================

Welcome to Gecko v${VERSION}!

INSTALLATION:
1. Drag "gecko.app" to the "Applications" folder
2. Open Launchpad or Finder > Applications
3. Double-click on "Gecko" to launch

SYSTEM REQUIREMENTS:
- macOS 11.5 (Big Sur) or later
- Apple Silicon (M1/M2/M3) or Intel processor (Universal binary)

FIRST RUN:
This app is signed with a Developer ID and notarized by Apple, so it
should open normally with a simple double-click. No security override
is required.

SUPPORT:
Visit: https://github.com/duniter/gecko

Thank you for using Gecko!
EOF

print_success "DMG structure created"

# Step 9: Create DMG
print_step "Creating DMG package..."
hdiutil create -volname "Gecko v${VERSION}" \
    -srcfolder "$TEMP_DMG_DIR" \
    -ov -format UDZO \
    "$RELEASE_DIR/$DMG_NAME" > /dev/null 2>&1

if [[ ! -f "$RELEASE_DIR/$DMG_NAME" ]]; then
    print_error "Failed to create DMG package"
fi

print_success "DMG package created"

# Step 9b: Notarize the DMG with Apple, then staple the ticket.
# Notarization must target the outermost container (the DMG). Stapling embeds the
# ticket so Gatekeeper accepts the app even on an offline machine.
print_step "Submitting DMG to Apple for notarization (this can take a few minutes)..."
if xcrun notarytool submit "$RELEASE_DIR/$DMG_NAME" \
        --keychain-profile "$NOTARY_PROFILE" --wait; then
    print_success "Notarization accepted by Apple"
else
    print_error "Notarization failed. Inspect with: xcrun notarytool log <submission-id> --keychain-profile $NOTARY_PROFILE"
fi

print_step "Stapling notarization ticket..."
xcrun stapler staple "$RELEASE_DIR/$DMG_NAME" || print_error "Failed to staple ticket to DMG"
# Also staple the standalone .app that gets copied to the release dir below.
xcrun stapler staple "$APP_PATH" 2>/dev/null || true
print_success "Notarization ticket stapled"

# Authoritative offline check: a stapled, notarized DMG must validate.
if xcrun stapler validate "$RELEASE_DIR/$DMG_NAME" >/dev/null 2>&1; then
    print_success "Gatekeeper: DMG is notarized and stapled"
else
    print_error "Stapler validation failed on the DMG"
fi

# Step 10: Copy standalone app
print_step "Copying standalone application..."
cp -R "$APP_PATH" "$RELEASE_DIR/"
print_success "Standalone app copied"

# Step 11: Generate checksum
print_step "Generating integrity checksum..."
cd "$RELEASE_DIR"
shasum -a 256 "$DMG_NAME" > "${DMG_NAME}.sha256"
print_success "Checksum generated"

# Step 12: Create documentation
print_step "Creating documentation..."

# Create README
cat > "$RELEASE_DIR/README.md" << EOF
# Gecko v${VERSION} - macOS Release Package

## 📁 Package Contents

- **\`${DMG_NAME}\`** ($(ls -lah "$DMG_NAME" | awk '{print $5}')) - Main installation package
- **\`gecko.app/\`** - Standalone application bundle
- **\`install.sh\`** - Automated installation script
- **\`INSTALLATION_GUIDE.md\`** - French installation guide
- **\`INSTALLATION_GUIDE_EN.md\`** - English installation guide
- **\`${DMG_NAME}.sha256\`** - Integrity checksum

## 🚀 Quick Installation

### Method 1: DMG Package (Recommended)
1. Double-click \`${DMG_NAME}\`
2. Drag \`gecko.app\` to \`Applications\`
3. Launch Gecko from Launchpad

### Method 2: Automated Script
\`\`\`bash
chmod +x install.sh
./install.sh
\`\`\`

## 🔍 Verification
\`\`\`bash
shasum -a 256 -c ${DMG_NAME}.sha256
\`\`\`

## 📋 System Requirements
- macOS 10.14 (Mojave) or later
- ~100 MB free space
- Administrator privileges for installation

---
**Version:** ${VERSION}+${BUILD_NUMBER}  
**Build Date:** $(date +"%d/%m/%Y %H:%M")  
**Platform:** macOS Universal (Intel + Apple Silicon)
EOF

# Create French installation guide
cat > "$RELEASE_DIR/INSTALLATION_GUIDE.md" << EOF
# Gecko v${VERSION} - Guide d'Installation macOS

## 📦 Installation

1. **Téléchargez** \`${DMG_NAME}\`
2. **Double-cliquez** sur le fichier DMG
3. **Glissez** \`gecko.app\` vers le dossier \`Applications\`
4. **Lancez** Gecko depuis Launchpad

## ✅ Sécurité

L'application est signée avec un certificat **Developer ID** et **notarisée par Apple**.
Elle s'ouvre donc normalement d'un simple double-clic, sans manipulation de sécurité.

## 🔧 Prérequis Système

- **macOS 11.5** (Big Sur) ou plus récent
- **~100 MB** d'espace libre
- **Droits administrateur** pour l'installation

## 🗑️ Désinstallation

1. Allez dans \`Applications\`
2. Glissez \`Gecko\` vers la Corbeille
3. Videz la Corbeille

## 📞 Support

- **Site web :** https://github.com/duniter/gecko
- **Version :** ${VERSION}+${BUILD_NUMBER}
- **Date de build :** $(date +"%d/%m/%Y")
EOF

# Create English installation guide
cat > "$RELEASE_DIR/INSTALLATION_GUIDE_EN.md" << EOF
# Gecko v${VERSION} - macOS Installation Guide

## 📦 Installation

1. **Download** \`${DMG_NAME}\`
2. **Double-click** the DMG file
3. **Drag** \`gecko.app\` to the \`Applications\` folder
4. **Launch** Gecko from Launchpad

## ✅ Security

The app is signed with a **Developer ID** certificate and **notarized by Apple**.
It opens normally with a simple double-click — no security override needed.

## 🔧 System Requirements

- **macOS 11.5** (Big Sur) or later
- **~100 MB** free space
- **Administrator privileges** for installation

## 🗑️ Uninstallation

1. Go to \`Applications\`
2. Drag \`Gecko\` to Trash
3. Empty Trash

## 📞 Support

- **Website:** https://github.com/duniter/gecko
- **Version:** ${VERSION}+${BUILD_NUMBER}
- **Build Date:** $(date +"%d/%m/%Y")
EOF

# Create installation script
cat > "$RELEASE_DIR/install.sh" << 'EOF'
#!/bin/bash

# Gecko macOS Installation Script

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🦎 Gecko - macOS Installation${NC}"
echo "==============================="

DMG_FILE="$(ls Gecko-v*.dmg 2>/dev/null | head -n1)"

if [[ -z "$DMG_FILE" ]]; then
    echo -e "${RED}❌ Error: No Gecko DMG file found${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Found: $DMG_FILE${NC}"

# Mount DMG
echo -e "${BLUE}📀 Mounting disk image...${NC}"
MOUNT_POINT=$(hdiutil attach "$DMG_FILE" | grep "/Volumes/" | awk '{print $3}')

if [[ -z "$MOUNT_POINT" ]]; then
    echo -e "${RED}❌ Failed to mount DMG${NC}"
    exit 1
fi

# Install app
echo -e "${BLUE}📋 Installing application...${NC}"
if [[ ! -w "/Applications" ]]; then
    echo -e "${YELLOW}🔐 Administrator privileges required...${NC}"
    sudo cp -R "$MOUNT_POINT/gecko.app" "/Applications/"
else
    cp -R "$MOUNT_POINT/gecko.app" "/Applications/"
fi

# Unmount DMG
hdiutil detach "$MOUNT_POINT" >/dev/null 2>&1

echo -e "${GREEN}🎉 Installation completed!${NC}"
echo -e "${BLUE}Launch Gecko from Applications folder${NC}"
EOF

chmod +x "$RELEASE_DIR/install.sh"

# Create verification script
cat > "$RELEASE_DIR/verify_release.sh" << EOF
#!/bin/bash

# Gecko Release Verification Script

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "\${BLUE}🦎 Gecko v${VERSION} - Release Verification\${NC}"
echo "======================================="

ERRORS=0

check_file() {
    local file="\$1"
    local desc="\$2"
    echo -n "Checking \$desc... "
    if [[ -f "\$file" ]]; then
        local size=\$(ls -lah "\$file" | awk '{print \$5}')
        echo -e "\${GREEN}✅ Found (\$size)\${NC}"
    else
        echo -e "\${RED}❌ Missing\${NC}"
        ((ERRORS++))
    fi
}

check_file "${DMG_NAME}" "DMG package"
check_file "${DMG_NAME}.sha256" "Checksum"
check_file "gecko.app/Contents/MacOS/gecko" "Executable"
check_file "README.md" "README"
check_file "install.sh" "Install script"

echo -n "Verifying checksum... "
if shasum -a 256 -c "${DMG_NAME}.sha256" >/dev/null 2>&1; then
    echo -e "\${GREEN}✅ Valid\${NC}"
else
    echo -e "\${RED}❌ Invalid\${NC}"
    ((ERRORS++))
fi

echo ""
if [[ \$ERRORS -eq 0 ]]; then
    echo -e "\${GREEN}🎉 All checks passed! Release ready for distribution.\${NC}"
    exit 0
else
    echo -e "\${RED}❌ Found \$ERRORS error(s).\${NC}"
    exit 1
fi
EOF

chmod +x "$RELEASE_DIR/verify_release.sh"

print_success "Documentation created"

# Step 13: Final verification
print_step "Running final verification..."
cd "$RELEASE_DIR"
if ./verify_release.sh > /dev/null 2>&1; then
    print_success "All verification checks passed"
else
    print_error "Verification failed"
fi

# Step 14: Show results
echo ""
echo -e "${GREEN}🎉 BUILD COMPLETED SUCCESSFULLY! 🎉${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo -e "${BLUE}📦 Generated Files:${NC}"
echo -e "   📍 Location: ${RELEASE_DIR}"
echo -e "   🎯 Main package: ${DMG_NAME} ($(ls -lah "$DMG_NAME" | awk '{print $5}'))"
echo -e "   📱 Standalone app: gecko.app/"
echo -e "   🔐 Checksum: ${DMG_NAME}.sha256"
echo -e "   📚 Documentation: 4 files (FR + EN)"
echo -e "   🛠️  Installation tools: 2 scripts"
echo ""
echo -e "${BLUE}📊 Package Statistics:${NC}"
echo -e "   🔢 Total files: $(find "$RELEASE_DIR" -type f | wc -l | tr -d ' ')"
echo -e "   📏 Total size: $(du -sh "$RELEASE_DIR" | cut -f1)"
echo -e "   🏗️  Architecture: Universal Binary (Intel + Apple Silicon)"
echo ""
echo -e "${BLUE}🚀 Ready for Distribution:${NC}"
echo -e "   ✅ DMG package created and verified"
echo -e "   ✅ Installation scripts provided"
echo -e "   ✅ Bilingual documentation included"
echo -e "   ✅ Integrity checksum generated"
echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo -e "   1. Test the DMG on a clean macOS system"
echo -e "   2. Distribute ${DMG_NAME}"
echo -e "   3. Provide installation guides to users"
echo ""
echo -e "${GREEN}🦎 Gecko v${VERSION} macOS release is ready! 🎉${NC}"

# Return to project root
cd "$PROJECT_ROOT"
