# iOS Build Fix Implementation

This document summarizes the changes made to fix the iOS build issues in the CI pipeline.

## Problem Summary

The iOS build was failing during the IPA export phase with:
- `errSecInternalComponent` (exit status 70) - certificate chain resolution issues
- "Private key is not installed in your keychain" errors
- Conflicting automatic/manual code signing settings
- Duplicate provisioning profile entries

## Solution Implemented

### 1. Fastfile Rewrite (`ios/fastlane/Fastfile`)

**Key Changes:**
- **Ephemeral keychain management**: Creates a dedicated keychain per CI job with proper cleanup
- **Fastlane Match integration**: Uses centralized certificate/profile management
- **Forced manual signing**: Eliminates automatic signing conflicts
- **Proper API key handling**: Uses App Store Connect API key consistently
- **Better error handling**: Improved logging and cleanup on failure

**New lanes:**
- `build`: Main build lane with keychain management and match
- `deliver`: Upload to App Store Connect
- `beta`: Build and upload to TestFlight

### 2. CI Configuration Update (`.gitlab-ci.yml`)

**Simplified `build:ios` job:**
- Removed manual `sed` replacements (now handled via ENV variables)
- Cleaner before_script with proper Flutter/Ruby/CocoaPods setup
- Direct fastlane execution without complex error handling

### 3. Xcode Project Cleanup (`ios/Runner.xcodeproj/project.pbxproj`)

**Removed conflicting settings:**
- Changed hardcoded `CODE_SIGN_STYLE = Automatic` to `"$(inherited)"`
- Changed hardcoded `DEVELOPMENT_TEAM = 2P2PNF45VD` to `"$(inherited)"`
- Changed hardcoded `PROVISIONING_PROFILE_SPECIFIER = ""` to `"$(inherited)"`
- Removed SDK-specific overrides

### 4. Export Options Fix (`ios/ExportOptions.plist`)

**Fixed duplicate entries:**
- Removed duplicate `provisioningProfiles` dictionary
- Kept only the correct profile reference

## Required GitLab CI Variables

You need to set these variables in your GitLab project:

### Existing (already configured):
- `APPLE_TEAM_ID` ✅
- `IOS_APP_IDENTIFIER` ✅ 
- `APP_STORE_CONNECT_API_KEY_ID` ✅
- `APP_STORE_CONNECT_API_ISSUER_ID` ✅
- `APP_STORE_CONNECT_API_KEY_BASE64` ✅

### New variables needed:
- `MATCH_GIT_URL`: Private Git repository for storing certificates/profiles
- `MATCH_PASSWORD`: Encryption password for match files
- `RUNNER_KEYCHAIN_PASSWORD`: Password for ephemeral keychain (can be any secure string)

## Setting Up Fastlane Match

### One-time setup (run on a secure machine):

```bash
cd ios
bundle exec fastlane match init
# Choose: git storage, provide your private repo URL

# Generate and store certificates/profiles
MATCH_PASSWORD=your-secure-password bundle exec fastlane match appstore \
  --app_identifier fr.axiom-team.gecko \
  --team_id YOUR_TEAM_ID
```

This creates:
- Distribution certificate + private key
- App Store provisioning profile
- Encrypted storage in your private Git repo

### Alternative: Manual Certificate Storage

If you prefer not to use match, you can store certificates as CI variables:
- `IOS_DIST_P12_BASE64`: Distribution certificate + private key (base64 encoded)
- `IOS_DIST_P12_PASSWORD`: P12 file password
- `IOS_PROFILE_APPSTORE_BASE64`: Provisioning profile (base64 encoded)

## Why This Fixes the Issues

1. **Certificate Chain Resolution**: Ephemeral keychain includes System.keychain in search list, providing Apple's root certificates
2. **Private Key Access**: Match installs complete certificate + private key pairs
3. **Signing Consistency**: Forces manual signing throughout, eliminating automatic/manual conflicts
4. **Clean State**: Each CI job starts with a fresh keychain, no persistent state issues

## Testing the Fix

1. Set up the required CI variables
2. Initialize fastlane match (one-time setup)
3. Push a commit or create a tag to trigger the iOS build
4. The build should now complete successfully without certificate errors

## Rollback Plan

If issues occur, you can temporarily revert to the previous approach by:
1. Restoring the original Fastfile from git history
2. Restoring the original CI job configuration
3. The Xcode project changes are safe to keep as they use inherited values
