#!/bin/bash

# Helper script to encode API keys for GitLab CI/CD variables
# Usage: ./scripts/encode-keys.sh

set -e

echo "🔐 Gecko CI/CD Key Encoder"
echo "=========================="
echo ""
echo "This script helps you encode your API keys for secure storage in GitLab CI/CD variables."
echo "The encoded keys can be marked as 'Masked' in GitLab for better security."
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to show help
show_help() {
    echo "Gecko CI/CD Key Encoder"
    echo ""
    echo "USAGE:"
    echo "  $0                                    Interactive mode"
    echo "  $0 --google-play /path/to/key.json   Encode Google Play key"
    echo "  $0 --app-store /path/to/key.p8       Encode App Store key"
    echo "  $0 --android-keystore /path/to/key.jks  Encode Android keystore (in android/app/)"
    echo "  $0 --android-properties /path/to/key.properties  Encode Android properties"
    echo "  $0 --file /path/to/file VAR_NAME     Encode custom file"
    echo "  $0 --help                            Show this help"
    echo ""
    echo "EXAMPLES:"
    echo "  $0 -g android/gecko-466310-270a2d292cbf.json"
    echo "  $0 -a ios/AuthKey_ABC123.p8"
    echo "  $0 -k android/app/axiom-key2.jks"
    echo "  $0 -p android/key.properties"
    echo "  $0 -f /path/to/secret.txt MY_SECRET_BASE64"
    echo ""
    echo "SECURITY NOTES:"
    echo "  • Base64 encoding allows GitLab to mask the variables"
    echo "  • Always mark encoded variables as 'Masked' and 'Protected'"
    echo "  • Never commit the original key files to your repository"
    echo "  • Store original keys securely (password manager, encrypted storage)"
}

# Function to encode a file
encode_file() {
    local file_path="$1"
    local var_name="$2"
    
    if [ ! -f "$file_path" ]; then
        echo -e "${YELLOW}⚠️  File not found: $file_path${NC}"
        return 1
    fi
    
    echo -e "${BLUE}📁 Encoding: $file_path${NC}"
    echo -e "${GREEN}Variable name: $var_name${NC}"
    echo ""
    echo "Encoded value (copy this to GitLab CI/CD variables):"
    echo "---------------------------------------------------"
    
    # Encode and remove newlines
    base64 -i "$file_path" | tr -d '\n'
    
    echo ""
    echo "---------------------------------------------------"
    echo ""
    echo -e "${GREEN}✅ Copy the encoded value above and paste it as the value for variable: $var_name${NC}"
    echo -e "${YELLOW}💡 Remember to mark this variable as 'Masked' and 'Protected' in GitLab${NC}"
    echo ""
}

# Check if any arguments provided
if [ $# -eq 0 ]; then
    echo "Available options:"
    echo ""
    echo "1. Encode Google Play JSON key"
    echo "2. Encode App Store Connect .p8 key"
    echo "3. Encode Android keystore"
    echo "4. Encode Android key.properties"
    echo "5. Encode custom file"
    echo "6. Show help"
    echo ""
    read -p "Select an option (1-6): " choice
    
    case $choice in
        1)
            read -p "Enter path to Google Play JSON key file: " json_path
            encode_file "$json_path" "GOOGLE_PLAY_JSON_KEY_BASE64"
            ;;
        2)
            read -p "Enter path to App Store Connect .p8 key file: " p8_path
            encode_file "$p8_path" "APP_STORE_CONNECT_API_KEY_BASE64"
            ;;
        3)
            read -p "Enter path to Android keystore file: " keystore_path
            encode_file "$keystore_path" "ANDROID_KEYSTORE_BASE64"
            ;;
        4)
            read -p "Enter path to Android key.properties file: " keyprops_path
            encode_file "$keyprops_path" "ANDROID_KEY_PROPERTIES_BASE64"
            ;;
        5)
            read -p "Enter path to file: " custom_path
            read -p "Enter variable name: " var_name
            encode_file "$custom_path" "$var_name"
            ;;
        6)
            show_help
            ;;
        *)
            echo "Invalid option"
            exit 1
            ;;
    esac
else
    # Command line arguments provided
    case "$1" in
        --google-play|-g)
            if [ -n "$2" ]; then
                encode_file "$2" "GOOGLE_PLAY_JSON_KEY_BASE64"
            else
                echo "Error: Please provide path to Google Play JSON key file"
                echo "Usage: $0 --google-play /path/to/key.json"
                exit 1
            fi
            ;;
        --app-store|-a)
            if [ -n "$2" ]; then
                encode_file "$2" "APP_STORE_CONNECT_API_KEY_BASE64"
            else
                echo "Error: Please provide path to App Store .p8 key file"
                echo "Usage: $0 --app-store /path/to/key.p8"
                exit 1
            fi
            ;;
        --android-keystore|-k)
            if [ -n "$2" ]; then
                encode_file "$2" "ANDROID_KEYSTORE_BASE64"
            else
                echo "Error: Please provide path to Android keystore file"
                echo "Usage: $0 --android-keystore /path/to/keystore.jks"
                exit 1
            fi
            ;;
        --android-properties|-p)
            if [ -n "$2" ]; then
                encode_file "$2" "ANDROID_KEY_PROPERTIES_BASE64"
            else
                echo "Error: Please provide path to Android key.properties file"
                echo "Usage: $0 --android-properties /path/to/key.properties"
                exit 1
            fi
            ;;
        --file|-f)
            if [ -n "$2" ] && [ -n "$3" ]; then
                encode_file "$2" "$3"
            else
                echo "Error: Please provide file path and variable name"
                echo "Usage: $0 --file /path/to/file VARIABLE_NAME"
                exit 1
            fi
            ;;
        --help|-h)
            show_help
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
fi

echo -e "${BLUE}🔒 Security Reminder:${NC}"
echo "• Mark the variable as 'Masked' in GitLab CI/CD settings"
echo "• Mark the variable as 'Protected' to limit access to protected branches/tags"
echo "• Never commit the original key files to your repository"
echo ""
