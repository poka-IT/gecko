#!/bin/bash

# Android Google Play Store Deployment Script
# 
# This script builds an Android App Bundle (.aab) and automatically uploads it 
# to Google Play Store using fastlane.
#
# PREREQUISITES:
# 1. Create a Google Cloud Project and enable Google Play Developer API
# 2. Create a Service Account in Google Cloud Console:
#    - Go to Google Cloud Console > IAM & Admin > Service Accounts
#    - Create service account with name like "fastlane-supply"
#    - Create and download JSON key (choose JSON format)
# 3. Grant permissions in Google Play Console:
#    - Go to Google Play Console > Users and permissions
#    - Invite new user with the service account email
#    - Grant "Admin" permissions or at least "Releases" permissions
# 4. Configure .env file with:
#    - GOOGLE_PLAY_JSON_KEY_PATH: path to your JSON key file
#    - ANDROID_PACKAGE_NAME: your app package name (e.g., fr.axiomteam.gecko)
#    - GOOGLE_PLAY_TRACK: target track (internal, alpha, beta, production)
#    - GOOGLE_PLAY_RELEASE_STATUS: release status (draft, completed) [optional]
#
# USAGE:
#   ./scripts/deploy-android.sh                  # Deploy to Google Play Store
#   ./scripts/deploy-android.sh --validate-only  # Validate only (no upload)
#   ./scripts/deploy-android.sh -v               # Validate only (short form)
#   ./scripts/deploy-android.sh --changelog "Bug fixes and improvements"  # With changelog
#
# The script will:
# - Extract version from pubspec.yaml
# - Install fastlane if needed
# - Build the App Bundle
# - Upload to Google Play Store
#
# Compatible with both macOS and Linux

set -e

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to setup PATH for Ruby gems on macOS
setup_ruby_path() {
    # Add common Ruby gem paths for Homebrew on macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Homebrew Ruby paths
        export PATH="/opt/homebrew/lib/ruby/gems/3.4.0/bin:/opt/homebrew/lib/ruby/gems/3.3.0/bin:/opt/homebrew/lib/ruby/gems/3.2.0/bin:$PATH"
        export PATH="/usr/local/lib/ruby/gems/3.4.0/bin:/usr/local/lib/ruby/gems/3.3.0/bin:/usr/local/lib/ruby/gems/3.2.0/bin:$PATH"
        # System Ruby
        export PATH="/usr/local/bin:$PATH"
    fi
}

# Function to install fastlane
install_fastlane() {
    echo "Installing fastlane..."
    if command_exists gem; then
        echo "Installing fastlane using gem..."
        gem install fastlane -NV
        echo "Fastlane installation completed."
    elif command_exists bundle; then
        echo "Installing fastlane using bundle..."
        bundle install
    else
        echo "Error: Neither gem nor bundle found. Please install Ruby and RubyGems."
        echo "On macOS, you can install Ruby via Homebrew:"
        echo "  brew install ruby"
        exit 1
    fi
}

# Function to check fastlane installation
check_fastlane() {
    # Setup Ruby PATH first
    setup_ruby_path
    
    # Check if fastlane is available
    if ! command_exists fastlane; then
        echo "Fastlane not found in PATH, attempting to install..."
        install_fastlane
        
        # Re-setup PATH after installation
        setup_ruby_path
        
        # Final verification
        if ! command_exists fastlane; then
            echo "Error: Fastlane installation failed or not found in PATH."
            echo "Please install it manually with:"
            echo "  gem install fastlane -NV"
            echo ""
            echo "Or ensure it's in your PATH. Common locations on macOS:"
            echo "  /opt/homebrew/lib/ruby/gems/*/bin/fastlane"
            echo "  /usr/local/lib/ruby/gems/*/bin/fastlane"
            echo ""
            echo "You can also try: which fastlane"
            exit 1
        fi
    fi
    
    echo "Using fastlane: $(which fastlane)"
}

# Function to create changelog file if provided
create_changelog_file() {
    if [ -n "$CHANGELOG_TEXT" ]; then
        # Create temporary metadata directory structure
        METADATA_DIR="/tmp/fastlane_metadata/android/en-US/changelogs"
        mkdir -p "$METADATA_DIR"
        
        # Create changelog file with build number as filename
        echo "$CHANGELOG_TEXT" > "$METADATA_DIR/${BUILD}.txt"
        echo "Created changelog file: $METADATA_DIR/${BUILD}.txt"
        
        # Set metadata path for fastlane
        FASTLANE_METADATA_PATH="/tmp/fastlane_metadata"
        return 0
    else
        # No changelog provided, skip metadata upload
        FASTLANE_METADATA_PATH=""
        return 1
    fi
}

# Function to parse command line arguments
parse_arguments() {
    VALIDATE_ONLY=""
    CHANGELOG_TEXT=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --validate-only|-v)
                VALIDATE_ONLY="--validate_only"
                echo "Running in validation mode (no actual upload)..."
                shift
                ;;
            --changelog|-c)
                if [[ -n "$2" && ! "$2" =~ ^-- ]]; then
                    CHANGELOG_TEXT="$2"
                    echo "Changelog provided: $CHANGELOG_TEXT"
                    shift 2
                else
                    echo "Error: --changelog requires a text argument"
                    echo "Usage: $0 --changelog \"Your changelog text here\""
                    exit 1
                fi
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Function to show help
show_help() {
    echo "Android Google Play Store Deployment Script"
    echo ""
    echo "USAGE:"
    echo "  $0                                    Deploy to Google Play Store"
    echo "  $0 --validate-only                   Validate only (no upload)"
    echo "  $0 -v                                Validate only (short form)"
    echo "  $0 --changelog \"Bug fixes\"           Deploy with changelog"
    echo "  $0 -c \"New features added\"           Deploy with changelog (short form)"
    echo "  $0 --changelog \"Fix\" --validate-only  Validate with changelog"
    echo "  $0 --help                            Show this help"
    echo ""
    echo "ENVIRONMENT VARIABLES:"
    echo "  GOOGLE_PLAY_JSON_KEY_PATH   Path to Google Play service account JSON key"
    echo "  ANDROID_PACKAGE_NAME        Android package name (e.g., fr.axiomteam.gecko)"
    echo "  GOOGLE_PLAY_TRACK           Target track (internal, alpha, beta, production)"
    echo "  GOOGLE_PLAY_RELEASE_STATUS  Release status (draft, completed) [default: completed]"
    echo ""
    echo "RELEASE STATUS OPTIONS:"
    echo "  draft      - Upload but keep as draft (manual publish later)"
    echo "  completed  - Publish immediately (automatic)"
}

# Function to cleanup temporary files
cleanup() {
    echo "Cleaning up temporary files..."
    if [ -f "/tmp/fastlane_appfile" ]; then
        rm -f "/tmp/fastlane_appfile"
    fi
    if [ -f "/tmp/fastlane_supply_config" ]; then
        rm -f "/tmp/fastlane_supply_config"
    fi
    if [ -f "/tmp/changelog_${BUILD}.txt" ]; then
        rm -f "/tmp/changelog_${BUILD}.txt"
    fi
    if [ -d "/tmp/fastlane_metadata" ]; then
        rm -rf "/tmp/fastlane_metadata"
    fi
}

# Parse command line arguments first
parse_arguments "$@"

# Trap ERR and EXIT signals to ensure cleanup
trap cleanup ERR EXIT

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | sed 's/#.*//g' | xargs)
else
    echo "Please create a .env file with required Google Play credentials"
    exit 1
fi

# Check required environment variables
if [ -z "$GOOGLE_PLAY_JSON_KEY_PATH" ]; then
    echo "Error: GOOGLE_PLAY_JSON_KEY_PATH is required in .env file"
    exit 1
fi

if [ -z "$ANDROID_PACKAGE_NAME" ]; then
    echo "Error: ANDROID_PACKAGE_NAME is required in .env file"
    exit 1
fi

# Check if JSON key file exists
if [ ! -f "$GOOGLE_PLAY_JSON_KEY_PATH" ]; then
    echo "Error: Google Play JSON key file not found at: $GOOGLE_PLAY_JSON_KEY_PATH"
    exit 1
fi

# Set default track if not specified
if [ -z "$GOOGLE_PLAY_TRACK" ]; then
    GOOGLE_PLAY_TRACK="internal"
fi

# Set default release status if not specified
if [ -z "$GOOGLE_PLAY_RELEASE_STATUS" ]; then
    GOOGLE_PLAY_RELEASE_STATUS="completed"
fi

# Get version from pubspec.yaml
fVersion=$(grep "version: " pubspec.yaml | awk '{ print $2 }')
VERSION=$(awk -F '+' '{ print $1 }' <<<$fVersion)
BUILD=$(awk -F '+' '{ print $2 }' <<<$fVersion)

echo "Building Gecko Android AppBundle v${VERSION}+${BUILD}"
echo "Target track: ${GOOGLE_PLAY_TRACK}"
echo "Release status: ${GOOGLE_PLAY_RELEASE_STATUS}"
if [ -n "$CHANGELOG_TEXT" ]; then
    echo "Changelog: \"$CHANGELOG_TEXT\""
fi

# Check fastlane installation
check_fastlane

# Get dependencies
echo "Getting Flutter dependencies..."
fvm flutter pub get

# Build Android App Bundle
echo "Building Android App Bundle..."
fvm flutter build appbundle \
    --release \
    --build-name=$VERSION \
    --build-number=$BUILD

# Path to the built AAB
AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
if [ ! -f "$AAB_PATH" ]; then
    echo "AAB file not found at $AAB_PATH"
    exit 1
fi

echo "AppBundle built successfully at: $AAB_PATH"

# Create changelog file if provided
create_changelog_file

# Upload to Google Play Store using fastlane supply
echo "Uploading to Google Play Store (${GOOGLE_PLAY_TRACK} track)..."

# Prepare fastlane command with conditional parameters
FASTLANE_CMD="fastlane supply \
    --aab \"$AAB_PATH\" \
    --track \"$GOOGLE_PLAY_TRACK\" \
    --package_name \"$ANDROID_PACKAGE_NAME\" \
    --json_key \"$GOOGLE_PLAY_JSON_KEY_PATH\" \
    --release_status \"$GOOGLE_PLAY_RELEASE_STATUS\" \
    --skip_upload_metadata \
    --skip_upload_images \
    --skip_upload_screenshots"

# Add changelog-related parameters
if [ -n "$FASTLANE_METADATA_PATH" ]; then
    echo "Including changelog in upload..."
    FASTLANE_CMD="$FASTLANE_CMD --metadata_path \"$FASTLANE_METADATA_PATH\""
else
    FASTLANE_CMD="$FASTLANE_CMD --skip_upload_changelogs"
fi

# Add validate_only flag if set
if [ -n "$VALIDATE_ONLY" ]; then
    FASTLANE_CMD="$FASTLANE_CMD $VALIDATE_ONLY"
fi

# Execute fastlane command
eval $FASTLANE_CMD

if [ $? -eq 0 ]; then
    if [ -n "$VALIDATE_ONLY" ]; then
        echo "Validation completed successfully!"
        echo "AppBundle is ready for upload to Google Play Store (${GOOGLE_PLAY_TRACK} track)"
    else
        echo "Successfully uploaded AppBundle to Google Play Store (${GOOGLE_PLAY_TRACK} track)"
        echo ""
        if [ "$GOOGLE_PLAY_RELEASE_STATUS" = "draft" ]; then
            echo "⚠️  Release created as DRAFT - you need to manually publish it:"
            echo "   1. Go to Google Play Console"
            echo "   2. Select your app"
            echo "   3. Go to Release > Production (or your track)"
            echo "   4. Review and publish the draft release"
        elif [ "$GOOGLE_PLAY_RELEASE_STATUS" = "completed" ] && [ "$GOOGLE_PLAY_TRACK" = "production" ]; then
            echo "🚀 Release is LIVE in production!"
            echo "   Your app update should be available on Google Play within a few hours."
        elif [ "$GOOGLE_PLAY_RELEASE_STATUS" = "completed" ]; then
            echo "✅ Release is LIVE on ${GOOGLE_PLAY_TRACK} track!"
            echo "   Available to your ${GOOGLE_PLAY_TRACK} testers immediately."
        fi
    fi
    echo ""
    echo "Version: ${VERSION}+${BUILD}"
    echo "Package: ${ANDROID_PACKAGE_NAME}"
    if [ -n "$CHANGELOG_TEXT" ]; then
        echo "Changelog: \"$CHANGELOG_TEXT\""
    fi
else
    if [ -n "$VALIDATE_ONLY" ]; then
        echo "Validation failed - please check your configuration"
    else
        echo "Failed to upload AppBundle to Google Play Store"
    fi
    exit 1
fi

if [ -n "$VALIDATE_ONLY" ]; then
    echo "Android validation completed successfully!"
else
    echo "Android deployment completed successfully!"
fi 