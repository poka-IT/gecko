# Technology Stack

**Analysis Date:** 2026-03-25

## Languages

**Primary:**
- Dart 3.8.1+ — all application code (`lib/`, `test/`, `integration_test/`)

**Secondary:**
- Python — CI/CD scripts (`scripts/publish-forum.py`, `scripts/round_macos_icons.py`, `scripts/update_pubsec_yaml_versions.py`)
- Shell (bash/zsh) — build and deploy scripts (`scripts/build-apk.sh`, `scripts/deploy-android.sh`, etc.)
- PowerShell — Windows CI build (`codemagic.yaml` Windows workflow)

## Runtime

**Environment:**
- Flutter stable channel (required by CI: `codemagic.yaml` specifies `flutter: stable`)
- Dart SDK ^3.8.1 (declared in `pubspec.yaml`)

**Package Manager:**
- pub (Dart/Flutter package manager)
- Lockfile: `pubspec.lock` (present)

## Frameworks

**Core:**
- Flutter (Material Design) — cross-platform UI framework; `uses-material-design: true` in `pubspec.yaml`
- `flutter_riverpod` ^3.2.1 — primary state management (active migration from `package:provider`)
- `provider` ^6.1.5+1 — legacy state management in `lib/providers_deprecated/` (being phased out)

**UI:**
- `responsive_framework` ^1.5.1 — breakpoints: MOBILE (0-450), TABLET (451-800), DESKTOP (801+); configured in `lib/main.dart`
- `easy_localization` ^3.0.8 — i18n; translations in `assets/translations/` (en, fr, es, it, eo, de)
- `flutter_markdown` ^0.7.7+1 — markdown rendering; used via `lib/widgets/commons/text_markdown.dart`

**Testing:**
- `flutter_test` (SDK) — widget and unit test framework
- `integration_test` (SDK) — integration test framework

**Build/Dev:**
- `build_runner` ^2.11.1 — code generation (Hive adapters via `.g.dart` files)
- `flutter_lints` ^6.0.0 — lint rules via `analysis_options.yaml`
- `sentry_dart_plugin` ^2.0.0 — uploads debug symbols to Sentry during release builds
- `flutter_launcher_icons` ^0.14.4 — generates platform app icons from `assets/icon/gecko_flat_background.png`
- `flutter_native_splash` ^2.4.7 — generates native splash screens (color `#FFD68E`)

## Key Dependencies

**Critical:**
- `durt2` ^1.1.1 (local override: `../durt2`) — Duniter v2s blockchain SDK; provides all chain interactions (wallets, transactions, GraphQL, WebSocket). Root of the entire provider hierarchy via `Durt.i` singleton accessed in `lib/providers/providers.dart`
- `hive_flutter` ^1.1.0 — local key-value storage for app config, wallet metadata, contacts; initialized in `lib/services/storage_init_service.dart`; stores data at `~/.gecko/db/` (desktop) or `getApplicationDocumentsDirectory()` (mobile)
- `sqflite` ^2.4.1 — SQLite storage for Riverpod persist cache (`lib/providers/persist_storage_provider.dart` opens `gecko_riverpod_cache.db`)
- `riverpod_sqflite` ^0.4.2 — Riverpod persistence adapter over SQLite; used in `lib/providers/persist_storage_provider.dart`

**Blockchain/Crypto:**
- `pinenacl` ^0.6.0 — NaCl cryptography (Ed25519 key operations)
- `pointycastle` ^4.0.0 — additional crypto primitives; used in `lib/screens/myWallets/migrate_identity.dart`
- `crypto` ^3.0.7 — hash functions; used in `lib/providers/avatar_providers.dart`

**UI Components:**
- `graphql_flutter` ^5.2.1 — GraphQL client (used for Squid indexer queries via durt2)
- `flutter_map` ^8.2.2 + `latlong2` ^0.9.1 — OpenStreetMap rendering in Cesium profile screen
- `mobile_scanner` ^7.1.4 — QR code scanning (live camera feed)
- `barcode_scan2` ^4.7.2 — alternative barcode scanning
- `qr_flutter` ^4.1.0 — QR code generation
- `flutter_nfc_kit` ^3.5.2 + `ndef` ^0.3.1 — NFC read/write for wallet payments
- `local_auth` ^3.0.0 + `local_auth_android` ^2.0.4 + `local_auth_ios` ^1.1.7 — biometric authentication (fingerprint/Face ID); used in `lib/providers/biometric_provider.dart`
- `google_mlkit_text_recognition` ^0.15.1 — OCR for scanning seed phrases from photos; used in `lib/widgets/mnemonic_scanner.dart`
- `camera` ^0.12.0 — camera access for mnemonic scanning
- `image_picker` ^1.2.1 + `image_cropper` ^11.0.0 — avatar image selection
- `pdf` ^3.11.3 + `printing` ^5.14.2 — PDF export (paper wallet generation)
- `sentry_flutter` ^9.13.0 — error monitoring; configured in `lib/services/sentry_service.dart`

**Infrastructure:**
- `http` ^1.6.0 — HTTP requests for update checks (iTunes lookup, GitLab releases API); used in `lib/services/app_update_service.dart`
- `dio` ^5.9.1 — advanced HTTP client (used by durt2 and avatar fetching)
- `connectivity_plus` ^6.1.5 — network connectivity detection
- `in_app_update` ^4.2.5 — Android Play Store in-app update API
- `app_links` ^6.3.3 — deep link handling for `g1://` and `june://` URI schemes; used in `lib/providers/deep_link_provider.dart`
- `window_manager` ^0.5.1 — desktop window size/title management; configured in `lib/main.dart`
- `path_provider` ^2.1.5 — platform-specific directory resolution
- `package_info_plus` ^9.0.0 — app version/build number at runtime
- `device_info_plus` ^12.3.0 — device model/ABI detection for update downloads
- `get_it` ^9.2.0 — service locator (used alongside Riverpod for non-widget services)
- `logger` ^2.6.2 — structured logging; global `log` instance in `lib/globals.dart` with `LogCollectionOutput` for in-app log capture
- `uuid` ^4.5.2 — UUID generation for report IDs
- `intl` ^0.19.0 (override: ^0.20.0) — date/number formatting
- `timeago` ^3.7.1 — relative time strings (fr, es, it, de, eo supported)
- `jdenticon_dart` ^2.0.0 — identicon generation for wallet avatars
- `audioplayers` ^6.5.1 — sound effects for UI interactions
- `confetti` ^0.8.0 — confetti animation on successful operations
- `tutorial_coach_mark` ^1.3.3 — in-app onboarding coach marks
- `clipboard_watcher` ^0.3.0 — desktop clipboard monitoring

## Configuration

**Environment:**
- `.env` file present for local development; `.env.example` documents required vars
- Key CI vars: `GOOGLE_PLAY_JSON_KEY_PATH`, `ANDROID_PACKAGE_NAME`, `APP_STORE_CONNECT_API_KEY_PATH`, `DUNITER_FORUM_API_KEY`
- No runtime env vars injected into app — all configuration via Hive (`configBox`) at runtime

**App Configuration (Hive-based):**
- All user preferences in `configBox` (Hive box) — network selection, window size, PIN settings, currency display, locale override
- Managed through `lib/services/config_service.dart` with typed accessors
- Data schema versioned: `dataVersion = 13`, `walletHeaderDataVersion = 2` in `lib/globals.dart`

**Build:**
- `analysis_options.yaml` — lint rules (extends `flutter_lints/flutter.yaml`), formatter line width: 120
- `codemagic.yaml` — Windows CI build pipeline (triggered via API from GitLab CI)
- `.gitlab-ci.yml` — primary CI/CD pipeline (format, build, deploy, publish, release, ai-develop, ai-review stages)
- `graphql.config.yaml` — GraphQL schema path for IDE language service (points to `../durt2` schema)

## Platform Requirements

**Development:**
- Flutter stable channel
- Dart SDK ^3.8.1
- Local `durt2` package at `../durt2` (via `dependency_overrides` in `pubspec.yaml`)
- Android: API 23+ (`flutter_launcher_icons.min_sdk_android: 23`)
- iOS/macOS: Xcode required
- Linux/Windows: standard Flutter desktop toolchain

**Production Targets:**
- Android (fr.axiomteam.gecko) — Google Play Store + sideloaded APK
- iOS (fr.axiom-team.gecko) — Apple App Store
- macOS — DMG distribution
- Linux — binary distribution
- Windows — Inno Setup installer (`.exe`) + portable ZIP

**Package IDs:**
- Android: `fr.axiomteam.gecko`
- iOS/macOS: `fr.axiom-team.gecko`

---

*Stack analysis: 2026-03-25*
