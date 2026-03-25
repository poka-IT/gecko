# Codebase Structure

**Analysis Date:** 2026-03-25

## Directory Layout

```
gecko/
├── lib/                        # Application source code
│   ├── main.dart               # App entry point, bootstrap, Gecko root widget
│   ├── routes.dart             # Route table, RouteNames, RouteArguments, AppNavigator
│   ├── globals.dart            # Global singletons (log, Hive boxes, app constants)
│   ├── exceptions.dart         # App-level exception types
│   ├── extensions.dart         # Dart/Flutter extension methods
│   ├── utils.dart              # Standalone utility functions
│   ├── providers/              # Riverpod providers (all state management)
│   ├── services/               # Stateless business logic and infrastructure services
│   ├── screens/                # Full-page UI screens, organized by feature
│   ├── widgets/                # Reusable UI components and composite widgets
│   └── models/                 # Data classes, display items, UI constants
├── test/
│   ├── providers/              # Riverpod provider unit tests
│   ├── services/               # Service unit tests
│   ├── widgets/                # Widget tests
│   └── cert_button_state_test.dart
├── integration_test/           # Integration tests with duniter-mocks
│   ├── duniter/                # Duniter node mock data
│   ├── squid/                  # Squid indexer mock data
│   ├── scenarios/              # Test scenarios
│   └── utility/                # Test helpers
├── assets/
│   ├── translations/           # Localization JSON files (en, fr, es, it, eo, de)
│   ├── avatars/                # Default avatar images (0.png, 1.png, 2.png, 3.png)
│   ├── icon/                   # App icons
│   ├── onBoarding/             # Onboarding step images
│   └── sounds/                 # Audio assets
├── android/                    # Android platform config
├── ios/                        # iOS platform config
├── linux/                      # Linux platform config
├── macos/                      # macOS platform config
├── windows/                    # Windows platform config
├── .planning/codebase/         # GSD codebase analysis documents
└── pubspec.yaml                # Flutter/Dart dependencies
```

## Directory Purposes

**`lib/providers/`:**
- Purpose: All Riverpod state management — the reactive core of the app
- Contains: `NotifierProvider`, `AsyncNotifierProvider`, `StreamProvider`, `FutureProvider`, `Provider` declarations
- Key files:
  - `lib/providers/providers.dart` — root provider chain wrapping durt2 services
  - `lib/providers/connection_providers.dart` — connection status, StorageState, squid endpoint
  - `lib/providers/stream_providers.dart` — real-time balance/identity/certification stream providers
  - `lib/providers/wallets_provider.dart` — WalletsListState, PinState, DragDropState, SafeWalletGroup
  - `lib/providers/identity_providers.dart` — HybridIdentityNameNotifier, migration providers
  - `lib/providers/certification_queue_provider.dart` — CertificationQueueState, cert button state machine
  - `lib/providers/home_providers.dart` — AppInitNotifier, HomeMessageNotifier, NetworkTotals
  - `lib/providers/block_height_provider.dart` — BlockHeightNotifier (ticks on each new block)
  - `lib/providers/base_paginated_provider.dart` — generic pagination base for Squid list data
  - `lib/providers/transaction_history_providers.dart` — paginated transaction history
  - `lib/providers/certification_list_providers.dart` — paginated certification history

**`lib/services/`:**
- Purpose: Stateless business logic with no Riverpod state ownership
- Contains: Services instantiated by providers via `Provider<Service>((ref) => Service())`
- Key files:
  - `lib/services/storage_init_service.dart` — Hive initialization, box setup, adapter registration
  - `lib/services/config_service.dart` — typed Hive `configBox` wrapper (settings, window size, network)
  - `lib/services/pin_security_service.dart` — PIN lockout logic (13-attempt max, exponential backoff)
  - `lib/services/pin_cache_service.dart` — in-memory PIN holder (`PinCodeService.pinCode`)
  - `lib/services/certification_queue_service.dart` — Hive persistence for `certification_queues` box
  - `lib/services/wallet_management_service.dart` — avatar picker/crop, wallet rename, Cesium+ upload
  - `lib/services/mnemonic_service.dart` — BIP39 mnemonic generation and validation
  - `lib/services/wallet_scan_service.dart` — HD wallet derivation scanning
  - `lib/services/sentry_service.dart` — Sentry initialization and crash reporting config
  - `lib/services/diagnostic_service.dart` — Sentry diagnostic tags (connection state, device info)
  - `lib/services/snackbar_service.dart` — centralized snackbar display helper

**`lib/screens/`:**
- Purpose: Full-page screens; each file = one route entry in `AppRoutes.getRoutes()`
- Contains: `ConsumerStatefulWidget` (most screens) or `ConsumerWidget`
- Subdirectories:
  - `lib/screens/home/` — `HomeScreen`, `GeckoHomeWidget`, `WelcomeHomeWidget`; `desktop/` sub-layout
  - `lib/screens/home/desktop/` — Desktop-specific panels: `DesktopWalletOverview`, `DesktopSearchSection`, `DesktopActivityPanel`
  - `lib/screens/myWallets/` — wallet management: `WalletsHome`, `WalletOptions`, `UnlockingWallet`, `CesiumProfileScreen`, `RestoreSafe`, `ShowSeed`, `MigrateIdentity`, `MigrateSafe`, `SafeOptions`, `SwitchSafe`
  - `lib/screens/myWallets/g1v1_migration/` — 4-step G1v1 → G1v2 migration wizard screens
  - `lib/screens/onBoarding/` — 11-step wallet creation onboarding (numbered `1.dart`–`11_congratulations.dart`) + `ImportChoiceScreen`, `LegacyLoginScreen`, `WalletSelectionScreen`, `SafeSelectionScreen`
  - `lib/screens/identity/` — `ConfirmIdentity` (identity username submission)
  - `lib/screens/settings/` — `SettingsScreen`; `widgets/` sub-folder for `NetworkSection`
  - `lib/screens/certification_queue_screen.dart` — certification queue management
  - `lib/screens/search.dart`, `lib/screens/search_result.dart` — identity search
  - `lib/screens/transaction_in_progress.dart` — real-time transaction status display
  - `lib/screens/activity.dart` — transaction history view
  - `lib/screens/certifications.dart` — certification history view
  - `lib/screens/currency_page.dart` — G1 currency info page
  - `lib/screens/profile_view.dart` — public identity profile view

**`lib/widgets/`:**
- Purpose: Reusable UI components shared across screens
- Key files:
  - `lib/widgets/commons/storage_builder.dart` — guards widgets until durt2 storage is ready
  - `lib/widgets/commons/text_markdown.dart` — renders translated strings with Markdown formatting
  - `lib/widgets/commons/confirmation_dialog.dart` — standard confirmation dialog
  - `lib/widgets/payment_popup.dart` — bottom-sheet payment form
  - `lib/widgets/balance.dart` / `lib/widgets/balance_display.dart` — balance rendering
  - `lib/widgets/wallet_header.dart` — wallet identity/avatar header widget
  - `lib/widgets/global_offline_overlay.dart` — full-screen offline banner
  - `lib/widgets/global_search_overlay.dart` — Cmd+K / Ctrl+K search palette
  - `lib/widgets/bottom_app_bar.dart` — global bottom navigation bar
  - `lib/widgets/sentry_context_provider.dart` — attaches Sentry breadcrumbs/context
  - `lib/widgets/certify/` — `CertifyButton`, `AddToQueueButton`, `InQueueButton`, `ExecuteQueuedButton`, `ReadyCertificationListener`
  - `lib/widgets/desktop/` — desktop-only modal wrappers and drag info bars
  - `lib/widgets/desktop/modals/` — desktop modals for each major action (payment, certification, onboarding, wallet options, etc.)
  - `lib/widgets/desktop/panels/` — `ContactsPanel`
  - `lib/widgets/bottom_sheets/` — mobile bottom sheet widgets

**`lib/models/`:**
- Purpose: Data transfer objects, display items, UI constants
- Key files:
  - `lib/models/widgets_keys.dart` — all `Key` constants for widget testing
  - `lib/models/transaction_display_item.dart` — display model for transaction history
  - `lib/models/certification_display_item.dart` — display model for certifications
  - `lib/models/identity_display_item.dart` — display model for identity search results
  - `lib/models/wallet_header_data.dart` (+ `.g.dart`) — Hive-persisted header cache
  - `lib/models/g1_wallets_list.dart` (+ `.g.dart`) — Hive-persisted G1v1 wallet list
  - `lib/models/migration_data.dart` — migration data parsed from Squid
  - `lib/models/transaction_filters.dart` — filter state for transaction list
  - `lib/models/certification_filters.dart` — filter state for certification list
  - `lib/models/scale_functions.dart` — `scaleSize()` / `scaleFontSize()` helpers
  - `lib/models/responsive_breakpoints.dart` — `isDesktopLayout(context)` helper

## Key File Locations

**Entry Points:**
- `lib/main.dart`: Bootstrap, `Durt().init()`, `runApp()`
- `lib/routes.dart`: `AppRoutes.getRoutes()` — full route map
- `lib/globals.dart`: Global `log`, Hive box references, app constants

**Configuration:**
- `pubspec.yaml`: All dependencies; `version:` field = current app version
- `analysis_options.yaml`: Dart analysis rules, page width for formatter
- `assets/translations/*.json`: Localization strings per language

**Core Business Logic:**
- `lib/providers/providers.dart`: Root durt2 service providers
- `lib/providers/wallets_provider.dart`: Safe/wallet state management
- `lib/providers/connection_providers.dart`: Network state machine
- `lib/providers/stream_providers.dart`: All real-time blockchain subscriptions
- `lib/services/storage_init_service.dart`: Hive box setup

**Testing:**
- `test/providers/cert_button_state_test.dart`: Certification button state machine tests
- `test/services/pin_security_service_test.dart`: PIN lockout logic tests
- `integration_test/`: End-to-end tests using duniter-mocks

## Naming Conventions

**Files:**
- Screens: `snake_case.dart`, feature-descriptive (e.g., `wallet_options.dart`, `certification_queue_screen.dart`)
- Onboarding steps: numeric (`1.dart`, `10.dart`) + descriptive for named steps (`import_choice_screen.dart`)
- Providers: `snake_case_provider.dart` suffix (e.g., `connection_providers.dart`)
- Services: `snake_case_service.dart` suffix (e.g., `pin_security_service.dart`)
- Hive generated: `.g.dart` suffix (e.g., `wallet_header_data.g.dart`)

**Directories:**
- All lowercase `snake_case`
- Feature-grouped: `home/`, `myWallets/`, `onBoarding/`, `certify/`, `desktop/`

**Dart identifiers:**
- Providers: `lowerCamelCase` with `Provider` suffix (e.g., `walletsListProvider`, `storageStateProvider`)
- Notifiers: `PascalCase` with `Notifier` suffix (e.g., `WalletsListNotifier`)
- State classes: `PascalCase` with `State` suffix (e.g., `WalletsListState`, `PinState`)
- Services: `PascalCase` with `Service` suffix (e.g., `PinSecurityService`)
- Widget keys: `lowerCamelCase` with `key` prefix (e.g., `keyListWallets`, `keyCertify`)

## Where to Add New Code

**New screen / route:**
- Screen file: `lib/screens/<feature>/<screen_name>.dart`
- Register route: add to `RouteNames` constants, `AppRoutes.getRoutes()` map, and optionally `AppNavigator` static method in `lib/routes.dart`
- Add `RouteArguments` subclass in `lib/routes.dart` if parameters needed

**New Riverpod provider:**
- Simple derived state: add to nearest domain file in `lib/providers/` (e.g., identity-related → `identity_providers.dart`)
- New domain: create `lib/providers/<domain>_provider.dart`
- Never use `@riverpod` codegen — write providers manually
- Document with `///` in English

**New service:**
- Create `lib/services/<name>_service.dart`
- Pattern: static methods (no state) OR singleton with `factory` constructor
- Expose via Riverpod: add `final <name>ServiceProvider = Provider<Service>((ref) => Service())` at bottom of file or in domain providers file

**New widget (reusable):**
- Generic/common: `lib/widgets/commons/<widget_name>.dart`
- Feature-specific: `lib/widgets/<feature>/<widget_name>.dart`
- Desktop-only: `lib/widgets/desktop/modals/` (modals) or `lib/widgets/desktop/panels/`

**New model / data class:**
- `lib/models/<domain>_display_item.dart` for display-layer DTOs
- `lib/models/<domain>_filters.dart` for filter state
- Run `./scripts/build_runner.sh` after adding Hive `@HiveType` annotations

**New test:**
- Provider unit test: `test/providers/<name>_test.dart`
- Service unit test: `test/services/<name>_test.dart`
- Use `DurtTestMode.init()` / `Durt.resetTestMode()` in `setUpAll`/`tearDownAll`

**Translations:**
- Add key to `assets/translations/en.json` (English = canonical)
- Mirror to `fr.json`, `es.json`, `it.json`, `eo.json`, `de.json`
- Use `TextMarkDown` widget (not plain `Text`) for strings containing markdown bold/italic

## Special Directories

**`.planning/codebase/`:**
- Purpose: GSD codebase analysis documents for AI-assisted development
- Generated: By `/gsd:map-codebase` command
- Committed: Yes

**`lib/screens/home/desktop/`:**
- Purpose: Desktop-only home layout with multi-panel design (wallet overview, search, activity)
- Generated: No
- Committed: Yes

**`integration_test/`:**
- Purpose: End-to-end tests requiring duniter-mocks server (`../duniter-mocks`)
- Run via: `test/integration/run.sh`
- Committed: Yes

**`assets/avatars/`:**
- Purpose: Default wallet avatar images (4 variants: `0.png`–`3.png`), assigned by `walletNumber % 4`
- Generated: No
- Committed: Yes

**`build/`:**
- Purpose: Flutter build output
- Generated: Yes
- Committed: No (`.gitignore`)

**`.dart_tool/`:**
- Purpose: Dart tooling cache (pub, build_runner)
- Generated: Yes
- Committed: No

---

*Structure analysis: 2026-03-25*
