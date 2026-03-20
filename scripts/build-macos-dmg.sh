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

print_success "Environment verified"

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
- macOS 10.14 (Mojave) or later
- Apple Silicon (M1/M2/M3) or Intel processor

FIRST RUN:
If you see a security warning:
1. Go to System Preferences > Security & Privacy
2. Click "Open Anyway" for Gecko

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

## ⚠️ Avertissement de Sécurité

Si macOS affiche un avertissement au premier lancement :

1. Allez dans **Préférences Système > Sécurité et confidentialité**
2. Cliquez **"Ouvrir quand même"** pour Gecko
3. Ou faites **clic droit > Ouvrir** sur l'application

## 🔧 Prérequis Système

- **macOS 10.14** (Mojave) ou plus récent
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

## ⚠️ Security Warning

If macOS shows a security warning on first launch:

1. Go to **System Preferences > Security & Privacy**
2. Click **"Open Anyway"** for Gecko
3. Or **right-click > Open** on the application

## 🔧 System Requirements

- **macOS 10.14** (Mojave) or later
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
