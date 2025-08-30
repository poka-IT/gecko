# Gecko CI/CD

Automated pipeline for multi-platform build and release.

## 🚀 Quick Start

```bash
# 1. Encode API keys
./scripts/encode-keys.sh --google-play android/key.json
./scripts/encode-keys.sh --app-store ios/key.p8
./scripts/encode-keys.sh --android-keystore android/app/axiom-key2.jks
./scripts/encode-keys.sh --android-properties android/key.properties

# 2. Configure GitLab variables (Settings → CI/CD → Variables)
# 3. Create a release
./scripts/create-release.sh 1.2.3 --push
```

## 📋 Required CI/CD Variables

| Variable | Type | Description |
|----------|------|-------------|
| `GOOGLE_PLAY_JSON_KEY_BASE64` | Masked and hidden | Google Play key encoded in base64 |
| `APP_STORE_CONNECT_API_KEY_BASE64` | Masked and hidden | App Store key encoded in base64 |
| `APP_STORE_CONNECT_API_KEY_ID` | Masked and hidden | API Key ID |
| `APP_STORE_CONNECT_API_ISSUER_ID` | Masked and hidden | Issuer ID |
| `DUNITER_FORUM_API_KEY` | Masked and hidden | Duniter forum API key |
| `ANDROID_KEYSTORE_BASE64` | Masked and hidden | Android keystore encoded in base64 |
| `ANDROID_KEY_PROPERTIES_BASE64` | Masked and hidden | Android key.properties encoded in base64 |
| `ANDROID_PACKAGE_NAME` | Visible | Android package (e.g. fr.axiomteam.gecko) |
| `IOS_APP_IDENTIFIER` | Visible | iOS bundle ID |
| `DUNITER_FORUM_USERNAME` | Visible | Forum username (default: GeckoBuilds) |
| `DUNITER_FORUM_TOPIC_ID` | Visible | Topic ID (default: 9367) |

## 🔄 Pipeline

### Automatic (on `v*` tags)
1. **Build**: Android APK/AAB, iOS IPA, Linux Desktop
2. **Release**: GitLab release page with all assets

### Manual
- **Deploy**: Play Store, App Store
- **Forum**: Duniter forum announcement

## 🛠️ Local Builds

```bash
./scripts/deploy-android.sh    # Deploy to Play Store
./scripts/deploy-ios.sh        # Deploy to App Store  
./scripts/build-apk.sh         # APKs only
```

## 📱 Platforms

- **Android**: APK (v7a, v8a, x86_64) + AAB for Play Store
- **iOS**: IPA for App Store (requires macOS runner)
- **Linux**: tar.gz archive

## 🔐 Security

- JSON keys encoded in base64 for GitLab masking
- Variables marked "Masked and hidden" + "Protected"
- Access limited to protected branches/tags

## ⚡ Helpers

```bash
./scripts/check-dependencies.sh  # Check dependencies
./scripts/encode-keys.sh         # Encode API keys
./scripts/create-release.sh      # Create release
```
