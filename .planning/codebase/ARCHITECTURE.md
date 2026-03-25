# Architecture

**Analysis Date:** 2026-03-25

## Pattern Overview

**Overall:** Reactive layered architecture — Riverpod providers bridge durt2 blockchain services to a Flutter UI layer. The app is NOT a traditional MVC/MVP but a reactive graph: providers subscribe to blockchain streams, derive computed state, and widgets rebuild automatically.

**Key Characteristics:**
- `durt2` package owns all blockchain I/O — app never calls substrate RPC directly
- Riverpod 3 providers are the single source of truth for all app state
- Dual connectivity model: Duniter node (WebSocket substrate) + Squid GraphQL indexer
- Hybrid offline/online support: app works with cached state when disconnected
- Desktop and mobile layouts share the same providers but use separate widget trees

## Layers

**Blockchain Services (durt2):**
- Purpose: All Duniter blockchain I/O, wallet crypto, on-chain subscriptions
- Location: External package `durt2` (dependency_overrides: `../durt2` in dev)
- Contains: `Durt.i` singleton, `WalletService`, `DuniterStorageService`, `DuniterService`, `SquidService`, `CesiumPlusService`
- Depends on: Nothing in `lib/`
- Used by: `lib/providers/providers.dart` root providers

**Provider Layer:**
- Purpose: State management, reactive transformation of blockchain data, business logic coordination
- Location: `lib/providers/`
- Contains: Riverpod `NotifierProvider`, `AsyncNotifierProvider`, `StreamProvider`, `FutureProvider`, `Provider`
- Depends on: durt2 services (via `lib/providers/providers.dart`), `lib/services/`
- Used by: `lib/screens/`, `lib/widgets/`

**Services Layer:**
- Purpose: Stateless business logic that doesn't own Riverpod state (pure functions + side effects)
- Location: `lib/services/`
- Contains: PIN security, wallet management, configuration, queue persistence, app initialization
- Depends on: durt2, Hive, external packages; never imports providers
- Used by: Providers, screens, widgets (via `ref.read(serviceProvider)`)

**Screen Layer:**
- Purpose: Full-page UI organized by feature domain
- Location: `lib/screens/`
- Contains: `ConsumerStatefulWidget` / `ConsumerWidget` classes, one screen per route
- Depends on: providers, widgets, models
- Used by: `lib/routes.dart` route table

**Widget Layer:**
- Purpose: Reusable UI components and domain-specific composite widgets
- Location: `lib/widgets/`
- Contains: Stateless and stateful widgets, feature widgets (certify, bottom_sheets, desktop modals)
- Depends on: providers, models
- Used by: screens, other widgets

**Model Layer:**
- Purpose: Data classes, display items, filter state, UI keys
- Location: `lib/models/`
- Contains: `TransactionDisplayItem`, `CertificationDisplayItem`, `WalletHeaderData` (Hive), filter enums, `widgets_keys.dart`, scale functions
- Depends on: durt2 types, Hive
- Used by: providers, screens, widgets

## Data Flow

**Balance display flow:**

1. `Durt.i.storage.subscribeBalance(address)` (durt2 WebSocket subscription)
2. → `smartBalanceStreamProvider(address)` selects `persistentBalanceStreamProvider` (owned wallet) or `balanceStreamProvider` (other)
3. → `BalanceStorageBuilder` / `Balance` widget rebuilds reactively
4. Block height also triggers re-fetch via `blockHeightProvider` to catch missed subscription events

**Transaction submission flow:**

1. User fills `paymentPopup` widget (`lib/widgets/payment_popup.dart`)
2. Widget reads `duniterServiceProvider` → calls `duniterService.pay()`
3. `TransactionInProgress` screen (`lib/screens/transaction_in_progress.dart`) shows status
4. On completion, `walletActionsProvider.notifier.invalidateProviders()` invalidates balance/history providers
5. History providers re-fetch from Squid via `SquidService.client.getAccountHistory()`

**Certification queue flow:**

1. User taps `AddToQueueButton` (`lib/widgets/certify/add_to_queue_button.dart`)
2. `certificationQueueProvider(issuerAddress)` notifier adds target to queue
3. `CertificationQueueService.saveQueue()` persists queue to Hive box `certification_queues`
4. `ReadyCertificationListener` (`lib/widgets/certify/ready_certification_listener.dart`) globally monitors queue readiness
5. When conditions met, `ExecuteQueuedButton` calls `duniterService.certify()` for each queued target

**Connection state flow:**

1. `durt2` emits `ConnectionStatus` on `duniterConnectionStatusStream` / `squidConnectionStatusStream`
2. `ConnectionStatusNotifier` (`lib/providers/connection_providers.dart`) merges both streams
3. `storageStateProvider` maps connection status to `StorageState` enum (`notInitialized` → `offlineMode` → `onlineMode`)
4. All stream providers guard on `storageState == StorageState.onlineMode` before subscribing
5. On reconnect, `connectionStatusProvider` invalidates balance, identity, and certification stream providers

**State Management:**

- Online/realtime: `StreamProvider.family` wrapping durt2 `subscribeBalance`, `subscribeToIdtyStatus`, etc.
- Cached/paginated: `BasePaginatedNotifier` subclasses with Squid GraphQL + riverpod_sqflite persistence
- Safe (wallet group) state: `WalletsListNotifier` → `SafeWalletGroup`, reacts to `defaultSafeBoxNumberProvider`
- Session-only: `Notifier<T>` for PIN state, drag-drop state, recent certifications map

## Key Abstractions

**`Durt.i` singleton:**
- Purpose: Single entry point to all durt2 services after `Durt().init(network, keyPairType)`
- Provider: `lib/providers/providers.dart` — `durtProvider` wraps `Durt.i`
- Pattern: All sub-services accessed via `durtProvider` → `walletServiceProvider`, `storageServiceProvider`, etc.

**`smartBalanceStreamProvider` / `smartIdtyStatusStreamProvider` / `smartCertificationStreamProvider`:**
- Purpose: Auto-select persistent vs. auto-dispose subscription based on wallet ownership
- Files: `lib/providers/stream_providers.dart`
- Pattern: `.family.autoDispose` delegates to persistent variant for owned wallets, auto-dispose for searched wallets

**`HybridIdtyStatusNotifier` / `HybridCertificationNotifier`:**
- Purpose: Combine durt2 WebSocket streams with Squid fallback to handle edge cases (identity not yet on-chain, missed WebSocket events)
- Files: `lib/providers/stream_providers.dart`
- Pattern: `AsyncNotifier.family` — starts with `getIdtyStatus`, then subscribes; uses `blockHeightProvider` for polling when identity is `IdtyStatus.none`

**`BasePaginatedNotifier<T>`:**
- Purpose: Generic pagination, caching, and Squid subscription for list data (history, certifications, network activity)
- File: `lib/providers/base_paginated_provider.dart`
- Pattern: Subclass overrides `fetchPage()`, `createSubscription()`, `persistKey`; base handles cursor, JSON persistence via riverpod_sqflite

**`StorageBuilder` / `BalanceStorageBuilder`:**
- Purpose: Guard widgets from rendering before durt2 storage is initialized; show shimmer placeholder
- File: `lib/widgets/commons/storage_builder.dart`
- Pattern: Catches `DuniterStorageService not initialized` error, watches `storageStateProvider`

**`SafeWalletGroup`:**
- Purpose: Groups `SafeEntity` with its `WalletEntity[]` list + `isCurrent` flag
- File: `lib/providers/wallets_provider.dart`
- Pattern: `safeWalletGroupsProvider` computes this from ObjectBox query, used by `WalletsHome` and `SwitchSafe` screens

## Entry Points

**Application bootstrap:**
- Location: `lib/main.dart`, `main()` function
- Triggers: Flutter framework launch
- Responsibilities: Platform detection, Hive init, durt2 init (`Durt().init()`), locale/timeago setup, SSL certificate config, Sentry wrapping, desktop window management, `runApp(EasyLocalization(child: Gecko()))`

**Root widget:**
- Location: `lib/main.dart`, `Gecko` class
- Responsibilities: `ProviderScope` root, global provider watchers (`squidEndpointChangeNotifierProvider`, `appLifecycleProvider`, `deepLinkProvider`), `MaterialApp` with `ResponsiveBreakpoints`, navigation observers, global overlays (`GlobalOfflineOverlay`, `ReadyCertificationListener`, `GlobalBottomAppBar`)

**Route table:**
- Location: `lib/routes.dart`, `AppRoutes.getRoutes()`
- Pattern: Named routes using `RouteNames` constants; `RouteArguments` subclasses for type-safe argument passing; `AppNavigator` static helpers for programmatic navigation

**Home screen:**
- Location: `lib/screens/home/home_screen.dart`
- Responsibilities: App initialization (`appInitProvider.notifier.initApp()`), routing between `WelcomeHomeWidget` (no safe) and `GeckoHomeWidget` (safe exists); splash screen coordination

## Error Handling

**Strategy:** Errors surface to UI via `AsyncValue.error` or are caught and reported to Sentry. Services log via the global `log` instance (`lib/globals.dart`).

**Patterns:**
- Provider build errors: `AsyncValue.error` state → widget shows error or fallback
- Blockchain transaction errors: `DuniterService` throws typed exceptions; screens catch and display via snackbar or dialog
- Stream subscription errors: Logged, controller receives `addError()`, auto-dispose cleans up
- `NotMemberException` / `CantBeCertException`: Defined in `lib/exceptions.dart`, thrown by certify flow
- Storage not ready: `StorageBuilder` widget catches `DuniterStorageService not initialized` and shows shimmer
- Network loss: `connectivity_plus` listener in `AppInitNotifier._setupConnectionHandling()` calls `durt.resetConnectionStatus()` to trigger provider cascade

## Cross-Cutting Concerns

**Logging:** Global `log` in `lib/globals.dart` using `logger` package with `MultiOutput` (console + `LogCollectionService`). Log levels: `log.d()`, `log.i()`, `log.w()`, `log.e()`.

**Validation:** `WalletManagementService.isWalletNameValid()` for wallet names; PIN validation in `PinSecurityService` (`lib/services/pin_security_service.dart`) with lockout logic.

**Authentication:** PIN code stored in memory via `PinCodeService.pinCode` static field (`lib/services/pin_cache_service.dart`). Biometric via `local_auth` in `lib/providers/biometric_provider.dart`. PIN security enforced by `PinSecurityService` (13-attempt max, exponential lockout).

**Localization:** `easy_localization` with JSON translation files in `assets/translations/`. Supported locales: en, fr, es, it, eo, de. Use `"key".tr()` throughout. Markdown text uses `TextMarkDown` widget (`lib/widgets/commons/text_markdown.dart`).

**Responsive layout:** `responsive_framework` with three breakpoints: MOBILE (0–450), TABLET (451–800), DESKTOP (801+). Desktop layout uses side panels (`lib/screens/home/desktop/`); mobile uses drawer + bottom navigation bar.

**Diagnostics:** `DiagnosticService` (`lib/services/diagnostic_service.dart`) attaches rich tags to every Sentry event (connection status, provider state, device info).

---

*Architecture analysis: 2026-03-25*
