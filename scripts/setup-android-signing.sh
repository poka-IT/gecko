#!/bin/bash

# Script to setup Android signing for CI environment
# Creates keystore file from base64 encoded CI variable

set -e

echo "🔐 Setting up Android signing..."

# Check if we're in CI environment
if [ "$CI" = "true" ]; then
    echo "📦 CI detected - creating keystore from base64"
    
    # Check if signing variables are available
    if [ -z "$ANDROID_KEYSTORE_BASE64" ] || [ -z "$ANDROID_KEY_PROPERTIES_BASE64" ]; then
        echo "⚠️  Android signing variables not found - building debug APK instead"
        echo "   Set ANDROID_KEYSTORE_BASE64 and ANDROID_KEY_PROPERTIES_BASE64 for release builds"
        
        # Create a dummy key.properties that will make gradle use debug signing
        cat > android/key.properties << EOF
# Debug signing (CI fallback)
storePassword=debug
keyPassword=debug  
keyAlias=debug
storeFile=debug
EOF
        echo "✅ Debug signing configured"
        return 0
    fi
    
    # Create keystore file from base64
    echo "📦 Creating keystore from base64..."
    echo "$ANDROID_KEYSTORE_BASE64" | base64 -d > android/app/axiom-key2.jks || {
        echo "❌ Failed to decode keystore from base64"
        exit 1
    }
    
    # Create key.properties from base64 encoded CI variable
    echo "📝 Creating key.properties..."
    echo "$ANDROID_KEY_PROPERTIES_BASE64" | base64 -d > android/key.properties || {
        echo "❌ Failed to create key.properties"
        exit 1
    }
    
    # Debug: Show the actual content of key.properties
    echo "🔍 Debug - key.properties content:"
    cat android/key.properties
    
    # Verify keystore was created
    if [ -f "android/app/axiom-key2.jks" ]; then
        echo "✅ Android keystore created successfully"
    else
        echo "❌ Keystore file not found after creation"
        exit 1
    fi
    
    # Verify key.properties was created
    if [ -f "android/key.properties" ]; then
        echo "✅ Key properties configured successfully"
        echo "📋 Key properties (passwords hidden):"
        cat android/key.properties | grep -v Password | grep -v password || echo "  (all properties contain passwords)"
    else
        echo "❌ Key properties file not found after creation"
        exit 1
    fi
else
    echo "🏠 Local environment detected - using existing keystore"
    
    # Check if local keystore exists
    if [ ! -f "android/app/axiom-key2.jks" ]; then
        echo "⚠️  Local keystore not found at android/app/axiom-key2.jks"
        echo "   Make sure your keystore is properly configured for local builds"
    fi
fi
