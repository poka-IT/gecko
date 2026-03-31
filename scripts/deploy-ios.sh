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
#   ./scripts/deploy-ios.sh                         # Deploy to App Store and submit for review
#   ./scripts/deploy-ios.sh --beta                  # Deploy to TestFlight (beta testing)
#   ./scripts/deploy-ios.sh --validate-only         # Validate only (no upload)
#   ./scripts/deploy-ios.sh --skip-review           # Upload only (don't submit for review)
#   ./scripts/deploy-ios.sh --changelog "Bug fixes" # With English changelog
#   ./scripts/deploy-ios.sh --auto-release          # Auto-release after approval
#
# MULTILINGUAL CHANGELOG SUPPORT:
#   CHANGELOG_TEXT="Bug fixes" CHANGELOG_TEXT_FR="Corrections de bugs" ./scripts/deploy-ios.sh
#   # Or set environment variables:
#   export CHANGELOG_TEXT="Bug fixes and improvements"
#   export CHANGELOG_TEXT_FR="Corrections de bugs et améliorations"
#   ./scripts/deploy-ios.sh
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

# Setup Ruby PATH immediately at script start (before any checks)
# Prioritize Homebrew Ruby over system Ruby
if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
    export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
fi
if [ -d "/usr/local/opt/ruby/bin" ]; then
    export PATH="/usr/local/opt/ruby/bin:$PATH"
fi

# Add common Ruby gem paths for Homebrew on macOS
export PATH="/opt/homebrew/lib/ruby/gems/3.4.0/bin:/opt/homebrew/lib/ruby/gems/3.3.0/bin:/opt/homebrew/lib/ruby/gems/3.2.0/bin:$PATH"
export PATH="/usr/local/lib/ruby/gems/3.4.0/bin:/usr/local/lib/ruby/gems/3.3.0/bin:/usr/local/lib/ruby/gems/3.2.0/bin:$PATH"

# Add user gem installation directory
if command -v ruby >/dev/null 2>&1; then
    USER_GEM_HOME="$(ruby -e 'puts Gem.user_dir' 2>/dev/null)/bin"
    if [ -d "$USER_GEM_HOME" ]; then
        export PATH="$USER_GEM_HOME:$PATH"
    fi
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to setup PATH for Ruby gems on macOS
setup_ruby_path() {
    # This function is now mostly redundant as PATH is set at script start,
    # but kept for backwards compatibility and to refresh paths after gem installations
    
    # Prioritize Homebrew Ruby over system Ruby
    if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
        export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
    fi
    if [ -d "/usr/local/opt/ruby/bin" ]; then
        export PATH="/usr/local/opt/ruby/bin:$PATH"
    fi
    
    # Add common Ruby gem paths for Homebrew on macOS
    export PATH="/opt/homebrew/lib/ruby/gems/3.4.0/bin:/opt/homebrew/lib/ruby/gems/3.3.0/bin:/opt/homebrew/lib/ruby/gems/3.2.0/bin:$PATH"
    export PATH="/usr/local/lib/ruby/gems/3.4.0/bin:/usr/local/lib/ruby/gems/3.3.0/bin:/usr/local/lib/ruby/gems/3.2.0/bin:$PATH"
    
    # Add user gem installation directory
    if command -v ruby >/dev/null 2>&1; then
        USER_GEM_HOME="$(ruby -e 'puts Gem.user_dir' 2>/dev/null)/bin"
        if [ -d "$USER_GEM_HOME" ]; then
            export PATH="$USER_GEM_HOME:$PATH"
        fi
    fi
}

# Function to install fastlane
install_fastlane() {
    echo "Installing fastlane..."
    if command_exists gem; then
        echo "Installing fastlane using gem..."
        echo "Using Ruby: $(which ruby)"
        echo "Using Gem: $(which gem)"
        # Install required dependencies first
        gem install sysrandom -NV
        gem install fastlane-sirp -NV
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
            echo "  gem install sysrandom -NV"
            echo "  gem install fastlane-sirp -NV"
            echo "  gem install fastlane -NV"
            echo ""
            echo "Or ensure it's in your PATH. Common locations on macOS:"
            echo "  /opt/homebrew/lib/ruby/gems/*/bin/fastlane"
            echo "  /usr/local/lib/ruby/gems/*/bin/fastlane"
            echo "  ~/.gem/ruby/*/bin/fastlane (user installation)"
            echo ""
            echo "You can also try: which fastlane"
            exit 1
        fi
    else
        # Fastlane exists, but verify dependencies are installed
        echo "Verifying fastlane dependencies..."
        echo "Using Ruby: $(which ruby)"
        echo "Using Gem: $(which gem)"
        
        # Test if fastlane actually works by running a simple command
        if ! fastlane --version >/dev/null 2>&1; then
            echo "Fastlane found but not working properly. Installing missing dependencies..."
            # Install fastlane which will pull in all missing dependencies
            gem install fastlane -NV
        else
            echo "Fastlane is working correctly."
        fi
    fi
    
    echo "Using fastlane: $(which fastlane)"
}

# Function to create changelog file if provided
create_changelog_file() {
    # Declare as global variables
    FASTLANE_METADATA_PATH=""
    
    # Determine the changelog text to use (English)
    local changelog_text_en=""
    local changelog_text_fr=""
    
    if [ -n "$CHANGELOG_TEXT" ]; then
        changelog_text_en="$CHANGELOG_TEXT"
        echo "Using provided English changelog: \"$changelog_text_en\""
    else
        # If no changelog provided but we're submitting for review, use a default one
        if [ "$SKIP_REVIEW" != "true" ] && [ "$APP_STORE_RELEASE_STATUS" != "hold" ]; then
            changelog_text_en="Bug fixes and improvements"
            echo "Warning: No changelog provided, but App Store Connect requires 'What's New' for review submission."
            echo "Using default English changelog: \"$changelog_text_en\""
        else
            # No changelog needed for upload-only mode
            FASTLANE_METADATA_PATH=""
            export FASTLANE_METADATA_PATH
            return 0
        fi
    fi
    
    # Determine French changelog text
    if [ -n "$CHANGELOG_TEXT_FR" ]; then
        changelog_text_fr="$CHANGELOG_TEXT_FR"
        echo "Using provided French changelog: \"$changelog_text_fr\""
    else
        # Use default French translation if no specific French changelog provided
        if [ "$SKIP_REVIEW" != "true" ] && [ "$APP_STORE_RELEASE_STATUS" != "hold" ]; then
            changelog_text_fr="Corrections de bugs et améliorations"
            echo "Using default French changelog: \"$changelog_text_fr\""
        fi
    fi
    
    # Create temporary metadata directory structure for both languages
    METADATA_DIR_EN="/tmp/fastlane_metadata/en-US"
    METADATA_DIR_FR="/tmp/fastlane_metadata/fr-FR"
    mkdir -p "$METADATA_DIR_EN"
    mkdir -p "$METADATA_DIR_FR"
    
    # Create the release notes files (What's New field) for both languages
    echo "$changelog_text_en" > "$METADATA_DIR_EN/release_notes.txt"
    echo "$changelog_text_fr" > "$METADATA_DIR_FR/release_notes.txt"
    echo "Created English changelog file: $METADATA_DIR_EN/release_notes.txt"
    echo "Created French changelog file: $METADATA_DIR_FR/release_notes.txt"
    
    # Create minimal required metadata files with placeholder content
    # These are only created when we need to submit for review
    if [ "$SKIP_REVIEW" != "true" ] && [ "$APP_STORE_RELEASE_STATUS" != "hold" ]; then
        # English metadata files
        echo "" > "$METADATA_DIR_EN/description.txt"
        echo "" > "$METADATA_DIR_EN/keywords.txt"
        echo "" > "$METADATA_DIR_EN/support_url.txt"
        
        # French metadata files
        echo "" > "$METADATA_DIR_FR/description.txt"
        echo "" > "$METADATA_DIR_FR/keywords.txt"
        echo "" > "$METADATA_DIR_FR/support_url.txt"
        
        # Copyright file goes at the root metadata level (not language-specific)
        echo "2025 Axiom Team" > "/tmp/fastlane_metadata/copyright.txt"
        
        echo "Created minimal metadata files for App Store submission (en-US and fr-FR)"
        echo "Added copyright metadata: 2025 Axiom Team"
    fi
    
    # Set metadata path for fastlane
    FASTLANE_METADATA_PATH="/tmp/fastlane_metadata"
    export FASTLANE_METADATA_PATH
    return 0
}

# Function to parse command line arguments
parse_arguments() {
    VALIDATE_ONLY=""
    SKIP_REVIEW=""
    AUTO_RELEASE=""
    CHANGELOG_TEXT=""
    BETA_MODE=""

    # Default behavior: submit for review
    SUBMIT_FOR_REVIEW="--submit_for_review"

    while [[ $# -gt 0 ]]; do
        case $1 in
            --beta|-b)
                BETA_MODE="true"
                echo "Beta mode: will upload to TestFlight instead of App Store..."
                shift
                ;;
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
    echo "  $0                                   Deploy to App Store and submit for review"
    echo "  $0 --beta                            Deploy to TestFlight (beta testing)"
    echo "  $0 -b                                Deploy to TestFlight (short form)"
    echo "  $0 --validate-only                   Validate only (no upload)"
    echo "  $0 --skip-review                     Upload only (don't submit for review)"
    echo "  $0 --auto-release                    Auto-release after approval"
    echo "  $0 --changelog \"Bug fixes\"           Deploy with changelog"
    echo "  $0 --beta --changelog \"Fix\"          TestFlight with changelog"
    echo "  $0 --help                            Show this help"
    echo ""
    echo "IMPORTANT NOTES:"
    echo "  • App Store Connect requires a 'What's New' description for review submissions"
    echo "  • If no --changelog is provided, a default 'Bug fixes and improvements' will be used"
    echo "  • The script automatically creates minimal required metadata files for App Store submission"
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
if [ "$BETA_MODE" = "true" ]; then
    echo "Target: TestFlight (beta)"
else
    echo "Target: App Store (production)"
    echo "Release behavior: ${APP_STORE_RELEASE_STATUS}"
    if [ "$SKIP_REVIEW" = "true" ]; then
        echo "Submission mode: Upload only (skip review)"
    else
        echo "Submission mode: Submit for review after upload"
    fi
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
echo "Creating changelog file..."
echo "SKIP_REVIEW: $SKIP_REVIEW"
echo "APP_STORE_RELEASE_STATUS: $APP_STORE_RELEASE_STATUS"
echo "CHANGELOG_TEXT: $CHANGELOG_TEXT"
create_changelog_file
echo "FASTLANE_METADATA_PATH after create_changelog_file: $FASTLANE_METADATA_PATH"

# Create API key JSON file (shared by both beta and production paths)
TEMP_API_KEY_JSON=""
if [ "$AUTH_METHOD" = "api_key" ]; then
    TEMP_API_KEY_JSON="/tmp/api_key_$$.json"
    python3 -c "
import json
with open('$APP_STORE_CONNECT_API_KEY_PATH', 'r') as f:
    key_content = f.read()
api_key_data = {
    'key_id': '$APP_STORE_CONNECT_API_KEY_ID',
    'issuer_id': '$APP_STORE_CONNECT_API_ISSUER_ID',
    'key': key_content
}
with open('$TEMP_API_KEY_JSON', 'w') as f:
    json.dump(api_key_data, f, indent=2)
"
    echo "Using App Store Connect API key authentication"
fi

if [ "$BETA_MODE" = "true" ]; then
    # ── TestFlight upload (beta) ──
    echo "Uploading to TestFlight..."

    FASTLANE_CMD="fastlane pilot upload \
        --ipa \"$IPA_PATH\" \
        --app_identifier \"$APP_IDENTIFIER\" \
        --skip_submission \
        --skip_waiting_for_build_processing"

    if [ -n "$TEMP_API_KEY_JSON" ]; then
        FASTLANE_CMD="$FASTLANE_CMD --api_key_path \"$TEMP_API_KEY_JSON\""
    else
        FASTLANE_CMD="$FASTLANE_CMD --username \"$APPLE_ID\""
        export FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD="$APP_SPECIFIC_PASSWORD"
    fi

    if [ -n "$CHANGELOG_TEXT" ]; then
        FASTLANE_CMD="$FASTLANE_CMD --changelog \"$CHANGELOG_TEXT\""
    fi

else
    # ── App Store upload (production) ──
    echo "Uploading to App Store Connect..."

    if [ "$AUTH_METHOD" = "api_key" ]; then
        FASTLANE_CMD="fastlane deliver \
            --api_key_path \"$TEMP_API_KEY_JSON\" \
            --app_identifier \"$APP_IDENTIFIER\""
    else
        FASTLANE_CMD="fastlane deliver \
            --username \"$APPLE_ID\" \
            --app_identifier \"$APP_IDENTIFIER\""
        export FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD="$APP_SPECIFIC_PASSWORD"
    fi

    # Add common parameters
    FASTLANE_CMD="$FASTLANE_CMD \
        --ipa \"$IPA_PATH\" \
        --skip_screenshots \
        --precheck_include_in_app_purchases false \
        --reject_if_possible true"

    # Add changelog-related parameters
    if [ -n "$FASTLANE_METADATA_PATH" ]; then
        echo "Including changelog and metadata in upload..."
        FASTLANE_CMD="$FASTLANE_CMD --metadata_path \"$FASTLANE_METADATA_PATH\""
    else
        FASTLANE_CMD="$FASTLANE_CMD --skip_metadata"
    fi

    # Add release behavior parameters
    if [ "$SKIP_REVIEW" = "true" ]; then
        echo "Skipping review submission - upload only"
    elif [ "$APP_STORE_RELEASE_STATUS" = "hold" ]; then
        echo "Configured to hold release - uploading only, not submitting for review"
        SUBMIT_FOR_REVIEW=""
    else
        case "$APP_STORE_RELEASE_STATUS" in
            auto)
                FASTLANE_CMD="$FASTLANE_CMD $SUBMIT_FOR_REVIEW --automatic_release"
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
fi

# Execute fastlane command
eval $FASTLANE_CMD

if [ $? -eq 0 ]; then
    if [ -n "$VALIDATE_ONLY" ]; then
        echo "Validation completed successfully!"
        echo "IPA is ready for upload"
    elif [ "$BETA_MODE" = "true" ]; then
        echo "Successfully uploaded to TestFlight!"
        echo "   Testeurs internes : disponible immédiatement"
        echo "   Testeurs externes : nécessite une review Apple (~24-48h)"
    else
        echo "Successfully uploaded IPA to App Store Connect"
        echo ""
        if [ "$SKIP_REVIEW" = "true" ] || [ "$APP_STORE_RELEASE_STATUS" = "hold" ]; then
            echo "📦 Build uploaded successfully!"
            echo "   Build NOT submitted for review - you need to manually submit it"
        elif [[ "$FASTLANE_CMD" == *"--automatic_release"* ]] && [[ "$FASTLANE_CMD" != *"--automatic_release false"* ]]; then
            echo "🚀 Build submitted for review and will auto-release after approval!"
        else
            echo "📋 Build submitted for review!"
            echo "   You'll need to manually release it after Apple approval."
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
        echo "❌ Failed to upload IPA"
        echo "   Check the error messages above for details"
    fi
    exit 1
fi

if [ -n "$VALIDATE_ONLY" ]; then
    echo "iOS validation completed successfully!"
else
    echo "iOS deployment completed successfully!"
fi
