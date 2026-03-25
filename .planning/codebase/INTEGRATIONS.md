# External Integrations

**Analysis Date:** 2026-03-25

## APIs & External Services

**Duniter v2s Blockchain (Primary):**
- Duniter node — WebSocket RPC (Substrate/Polkadart protocol) for real-time balance subscriptions, identity status, and transaction submission
  - SDK/Client: `durt2` package (local path `../durt2`); accessed via `Durt.i.duniter` in `lib/providers/providers.dart`
  - Protocol: WebSocket (`wss://`)
  - Connection: auto-discovered endpoints managed by durt2's `ConnectionManager`; user can set custom endpoint via `configBox.customEndpoint` (`lib/services/config_service.dart`)
  - Streams: `Durt.i.duniterConnectionStatusStream` watched in `lib/providers/connection_providers.dart`
  - Networks: `g1` (production Ḡ1v2), `gdev`, `gtest`

**Squid GraphQL Indexer:**
- Subsquid indexer — GraphQL over WebSocket for transaction history, identity search, certification lists
  - SDK/Client: `durt2`'s `SquidService`; accessed via `Durt.i.squid` in `lib/providers/providers.dart`
  - Protocol: WebSocket GraphQL (`wss://`)
  - Path: `/v1/graphql` (auto-appended in `lib/providers/connection_providers.dart`)
  - Connection: auto-discovered; user can override via `configBox.customIndexer` (`lib/services/config_service.dart`)
  - Schema: `../durt2/lib/src/models/graphql/squid/squid-schema.graphql` (referenced in `graphql.config.yaml`)
  - Client wrapper: `graphql_flutter` ^5.2.1 used internally by durt2

**Cesium+ Profile API:**
- Cesium+ pod — REST API for social identity profiles (avatar, name, geolocation, bio)
  - SDK/Client: `durt2`'s `CesiumPlusService`; accessed via `Durt.i.cesiumPlus` in `lib/providers/providers.dart`
  - Protocol: HTTPS REST
  - Usage: `lib/providers/cesium_profile_provider.dart`, `lib/providers/avatar_providers.dart`
  - Also used for certification queue sync: `lib/providers/certification_queue_provider.dart` (`_syncWithCesiumPlus`)

**Sentry Error Monitoring:**
- Sentry (axiom-team project) — crash reporting and performance monitoring
  - SDK: `sentry_flutter` ^9.13.0
  - DSN: `https://c09587b46eaa42e8b9fda28d838ed180@o496840.ingest.sentry.io/5572110` (hardcoded in `lib/main.dart`)
  - Org/project: `axiom-team` / `axiom-team`
  - Service wrapper: `lib/services/sentry_service.dart` (adds diagnostic tags, lifecycle breadcrumbs, memory pressure tracking)
  - Release tags: `gecko@{ver}+{build}` (Linux/Windows), `fr.axiomteam.gecko@{ver}+{build}` (Android), `fr.axiom-team.gecko@{ver}+{build}` (iOS/macOS)
  - Debug symbols uploaded to Sentry via `sentry_dart_plugin` during CI builds (configured in `pubspec.yaml` `sentry:` section)
  - Only enabled in release mode when user has not disabled it (`configBox.sentryEnabled`)

## Data Storage

**Databases:**

- **Hive (local key-value)** — primary app configuration and wallet metadata storage
  - Client: `hive_flutter` ^1.1.0
  - Boxes: `configBox` (app settings), `g1WalletsBox` (G1v1 wallet list), `contactsBox` (contacts), `walletHeaderDataBox` (wallet display cache)
  - Path: `~/.gecko/db/` (desktop), `getApplicationDocumentsDirectory()` (mobile)
  - Initialization: `lib/services/storage_init_service.dart`
  - Config accessor: `lib/services/config_service.dart`

- **ObjectBox (via durt2)** — blockchain entity storage (wallets, safes, cached chain data, connection endpoints)
  - Client: `durt2/objectbox.g.dart` (generated); accessed indirectly via `Durt.i.wallets`, `Durt.i.storage`
  - Used directly by: `lib/providers/safe_data_provider.dart`, `lib/providers/wallets_provider.dart`, `lib/providers/settings_provider.dart`, `lib/services/wallet_scan_service.dart`
  - Config Box: exposed as `Durt.i.configBox` in `lib/providers/providers.dart`

- **SQLite (Riverpod persist cache)** — persists Riverpod provider state across restarts
  - Client: `sqflite` ^2.4.1 + `riverpod_sqflite` ^0.4.2
  - DB file: `gecko_riverpod_cache.db` (in platform databases path)
  - Provider: `lib/providers/persist_storage_provider.dart`
  - Falls back to in-memory storage on Linux (no persistence)

**File Storage:**
- Local filesystem only — avatars at `~/.gecko/avatars/` and `~/.gecko/avatarsCache/` (desktop) or equivalent app documents directory (mobile)
- No cloud file storage

**Caching:**
- In-memory Riverpod provider cache (automatic via `flutter_riverpod`)
- Hive `wallet_header_cache` box for wallet display data (versioned; cleared on schema bump)
- Avatar image cache at `~/.gecko/avatarsCache/`

## Authentication & Identity

**PIN Security (custom):**
- 4-digit PIN authentication for wallet access
- PIN state, lockout, and failed attempts persisted in `configBox` via `lib/services/config_service.dart`
- PIN caching service: `lib/services/pin_cache_service.dart`
- Security provider: `lib/providers/pin_security_provider.dart`

**Biometric Authentication:**
- SDK: `local_auth` ^3.0.0
- Provider: `lib/providers/biometric_provider.dart`
- Platforms: Android (`local_auth_android` ^2.0.4) and iOS (`local_auth_ios` ^1.1.7)
- Falls back to PIN if biometrics unavailable

**Blockchain Cryptography:**
- Ed25519 key pairs (default) via `durt2`; `KeyPairType.ed25519` set at `Durt.init()` in `lib/main.dart`
- Sr25519 key pairs also supported (used in debug tools: `lib/utils/debug_test_wallet.dart`)
- Mnemonic generation/validation: `lib/services/mnemonic_service.dart`
- NaCl crypto: `pinenacl` ^0.6.0 (used internally by durt2 and wallet operations)
- Legacy Cesium v1 wallet import supported (password-based key derivation via `pointycastle`)

## App Updates

**Android (Play Store):**
- In-App Update API via `in_app_update` ^4.2.5
- Flexible update flow (background download)
- Detected in `lib/services/app_update_service.dart`

**Android (Sideloaded):**
- GitLab Releases API: `https://git.duniter.org/api/v4/projects/clients%2Fgecko/releases?per_page=1`
- Architecture-specific APK URL selection based on device ABI
- HTTP client: `http` ^1.6.0

**iOS (App Store):**
- iTunes Lookup API: `https://itunes.apple.com/lookup?bundleId=fr.axiom-team.gecko`
- App Store URL: `https://apps.apple.com/app/id6739944308`
- HTTP client: `http` ^1.6.0

**Desktop / Linux / macOS / Windows:**
- GitLab Releases API (same as sideloaded Android)
- Redirects to release page: `https://git.duniter.org/clients/gecko/-/releases`

## Maps & Geolocation

**OpenStreetMap:**
- Tile rendering: `flutter_map` ^8.2.2, tile URL `https://tile.openstreetmap.org/{z}/{x}/{y}.png`
- Geocoding: Nominatim API `https://nominatim.openstreetmap.org/search`
- Used in: `lib/screens/myWallets/cesium_profile_screen.dart` for identity geolocation display
- No API key required

## Deep Links & NFC

**Deep Links:**
- Schemes: `g1://` and `june://` for payment URIs
- Package: `app_links` ^6.3.3
- Handler: `lib/providers/deep_link_provider.dart`
- URI parsing: `lib/services/qr_scanner_service.dart` (`QrScannerService`)

**NFC:**
- Package: `flutter_nfc_kit` ^3.5.2 + `ndef` ^0.3.1
- Services: `lib/services/nfc_service.dart` (scanning), `lib/services/nfc_hce_service.dart` (HCE emulation)
- Providers: `lib/providers/nfc_providers.dart`
- Protocol: NDEF tags carrying `june://` URIs; HCE emulation to present wallet address as NFC tag

**QR Code:**
- Scanning: `mobile_scanner` ^7.1.4 (live) + `barcode_scan2` ^4.7.2 (one-shot)
- Generation: `qr_flutter` ^4.1.0
- OCR (mnemonic scanning): `google_mlkit_text_recognition` ^0.15.1 via `lib/widgets/mnemonic_scanner.dart`

## Monetary License

**GitLab Raw Content:**
- Ğ1 monetary license fetched from: `https://git.duniter.org/documents/g1_monetary_license/-/raw/master/g1_monetary_license_{lang}.rst`
- Provider: `lib/providers/license_provider.dart`
- Falls back to English if locale-specific file unavailable

## CI/CD & Deployment

**Hosting:**
- Android: Google Play Store (package `fr.axiomteam.gecko`, track `internal`/`alpha`/`beta`/`production`)
- iOS: Apple App Store (bundle ID `fr.axiom-team.gecko`)
- Desktop/Sideloaded: GitLab Releases at `git.duniter.org/clients/gecko`

**CI Pipeline:**
- GitLab CI (`/.gitlab-ci.yml`) — primary pipeline with stages: `format`, `build`, `deploy`, `publish`, `release`, `ai-develop`, `ai-review`
- Docker images: `poka/gecko-ci-android:latest` (~5GB), `poka/gecko-ci-format:latest` (~300MB), `poka/gecko-ci-deploy:latest` (~400MB), `poka/gecko-ci-publish:latest` (~150MB)
- Codemagic (`/codemagic.yaml`) — Windows builds only (triggered via API from GitLab CI)

**Deployment Scripts:**
- Android: `scripts/deploy-android.sh` — fastlane to Google Play
- iOS: `scripts/deploy-ios.sh` — App Store Connect via fastlane
- macOS: `scripts/build-macos-dmg.sh`
- Linux: `scripts/build-docker-linux.sh`
- Release notes: `scripts/publish-forum.py` — posts to Duniter forum via Discourse API (pydiscourse client)

## Environment Configuration

**Required env vars (CI/deployment only):**
- `GOOGLE_PLAY_JSON_KEY_PATH` — Google Play service account JSON
- `ANDROID_PACKAGE_NAME` — `fr.axiomteam.gecko`
- `APP_STORE_CONNECT_API_KEY_PATH`, `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_API_ISSUER_ID` — App Store Connect
- `IOS_APP_IDENTIFIER` — `fr.axiom-team.gecko`
- `DUNITER_FORUM_API_KEY`, `DUNITER_FORUM_URL`, `DUNITER_FORUM_USERNAME` — forum posting
- `.env` file present; `.env.example` documents all required vars

**Secrets location:**
- CI secrets stored in GitLab CI/CD variables
- Local development: `.env` file (gitignored)
- No secrets embedded in app binary except Sentry DSN (not sensitive)

## Webhooks & Callbacks

**Incoming:**
- `g1://` and `june://` URI scheme deep links (handled by `lib/providers/deep_link_provider.dart`)
- Android: intent filter for URI schemes in `AndroidManifest.xml`
- iOS: URL scheme registration in `ios/Runner/Info.plist`

**Outgoing:**
- Duniter WebSocket subscriptions (balance, identity status, certifications) — push from blockchain node
- Squid GraphQL subscriptions — real-time indexer updates

---

*Integration audit: 2026-03-25*
