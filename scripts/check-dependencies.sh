#!/bin/bash

# Script to check if all required dependencies are installed for Gecko builds
# Usage: ./scripts/check-dependencies.sh

set -e

echo "🔍 Checking Gecko build dependencies..."
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track if any dependencies are missing
MISSING_DEPS=0

# Function to check command
check_command() {
    local cmd=$1
    local name=$2
    local install_hint=$3
    
    if command -v "$cmd" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $name is installed"
        return 0
    else
        echo -e "${RED}✗${NC} $name is NOT installed"
        echo -e "  ${YELLOW}→ $install_hint${NC}"
        MISSING_DEPS=1
        return 1
    fi
}

# Function to check Flutter version
check_flutter_version() {
    if command -v flutter &> /dev/null; then
        local version=$(flutter --version | head -n 1 | awk '{print $2}')
        echo -e "${GREEN}✓${NC} Flutter version: $version"
        
        # Check if FVM is being used
        if command -v fvm &> /dev/null; then
            local fvm_version=$(fvm flutter --version | head -n 1 | awk '{print $2}')
            echo -e "${GREEN}✓${NC} FVM Flutter version: $fvm_version"
        fi
    fi
}

echo "📱 Core Dependencies:"
echo "===================="

# Flutter
check_command "flutter" "Flutter" "Install from https://flutter.dev/docs/get-started/install"

# FVM (Flutter Version Management)
check_command "fvm" "FVM (Flutter Version Management)" "Install with: dart pub global activate fvm"

# Git
check_command "git" "Git" "Install from https://git-scm.com/"

echo ""
echo "🤖 Android Dependencies:"
echo "======================="

# Android SDK
if [ -n "$ANDROID_HOME" ] || [ -n "$ANDROID_SDK_ROOT" ]; then
    echo -e "${GREEN}✓${NC} Android SDK is configured"
else
    echo -e "${RED}✗${NC} Android SDK environment not found"
    echo -e "  ${YELLOW}→ Set ANDROID_HOME or ANDROID_SDK_ROOT environment variable${NC}"
    MISSING_DEPS=1
fi

# Java
check_command "java" "Java" "Install OpenJDK 11 or higher"

echo ""
echo "🍎 iOS Dependencies (macOS only):"
echo "================================"

if [[ "$OSTYPE" == "darwin"* ]]; then
    # Xcode
    if xcode-select -p &> /dev/null; then
        echo -e "${GREEN}✓${NC} Xcode Command Line Tools installed"
    else
        echo -e "${RED}✗${NC} Xcode Command Line Tools NOT installed"
        echo -e "  ${YELLOW}→ Install with: xcode-select --install${NC}"
        MISSING_DEPS=1
    fi
    
    # CocoaPods
    check_command "pod" "CocoaPods" "Install with: sudo gem install cocoapods"
    
    # Fastlane
    check_command "fastlane" "Fastlane" "Install with: gem install fastlane -NV"
else
    echo -e "${YELLOW}ℹ${NC} Skipping iOS checks (not on macOS)"
fi

echo ""
echo "🐧 Linux Desktop Dependencies:"
echo "============================="

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Check for required packages
    check_command "cmake" "CMake" "Install with: sudo apt-get install cmake"
    check_command "ninja" "Ninja" "Install with: sudo apt-get install ninja-build"
    check_command "pkg-config" "pkg-config" "Install with: sudo apt-get install pkg-config"
    
    # Check for GTK development files
    if pkg-config --exists gtk+-3.0 2>/dev/null; then
        echo -e "${GREEN}✓${NC} GTK 3.0 development files installed"
    else
        echo -e "${RED}✗${NC} GTK 3.0 development files NOT installed"
        echo -e "  ${YELLOW}→ Install with: sudo apt-get install libgtk-3-dev${NC}"
        MISSING_DEPS=1
    fi
else
    echo -e "${YELLOW}ℹ${NC} Skipping Linux desktop checks (not on Linux)"
fi

echo ""
echo "📦 Deployment Tools:"
echo "==================="

# Ruby (for Fastlane)
check_command "ruby" "Ruby" "Install from https://www.ruby-lang.org/"

# Gem (Ruby package manager)
check_command "gem" "RubyGems" "Usually comes with Ruby installation"

# Fastlane (if Ruby is available)
if command -v gem &> /dev/null; then
    check_command "fastlane" "Fastlane" "Install with: gem install fastlane -NV"
fi

# Python (for helper scripts)
check_command "python3" "Python 3" "Install from https://www.python.org/"

echo ""
echo "📋 Configuration Files:"
echo "====================="

# Check for .env file
if [ -f ".env" ]; then
    echo -e "${GREEN}✓${NC} .env file exists"
else
    echo -e "${YELLOW}!${NC} .env file not found"
    echo -e "  ${YELLOW}→ Copy .env.example to .env and configure it${NC}"
fi

# Check for Android signing key
if [ -f "android/key.properties" ]; then
    echo -e "${GREEN}✓${NC} Android key.properties exists"
else
    echo -e "${YELLOW}!${NC} Android key.properties not found"
    echo -e "  ${YELLOW}→ Required for release builds${NC}"
fi

# Check for iOS ExportOptions.plist
if [ -f "ios/ExportOptions.plist" ]; then
    echo -e "${GREEN}✓${NC} iOS ExportOptions.plist exists"
else
    echo -e "${YELLOW}!${NC} iOS ExportOptions.plist not found"
    echo -e "  ${YELLOW}→ Required for iOS release builds${NC}"
fi

echo ""
echo "================================"

# Show Flutter/FVM version details
if command -v flutter &> /dev/null; then
    echo ""
    check_flutter_version
fi

# Summary
echo ""
if [ $MISSING_DEPS -eq 0 ]; then
    echo -e "${GREEN}✅ All required dependencies are installed!${NC}"
    echo ""
    echo "You can now:"
    echo "  • Run local builds with: flutter build [apk|ipa|linux]"
    echo "  • Deploy to stores with: ./scripts/deploy-[android|ios].sh"
    echo "  • Create releases with: ./scripts/create-release.sh"
else
    echo -e "${RED}❌ Some dependencies are missing!${NC}"
    echo ""
    echo "Please install the missing dependencies listed above."
    exit 1
fi
