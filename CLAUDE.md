# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ğecko is a Flutter mobile wallet for the Duniter v2s blockchain (Ḡ1v2). It uses the `durt2` package to interact with Duniter nodes and provides wallet management, identity certification, and transaction capabilities.

## Build & Run Commands

```bash
# Run in debug mode (requires running emulator)
flutter run

# Build APK
./scripts/build-apk.sh

# Run unit tests
flutter test                                         # all unit tests
flutter test test/providers/                         # provider tests only

# Code generation (Hive adapters)
./scripts/build_runner.sh

# Lint
flutter analyze

# Format (uses page_width from analysis_options.yaml)
dart format .
```

## Architecture

### State Management: Riverpod + Legacy Provider

The app is migrating from `package:provider` to **Riverpod 3**. Both coexist:
- New code uses `flutter_riverpod` with `ConsumerWidget`/`ConsumerStatefulWidget`
- Legacy providers in `lib/providers_deprecated/` (being phased out)

**Riverpod conventions (from `.cursor/rules/migration_riverpod.mdc`):**
- **Never use codegen** (`@riverpod` syntax) - write providers manually
- Separate business logic into `lib/services/` (stateless), state management in `lib/providers/`
- Prefer `AsyncNotifier` for async state, `FutureProvider` for cached async data
- Document providers in English with `///`

### Core Provider Hierarchy

Root provider chain in `lib/providers/providers.dart`:
```
durtProvider (Durt.i singleton)
├── walletServiceProvider    → Wallet/Safe management
├── storageServiceProvider   → On-chain data cache & subscriptions
├── duniterServiceProvider   → Transaction building (pay, certify, etc.)
├── squidServiceProvider     → GraphQL indexer queries
├── cesiumPlusServiceProvider → Identity REST API
└── networkProvider          → Current network (gdev, gtest, g1)
```

### Key Directories

- `lib/providers/` - Riverpod providers (state management)
- `lib/services/` - Stateless business logic (mnemonic, wallet scan, PIN security)
- `lib/screens/` - UI screens (ConsumerStatefulWidget pattern)
- `lib/widgets/` - Reusable UI components
- `lib/models/` - Data models and widget keys
- `lib/providers_deprecated/` - Legacy ChangeNotifier providers (do not add new ones)

### Blockchain Integration (durt2)

The `durt2` package provides all Duniter blockchain interactions:
- Real-time subscriptions: `storageService.subscribeBalance(address)`, `subscribeIdtyStatus(address)`
- Connection streams: `durt.duniterConnectionStatusStream`, `squid.connectionStream`
- Transactions: Built via `duniterService.pay()`, `duniterService.certify()`, etc.

### Connection State Management

`lib/providers/connection_providers.dart` handles dual connectivity (Duniter node + Squid indexer):
- `storageStateProvider` tracks: `notInitialized`, `offlineMode`, `ready`
- Reconnection triggers provider invalidation for automatic data refresh

## Unit Tests

Unit tests use durt2's test mode to mock blockchain services without network connections.

### Running tests

```bash
flutter test                          # all tests
flutter test test/providers/          # provider tests only
```

### Test mode setup (durt2)

The `durt2` package provides `DurtTestMode` to mock `Durt.storage` and `Durt.wallets`:

```dart
import 'package:durt2/durt2.dart';

setUpAll(() async {
  await DurtTestMode.init();
});

tearDownAll(() {
  Durt.resetTestMode();
});
```

### Testing async providers (priming technique)

When testing providers that use `ref.watch()` on `AsyncNotifierProvider`, you must "prime" them first to avoid hanging on `AsyncLoading`:

```dart
final container = ProviderContainer(overrides: [...]);

// Prime async providers BEFORE reading the main provider
await container.read(certStateProvider(address).future);
await container.read(certificationQueueProvider(address).future);

// Now safe to read the provider that watches them
final state = await container.read(certButtonStateProvider(address).future);
```

### Test structure

- `test/providers/` - Riverpod provider unit tests
- Widget keys for test interactions: `lib/models/widgets_keys.dart`

## Localization

Uses `easy_localization` with translations in `assets/translations/`. Supported: en, fr, es, it.

## Platform Notes

- Android API 23+, iOS, macOS, Linux supported
- Portrait orientation only
- SSL self-signed certificates enabled for Android compatibility
- Local dev can override durt2 via `pubspec.yaml` dependency_overrides pointing to `../durt2`
