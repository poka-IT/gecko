# Coding Conventions

**Analysis Date:** 2026-03-25

## Naming Patterns

**Files:**
- Screens: `snake_case.dart` (e.g., `home_screen.dart`, `transaction_in_progress.dart`)
- Providers: `snake_case_provider.dart` (e.g., `certification_queue_provider.dart`, `connection_providers.dart`)
- Widgets: `snake_case.dart`, grouped in subdirectories by feature (e.g., `widgets/certify/certify_button.dart`)
- Onboarding screens numbered: `lib/screens/onBoarding/10.dart` (exception: camelCase directory)
- Models: `snake_case.dart` (e.g., `migration_data.dart`, `widgets_keys.dart`)
- Services: `snake_case_service.dart` (e.g., `pin_security_service.dart`, `storage_init_service.dart`)
- One Riverpod provider file uses `.provider.dart` suffix: `g1v1_migration.provider.dart`

**Classes:**
- Widget classes: PascalCase matching file concept (e.g., `CertifyButton`, `HomeScreen`, `TransactionInProgressScreen`)
- Notifier classes: PascalCase with `Notifier` suffix (e.g., `HomeMessageNotifier`, `StorageStateNotifier`)
- State classes: PascalCase with `State` suffix (e.g., `WalletsListState`, `PinState`, `DragDropState`)
- Services: PascalCase with `Service` suffix (e.g., `PinSecurityService`, `CertificationQueueService`)
- Exceptions: PascalCase with `Exception` suffix (e.g., `NotMemberException`, `CantBeCertException`)

**Providers (variables):**
- All provider variables: `camelCase` with `Provider` suffix (e.g., `storageStateProvider`, `certButtonStateProvider`)
- Family providers follow same convention (e.g., `migrationDataProvider`, `certStateProvider`)

**Functions and methods:**
- `camelCase` throughout (e.g., `getShortPubkey`, `recordFailedAttempt`, `markCompleted`)
- Private methods: `_camelCase` prefix with underscore (e.g., `_subscribeToStreams`, `_getInitialState`)
- Boolean predicates: `is`/`has`/`should`/`can` prefix (e.g., `isLockedOut`, `shouldDeleteSafe`, `wasCertifiedRecently`)

**Variables:**
- Local variables: `camelCase`
- Private instance fields: `_camelCase`
- Constants: `camelCase` (not SCREAMING_CAPS), declared with `const` (e.g., `const keyInfoPopup = Key(...)`)
- Global `late` variables for Hive boxes: `camelCase` (e.g., `configBox`, `g1WalletsBox` in `lib/globals.dart`)

**Enums:**
- Type: PascalCase (e.g., `StorageState`, `RecentCertState`, `ConfirmationDialogType`)
- Values: `camelCase` (e.g., `StorageState.notInitialized`, `StorageState.onlineMode`)

## Code Style

**Formatting:**
- `dart format` using `page_width: 120` (configured in `analysis_options.yaml`)
- No enforced single-quote rule (default double quotes in practice)

**Linting:**
- `package:flutter_lints/flutter.yaml` (standard Flutter recommended rules)
- Config: `analysis_options.yaml`
- No custom rules added beyond the default set

**Line length:** 120 characters

## Riverpod Provider Patterns

**Do not use codegen.** Never use `@riverpod` syntax. Write providers manually.

**Provider types by use case:**

| Use Case | Provider Type |
|----------|---------------|
| Wrapping a service (sync) | `Provider<T>` |
| Async data (read-once, cached) | `FutureProvider<T>` |
| Mutable sync state | `NotifierProvider<Notifier<S>, S>` |
| Mutable async state | `AsyncNotifierProvider<AsyncNotifier<S>, S>` |
| Parameterized variants | `.family` suffix on any of the above |

**Notifier structure:**
```dart
/// Provides X for Y purpose.
class MyNotifier extends Notifier<MyState> {
  @override
  MyState build() {
    ref.onDispose(() => /* cleanup */);
    // Defer side-effects to avoid modifying providers during build:
    Future.microtask(() => _subscribeToStreams());
    return MyState.initial();
  }

  void doSomething() => state = /* new state */;
}

final myProvider = NotifierProvider<MyNotifier, MyState>(MyNotifier.new);
```

**AsyncNotifier structure:**
```dart
class CertStateNotifier extends AsyncNotifier<d.CertState?> {
  // Pass args via constructor for family notifiers
  @override
  Future<d.CertState?> build() async {
    // watch providers here
    return /* async result */;
  }
}

final certStateProvider = AsyncNotifierProvider.family<CertStateNotifier, d.CertState?, String>(
  CertStateNotifier.new,
);
```

**Provider documentation:** All providers must have a `///` doc comment in English describing what they provide and when they return null (if applicable). See `lib/providers/providers.dart` for reference style.

**Avoiding build-time state mutation:** Never modify provider state directly in `build()`. Use `Future.microtask(() => ...)` to defer stream subscriptions and initial side-effects. See `lib/providers/connection_providers.dart` lines 28-30.

**Immutable state with `copyWith`:** State classes use immutable fields and a `copyWith` method for updates. See `WalletsListState`, `PinState`, `DragDropState` in `lib/providers/wallets_provider.dart`.

**ref.watch vs ref.read:**
- `ref.watch` in `build()` for reactive dependencies
- `ref.read` in methods/callbacks (not in build)
- `ref.listen` for side-effects triggered by other providers

## Widget Patterns

**Three widget types in use:**
1. `ConsumerStatefulWidget` + `ConsumerState` — for widgets with local state AND Riverpod access (most screens and interactive widgets)
2. `ConsumerWidget` (with `build(context, ref)`) — for stateless widgets that only read providers
3. `StatelessWidget` — for pure UI widgets with no provider access

**Choosing the right type:**
- If widget has `setState`, `initState`, `dispose`, or `_isProcessing` guard: use `ConsumerStatefulWidget`
- If widget only reads providers in build: use `ConsumerWidget`
- If widget has no provider access at all: use `StatelessWidget`

**Widget key constants:** All testable widget keys are defined in `lib/models/widgets_keys.dart` as `const Key(...)` top-level constants. Use these for test interactions.

**Processing guards:** Interactive widgets that trigger async actions use a `_isProcessing` bool to prevent double-taps:
```dart
Future<void> _onTap(BuildContext context) async {
  if (_isProcessing) return;
  setState(() => _isProcessing = true);
  try {
    // ... async work ...
  } finally {
    if (mounted) setState(() => _isProcessing = false);
  }
}
```
See `lib/widgets/certify/certify_button.dart`.

**`mounted` guard usage:** Check `mounted` (or `context.mounted`) before any UI operation after an `await`. Use `if (!mounted) return;` only when it genuinely requires a live widget tree (navigation, dialogs). Do NOT use it to silence crashes — fix the root cause instead.

**Markdown text:** Never use plain `Text` for strings that may contain `**bold**` or `*italic*` markdown. Use `TextMarkDown` from `lib/widgets/commons/text_markdown.dart` instead.

**Confirmation dialogs:** Use `showConfirmationDialog` from `lib/widgets/commons/confirmation_dialog.dart`. It accepts a `ConfirmationDialogType` (info, warning, success, error, question) and renders message text as markdown.

## Import Organization

**Order:**
1. Dart SDK (`dart:async`, `dart:io`, etc.)
2. Flutter packages (`package:flutter/material.dart`)
3. External packages (`package:flutter_riverpod/...`, `package:durt2/...`, `package:easy_localization/...`)
4. Internal package imports (`package:gecko/...`)

**durt2 import convention:** Import as aliased `import 'package:durt2/durt2.dart' as d;` to avoid namespace collisions. Access types as `d.CertState`, `d.ConnectionStatus`, etc. Exception: when only a few specific types are needed, selective imports are used (`import 'package:durt2/durt2.dart' show IdtyStatus;`).

**Hide conflicts:** Use `hide Provider` when importing `durt2` in files that also use Riverpod's `Provider` type (e.g., `import 'package:durt2/durt2.dart' hide Provider;`).

## Error Handling

**Service errors:** Services return `null` on failure (rather than throwing), and callers guard with null checks. See `migrationDataProvider` in `lib/providers/identity_providers.dart` where `catch (e) { return null; }` is the pattern for expected network failures.

**Business logic exceptions:** Typed custom exceptions for domain-level failures, defined in `lib/exceptions.dart`:
- `NotMemberException` — identity not a member
- `CantBeCertException` — target cannot be certified

**UI error display:** Errors are surfaced via `showConfirmationDialog(..., type: ConfirmationDialogType.error, message: e.toString())`. Known exceptions (`NotMemberException`, `CantBeCertException`) are filtered before logging.

**Logging framework:** `Logger` from `package:logger`, global instance `log` in `lib/globals.dart`. Multi-output: console + `LogCollectionService` for Sentry.
- `log.d(...)` — debug
- `log.i(...)` — info (e.g., successful state changes)
- `log.w(...)` — warning (e.g., expected edge cases)
- `log.e(...)` — error (unexpected failures only)

**Never log known exceptions:** Filter typed exceptions before calling `log.e`:
```dart
if (e is! NotMemberException && e is! CantBeCertException) log.e(e);
```

## Comments

**Provider documentation:** Triple-slash `///` doc comments on every provider variable. Written in English. Describes purpose + null behavior if async. See `lib/providers/providers.dart` for full reference.

**Method documentation:** `///` on public methods of services and notifiers. Inline comments for non-obvious logic.

**Test comments:** Test files start with a multi-line `///` block describing what the test file covers. Groups use sectioned headers (`// ===`).

**French vs English:** Provider docs and code comments are in English. UI strings use `easy_localization` translation keys. Inline comments in provider/service code may be French (especially older code).

## Localization

All UI text uses `easy_localization` translation keys. Access via `.tr()` extension:
```dart
'certify'.tr()
'networkConnectionError'.tr()
'connected'.tr(args: [networkName])
```

Translation files live in `assets/translations/`. Never hardcode user-visible strings.

## Extensions

Project-wide extensions are in `lib/extensions.dart`:
- `BlockTimestampParsing on String` — blockchain timestamp parsing
- `IterableExtension<T> on Iterable<T>` — `firstWhereOrNull`
- `ExtendedBuildContext on BuildContext` — `textTheme`, `colorScheme`, `isDarkTheme`, `geckoColors`

Use `context.geckoColors` for semantic color tokens (danger, warning, success) instead of hardcoded colors.

---

*Convention analysis: 2026-03-25*
