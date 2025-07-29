#!/bin/bash

# iOS App Store Deployment Script
# 
# This script builds an iOS Archive (.ipa) and automatically uploads it 
# to App Store Connect using fastlane with optional automatic submission for review.
#
# PREREQUISITES:
# 1. Create an App Store Connect API Key:
#    - Go to App Store Connect > Users and Access > Integrations > App Store Connect API
#    - Create a new API key with "Admin" or "Developer" role
#    - Download the .p8 private key file
# 2. Configure .env file with:
#    - APP_STORE_CONNECT_API_KEY_PATH: path to your .p8 key file
#    - APP_STORE_CONNECT_API_KEY_ID: your API key ID
#    - APP_STORE_CONNECT_API_ISSUER_ID: your issuer ID
#    - IOS_APP_IDENTIFIER: your app bundle ID (e.g., fr.axiomteam.gecko)
#    - APP_STORE_RELEASE_STATUS: release behavior (auto, manual, hold) [optional]
#
# ALTERNATIVE AUTHENTICATION (deprecated, use API key instead):
#    - APPLE_ID: your Apple ID email
#    - APP_SPECIFIC_PASSWORD: app-specific password
#    - BUNDLE_ID: your app bundle ID
#
# USAGE:
#   ./scripts/deploy-ios.sh                         # Deploy and submit for review
#   ./scripts/deploy-ios.sh --validate-only         # Validate only (no upload)
#   ./scripts/deploy-ios.sh -v                      # Validate only (short form)
#   ./scripts/deploy-ios.sh --skip-review           # Upload only (don't submit for review)
#   ./scripts/deploy-ios.sh --changelog "Bug fixes" # With changelog
#   ./scripts/deploy-ios.sh --auto-release          # Auto-release after approval
#
# The script will:
# - Extract version from pubspec.yaml
# - Install fastlane if needed
# - Build the iOS Archive
# - Upload to App Store Connect
# - Optionally submit for review
#
# Compatible with macOS (iOS development requires macOS)

set -e

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to setup PATH for Ruby gems on macOS
setup_ruby_path() {
    # Add common Ruby gem paths for Homebrew on macOS
    export PATH="/opt/homebrew/lib/ruby/gems/3.4.0/bin:/opt/homebrew/lib/ruby/gems/3.3.0/bin:/opt/homebrew/lib/ruby/gems/3.2.0/bin:$PATH"
    export PATH="/usr/local/lib/ruby/gems/3.4.0/bin:/usr/local/lib/ruby/gems/3.3.0/bin:/usr/local/lib/ruby/gems/3.2.0/bin:$PATH"
    # System Ruby
    export PATH="/usr/local/bin:$PATH"
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
        METADATA_DIR="/tmp/fastlane_metadata/en-US"
        mkdir -p "$METADATA_DIR"
        
        # Create release notes file
        echo "$CHANGELOG_TEXT" > "$METADATA_DIR/release_notes.txt"
        echo "Created changelog file: $METADATA_DIR/release_notes.txt"
        
        # Set metadata path for fastlane
        FASTLANE_METADATA_PATH="/tmp/fastlane_metadata"
        return 0
    else
        # If no changelog provided but we're submitting for review, use a default one
        if [ "$SKIP_REVIEW" != "true" ] && [ "$APP_STORE_RELEASE_STATUS" != "hold" ]; then
            echo "Warning: No changelog provided, but App Store Connect requires 'What's New' for review submission."
            echo "Using default changelog: 'Bug fixes and improvements'"
            
            # Create temporary metadata directory structure
            METADATA_DIR="/tmp/fastlane_metadata/en-US"
            mkdir -p "$METADATA_DIR"
            
            # Create release notes file with default content
            echo "Bug fixes and improvements" > "$METADATA_DIR/release_notes.txt"
            echo "Created default changelog file: $METADATA_DIR/release_notes.txt"
            
            # Set metadata path for fastlane
            FASTLANE_METADATA_PATH="/tmp/fastlane_metadata"
            return 0
        else
            # No changelog needed for upload-only mode
            FASTLANE_METADATA_PATH=""
            return 0
        fi
    fi
}

# Function to parse command line arguments
parse_arguments() {
    VALIDATE_ONLY=""
    SKIP_REVIEW=""
    AUTO_RELEASE=""
    CHANGELOG_TEXT=""
    
    # Default behavior: submit for review
    SUBMIT_FOR_REVIEW="--submit_for_review"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --validate-only|-v)
                VALIDATE_ONLY="--verify_only"
                echo "Running in validation mode (no actual upload)..."
                shift
                ;;
            --skip-review|-s)
                SKIP_REVIEW="true"
                SUBMIT_FOR_REVIEW=""
                echo "Will skip review submission (upload only)..."
                shift
                ;;
            --auto-release|-a)
                AUTO_RELEASE="--automatic_release"
                echo "Will auto-release after approval..."
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
    echo "iOS App Store Deployment Script"
    echo ""
    echo "USAGE:"
    echo "  $0                                   Deploy and submit for review"
    echo "  $0 --validate-only                  Validate only (no upload)"
    echo "  $0 -v                               Validate only (short form)"
    echo "  $0 --skip-review                    Upload only (don't submit for review)"
    echo "  $0 -s                               Skip review (short form)"
    echo "  $0 --auto-release                   Auto-release after approval"
    echo "  $0 -a                               Auto-release (short form)"
    echo "  $0 --changelog \"Bug fixes\"          Deploy with changelog"
    echo "  $0 -c \"New features added\"          Deploy with changelog (short form)"
    echo "  $0 --changelog \"Fix\" --auto-release  Submit with changelog and auto-release"
    echo "  $0 --help                           Show this help"
    echo ""
    echo "IMPORTANT NOTES:"
    echo "  • App Store Connect requires a 'What's New' description for review submissions"
    echo "  • If no --changelog is provided, a default 'Bug fixes and improvements' will be used"
    echo "  • Use --skip-review to upload without submitting for review if you prefer to add changelog manually"
    echo ""
    echo "ENVIRONMENT VARIABLES (App Store Connect API - Recommended):"
    echo "  APP_STORE_CONNECT_API_KEY_PATH      Path to .p8 key file"
    echo "  APP_STORE_CONNECT_API_KEY_ID        API Key ID"
    echo "  APP_STORE_CONNECT_API_ISSUER_ID     Issuer ID"
    echo "  IOS_APP_IDENTIFIER                  iOS bundle identifier"
    echo "  APP_STORE_RELEASE_STATUS            Release behavior (auto, manual, hold)"
    echo ""
    echo "LEGACY ENVIRONMENT VARIABLES (Apple ID - Deprecated):"
    echo "  APPLE_ID                            Apple ID email"
    echo "  APP_SPECIFIC_PASSWORD               App-specific password"
    echo "  BUNDLE_ID                           iOS bundle identifier"
    echo ""
    echo "RELEASE STATUS OPTIONS:"
    echo "  auto     - Automatically release after approval"
    echo "  manual   - Release manually after approval"
    echo "  hold     - Hold for manual release (don't submit for review)"
}

# Function to cleanup temporary files
cleanup() {
    echo "Cleaning up temporary files..."
    
    # Clean up Info.plist
    if [ -f "ios/Runner/Info.plist" ]; then
        git checkout ios/Runner/Info.plist 2>/dev/null || true
    fi
    
    # Clean up temporary files
    if [ -f "/tmp/fastlane_appfile" ]; then
        rm -f "/tmp/fastlane_appfile"
    fi
    if [ -f "/tmp/changelog_${BUILD}.txt" ]; then
        rm -f "/tmp/changelog_${BUILD}.txt"
    fi
    if [ -d "/tmp/fastlane_metadata" ]; then
        rm -rf "/tmp/fastlane_metadata"
    fi
    
    # Clean up temporary API key JSON file
    if [ -n "$TEMP_API_KEY_JSON" ] && [ -f "$TEMP_API_KEY_JSON" ]; then
        rm -f "$TEMP_API_KEY_JSON"
    fi
}

# Parse command line arguments first
parse_arguments "$@"

# Trap ERR and EXIT signals to ensure cleanup
trap cleanup ERR EXIT

# Check if running on macOS (required for iOS development)
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "Error: iOS deployment requires macOS"
    exit 1
fi

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | sed 's/#.*//g' | xargs)
else
    echo "Please create a .env file with required App Store Connect credentials"
    exit 1
fi

# Determine authentication method and validate
if [ -n "$APP_STORE_CONNECT_API_KEY_PATH" ] && [ -n "$APP_STORE_CONNECT_API_KEY_ID" ] && [ -n "$APP_STORE_CONNECT_API_ISSUER_ID" ]; then
    echo "Using App Store Connect API authentication"
    AUTH_METHOD="api_key"
    
    # Check if API key file exists
    if [ ! -f "$APP_STORE_CONNECT_API_KEY_PATH" ]; then
        echo "Error: App Store Connect API key file not found at: $APP_STORE_CONNECT_API_KEY_PATH"
        exit 1
    fi
    
    # Set app identifier
    if [ -n "$IOS_APP_IDENTIFIER" ]; then
        APP_IDENTIFIER="$IOS_APP_IDENTIFIER"
    else
        echo "Error: IOS_APP_IDENTIFIER is required when using API key authentication"
        exit 1
    fi
    
elif [ -n "$APPLE_ID" ] && [ -n "$APP_SPECIFIC_PASSWORD" ] && [ -n "$BUNDLE_ID" ]; then
    echo "Using legacy Apple ID authentication (deprecated - consider switching to API key)"
    AUTH_METHOD="apple_id"
    APP_IDENTIFIER="$BUNDLE_ID"
    
else
    echo "Error: Missing authentication credentials."
    echo "Please configure either:"
    echo "  1. App Store Connect API (recommended):"
    echo "     - APP_STORE_CONNECT_API_KEY_PATH"
    echo "     - APP_STORE_CONNECT_API_KEY_ID"
    echo "     - APP_STORE_CONNECT_API_ISSUER_ID"
    echo "     - IOS_APP_IDENTIFIER"
    echo "  2. Apple ID (deprecated):"
    echo "     - APPLE_ID"
    echo "     - APP_SPECIFIC_PASSWORD"
    echo "     - BUNDLE_ID"
    exit 1
fi

# Set default release behavior if not specified
if [ -z "$APP_STORE_RELEASE_STATUS" ]; then
    APP_STORE_RELEASE_STATUS="manual"
fi

# Get version from pubspec.yaml
fVersion=$(grep "version: " pubspec.yaml | awk '{ print $2 }')
VERSION=$(awk -F '+' '{ print $1 }' <<<$fVersion)
BUILD=$(awk -F '+' '{ print $2 }' <<<$fVersion)

echo "Building Gecko iOS IPA v${VERSION}+${BUILD}"
echo "App identifier: ${APP_IDENTIFIER}"
echo "Release behavior: ${APP_STORE_RELEASE_STATUS}"
if [ "$SKIP_REVIEW" = "true" ]; then
    echo "Submission mode: Upload only (skip review)"
else
    echo "Submission mode: Submit for review after upload"
fi
if [ -n "$CHANGELOG_TEXT" ]; then
    echo "Changelog: \"$CHANGELOG_TEXT\""
fi

# Check fastlane installation
check_fastlane

# Temporarily replace build name and number in Info.plist
echo "Updating Info.plist with version ${VERSION} and build number ${BUILD}"
sed -i '' "s|\$(FLUTTER_BUILD_NAME)|${VERSION}|g" ios/Runner/Info.plist
sed -i '' "s|\$(FLUTTER_BUILD_NUMBER)|${BUILD}|g" ios/Runner/Info.plist

# Get dependencies
echo "Getting Flutter dependencies..."
fvm flutter pub get

# Build iOS Archive
echo "Building iOS Archive..."
fvm flutter build ipa \
    --release \
    --build-name=$VERSION \
    --build-number=$BUILD \
    --export-options-plist=ios/ExportOptions.plist

# Path to the built IPA
IPA_PATH="build/ios/ipa/gecko.ipa"
if [ ! -f "$IPA_PATH" ]; then
    echo "IPA file not found at $IPA_PATH"
    exit 1
fi

echo "IPA built successfully at: $IPA_PATH"

# Create changelog file if provided
create_changelog_file

# Upload to App Store Connect using fastlane deliver
echo "Uploading to App Store Connect..."

# Prepare fastlane command with authentication
if [ "$AUTH_METHOD" = "api_key" ]; then
    # Create a temporary JSON file for the API key using Python for proper JSON encoding
    TEMP_API_KEY_JSON="/tmp/api_key_$$.json"
    
    # Use Python to create proper JSON (handles escaping automatically)
    python3 -c "
import json
import sys

# Read the private key content
with open('$APP_STORE_CONNECT_API_KEY_PATH', 'r') as f:
    key_content = f.read()

# Create the JSON structure
api_key_data = {
    'key_id': '$APP_STORE_CONNECT_API_KEY_ID',
    'issuer_id': '$APP_STORE_CONNECT_API_ISSUER_ID',
    'key': key_content
}

# Write the JSON file
with open('$TEMP_API_KEY_JSON', 'w') as f:
    json.dump(api_key_data, f, indent=2)
"
    
    FASTLANE_CMD="fastlane deliver \
        --api_key_path \"$TEMP_API_KEY_JSON\" \
        --app_identifier \"$APP_IDENTIFIER\""
    
    echo "Using App Store Connect API key authentication via temporary JSON file"
else
    FASTLANE_CMD="fastlane deliver \
        --username \"$APPLE_ID\" \
        --app_identifier \"$APP_IDENTIFIER\""
    # Set app-specific password environment variable
    export FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD="$APP_SPECIFIC_PASSWORD"
fi

# Add common parameters
FASTLANE_CMD="$FASTLANE_CMD \
    --ipa \"$IPA_PATH\" \
    --skip_screenshots \
    --skip_metadata \
    --precheck_include_in_app_purchases false \
    --reject_if_possible true"

# Add changelog-related parameters
if [ -n "$FASTLANE_METADATA_PATH" ]; then
    echo "Including changelog in upload..."
    FASTLANE_CMD="$FASTLANE_CMD --metadata_path \"$FASTLANE_METADATA_PATH\""
fi

# Add release behavior parameters
if [ "$SKIP_REVIEW" = "true" ]; then
    echo "Skipping review submission - upload only"
elif [ "$APP_STORE_RELEASE_STATUS" = "hold" ]; then
    echo "Configured to hold release - uploading only, not submitting for review"
    SUBMIT_FOR_REVIEW=""
else
    # Default behavior or explicit submission
    case "$APP_STORE_RELEASE_STATUS" in
        auto)
            if [ -n "$AUTO_RELEASE" ]; then
                FASTLANE_CMD="$FASTLANE_CMD $SUBMIT_FOR_REVIEW --automatic_release"
            else
                FASTLANE_CMD="$FASTLANE_CMD $SUBMIT_FOR_REVIEW --automatic_release"
            fi
            ;;
        manual|*)
            if [ -n "$AUTO_RELEASE" ]; then
                FASTLANE_CMD="$FASTLANE_CMD $SUBMIT_FOR_REVIEW --automatic_release"
            else
                FASTLANE_CMD="$FASTLANE_CMD $SUBMIT_FOR_REVIEW --automatic_release false"
            fi
            ;;
    esac
fi

# Add validate_only flag if set
if [ -n "$VALIDATE_ONLY" ]; then
    FASTLANE_CMD="$FASTLANE_CMD $VALIDATE_ONLY"
fi

# Add force flag to skip HTML preview
FASTLANE_CMD="$FASTLANE_CMD --force"

# Execute fastlane command
eval $FASTLANE_CMD

if [ $? -eq 0 ]; then
    if [ -n "$VALIDATE_ONLY" ]; then
        echo "Validation completed successfully!"
        echo "IPA is ready for upload to App Store Connect"
    else
        echo "Successfully uploaded IPA to App Store Connect"
        echo ""
        
                 # Determine what happened based on configuration
         if [ "$SKIP_REVIEW" = "true" ] || [ "$APP_STORE_RELEASE_STATUS" = "hold" ]; then
             echo "📦 Build uploaded successfully!"
             echo "   ⚠️  Build NOT submitted for review - you need to manually submit it:"
             echo "   1. Go to App Store Connect"
             echo "   2. Select your app"
             echo "   3. Go to App Store > Prepare for Submission"
             echo "   4. Review and submit for review"
         else
             # Check if auto-release is enabled
             if [[ "$FASTLANE_CMD" == *"--automatic_release true"* ]] || [ "$APP_STORE_RELEASE_STATUS" = "auto" ]; then
                 echo "🚀 Build submitted for review and will auto-release after approval!"
                 echo "   Your app update will go live automatically once approved by Apple."
             else
                 echo "📋 Build submitted for review!"
                 echo "   You'll need to manually release it after Apple approval."
                 echo "   Go to App Store Connect > Your App > App Store > Prepare for Submission"
             fi
         fi
    fi
    echo ""
    echo "Version: ${VERSION}+${BUILD}"
    echo "Bundle ID: ${APP_IDENTIFIER}"
    if [ -n "$CHANGELOG_TEXT" ]; then
        echo "Changelog: \"$CHANGELOG_TEXT\""
    fi
else
    if [ -n "$VALIDATE_ONLY" ]; then
        echo "Validation failed - please check your configuration"
    else
        echo "❌ Failed to upload or submit IPA to App Store Connect"
        echo ""
        echo "Common solutions:"
        echo "  • If missing 'whatsNew' error: The build was uploaded but submission failed"
        echo "    → Go to App Store Connect and manually add 'What's New' description"
        echo "    → Or re-run with: $0 --changelog \"Your update description\""
        echo "  • If authentication error: Check your .env file credentials"
        echo "  • If build processing error: Wait a few minutes and try again"
        echo "  • If copyright date warning: Update your app metadata in App Store Connect"
        echo ""
        echo "🔍 Check the error messages above for specific details"
    fi
    exit 1
fi

if [ -n "$VALIDATE_ONLY" ]; then
    echo "iOS validation completed successfully!"
else
    echo "iOS deployment completed successfully!"
fi
