# Testing Patterns

**Analysis Date:** 2026-03-25

## Test Framework

**Runner:**
- `flutter_test` (Flutter's built-in test runner, wraps `package:test`)
- No dedicated `jest.config` or `vitest.config` — Flutter test runner is the standard

**Assertion Library:**
- `flutter_test` matchers (`expect`, `isTrue`, `isFalse`, `isNotNull`, `isNull`, `greaterThan`, `lessThanOrEqualTo`, `contains`, `anyOf`, `equals`)

**Run Commands:**
```bash
flutter test                           # Run all unit tests
flutter test test/providers/           # Provider tests only
flutter test test/services/            # Service tests only
flutter test test/widgets/             # Widget tests only
# Integration tests (require duniter-mocks running):
flutter test test/integration/migrate_identity_test.dart
```

**CRITICAL:** Never run `flutter test` on the full project without justification — it compiles and can crash the machine. Run targeted test paths instead.

## Test File Organization

**Location:** Tests are in `test/` (separate from `lib/`), mirroring the source structure:
```
test/
├── providers/
│   └── cert_button_state_test.dart      # Provider logic tests (Riverpod)
├── services/
│   └── pin_security_service_test.dart   # Stateless service tests (Hive)
├── widgets/
│   └── transaction_in_progress_test.dart  # Widget logic tests (minimal widget)
└── integration/
    ├── migrate_identity_test.dart         # Blockchain integration tests
    └── debug_owner_key_used.dart          # Debug/diagnostic scripts
```

**Naming:** `{feature}_test.dart` for all test files.

## Test Structure

**File-level library declaration:** Every test file opens with a `library;` statement (bare declaration, no name) to enable per-file `// ignore:` directives.

**File-level doc comment:** Every test file starts with a `///` block describing what the file covers and the key behaviors tested.

**Suite organization:**
```dart
/// Tests for XProvider
///
/// This provider does X based on Y and Z.
/// Actions: a, b, c
library;

import '...';

void main() {
  const someAddress = '5GrwvaEF5z...';

  late MockService mockService;

  setUpAll(() async {
    // One-time setup: init test mode, temp dirs
    mockService = MockService();
    await DurtTestMode.init(config: DurtTestConfig(mockStorage: mockService));
  });

  tearDownAll(() => DurtTestMode.reset());

  setUp(() async { /* per-test setup */ });
  tearDown(() async { /* per-test cleanup */ });

  group('Feature Area', () {
    test('condition → expected result', () async {
      // ...
    });
  });
}
```

**Group naming:** Descriptive, matches the feature or state being tested (e.g., `'CertStatus.canCert'`, `'recordFailedAttempt'`, `'Full brute-force scenario'`).

**Test naming:** `'condition → expected result'` pattern (e.g., `'storageState.notInitialized → none'`, `'returns 30s for 3rd failed attempt (first lockout)'`).

**Section dividers:** Long test files use prominent comment dividers:
```dart
// ==========================================================================
// 1. Section Name
// ==========================================================================
```

## durt2 Test Mode Setup

All provider and widget tests that touch blockchain services require `durt2`'s mock mode:

```dart
import 'package:durt2/durt2.dart' as d;

setUpAll(() async {
  final mockStorage = d.MockDuniterStorageService();
  final mockWallets = d.MockWalletService();
  await d.DurtTestMode.init(
    config: d.DurtTestConfig(mockStorage: mockStorage, mockWallets: mockWallets),
  );
});

tearDownAll(() => d.DurtTestMode.reset());
```

Widget tests additionally call `WidgetsFlutterBinding.ensureInitialized()` in `setUpAll`.

## Mocking Riverpod Providers

**Pattern:** Extend the real Notifier class, override `build()` to return a fixed value. Do NOT use external mock libraries.

```dart
// Mock a sync NotifierProvider
class _MockStorageStateNotifier extends StorageStateNotifier {
  final StorageState _state;
  _MockStorageStateNotifier(this._state);

  @override
  StorageState build() => _state;
}

// Mock an AsyncNotifierProvider
class _MockCertStateNotifier extends CertStateNotifier {
  final d.CertState? _value;
  _MockCertStateNotifier(this._value) : super('mock');

  @override
  Future<d.CertState?> build() async => _value;
}

// Mock a family AsyncNotifierProvider (pass required args via constructor)
class _MockCertificationQueueNotifier extends CertificationQueueNotifier {
  final d.CertificationQueueState _value;
  _MockCertificationQueueNotifier(this._value) : super('mock');

  @override
  Future<d.CertificationQueueState?> build() async => _value;
}
```

**FutureProvider override (lambda form):**
```dart
certificationExistsProvider(targetAddress).overrideWith((ref) async => false)
smartIdtyStatusStreamProvider(targetAddress).overrideWith((ref) => AsyncValue.data(d.IdtyStatus.validated))
```

**ProviderContainer with overrides:**
```dart
final container = ProviderContainer(
  overrides: [
    storageStateProvider.overrideWith(() => _MockStorageStateNotifier(StorageState.onlineMode)),
    certStateProvider(targetAddress).overrideWith(() => _MockCertStateNotifier(certState)),
    certificationQueueProvider(issuerAddress).overrideWith(() => _MockCertificationQueueNotifier(queue)),
  ],
);
// Always dispose after test:
container.dispose();
```

## Async Provider Priming (Critical Pattern)

When testing providers that `ref.watch()` other `AsyncNotifierProvider`s, you must "prime" the watched providers first. Without priming, reading the outer provider hangs on `AsyncLoading`.

```dart
// REQUIRED: prime async providers before reading the target provider
await container.read(certStateProvider(address).future);
await container.read(certificationQueueProvider(issuerAddress).future);

// NOW safe to read the provider that watches them
final result = await container.read(certButtonStateProvider(params).future);
```

See `lib/CLAUDE.md` and `test/providers/cert_button_state_test.dart` lines 82-88 for reference.

## Widget Testing

**Minimal test widget pattern:** When testing widget logic that has complex real dependencies (avatars, translations, Hive), create a minimal test widget that replicates only the logic under test:

```dart
class _MinimalTestWidget extends ConsumerStatefulWidget {
  final Stream<d.TransactionStatus> transactionStatus;
  // ... required params

  const _MinimalTestWidget({required this.transactionStatus, ...});

  @override
  ConsumerState<_MinimalTestWidget> createState() => _MinimalTestWidgetState();
}
```

**Wrapping with ProviderScope:**
```dart
Widget createTestWidget({required Stream stream, required ProviderContainer container}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: _MinimalTestWidget(transactionStatus: stream),
    ),
  );
}
```

**Pump pattern for async widget tests:**
```dart
final streamController = StreamController<d.TransactionStatus>();

await tester.pumpWidget(createTestWidget(...));
await tester.pump(const Duration(milliseconds: 50));

streamController.add(d.TransactionStatus(state: d.TransactionState.inBlock));
await tester.pump(const Duration(milliseconds: 50));
await tester.pump(); // Execute addPostFrameCallback / Future.microtask

// Now assert provider state
expect(container.read(recentCertificationsProvider.notifier).isInProgress(...), isFalse);

await streamController.close();
container.dispose();
```

## Service Testing (Hive-backed)

For services that use Hive boxes, create a temp directory and initialize Hive:

```dart
late Directory tempDir;

setUpAll(() async {
  tempDir = await Directory.systemTemp.createTemp('my_test_');
  Hive.init(tempDir.path);
});

tearDownAll(() async {
  await Hive.close();
  if (await tempDir.exists()) {
    await tempDir.delete(recursive: true);
  }
});

setUp(() async {
  if (Hive.isBoxOpen('configBox')) {
    await Hive.box('configBox').clear();
  } else {
    configBox = await Hive.openBox('configBox');
  }
});

tearDown(() async {
  await configBox.clear();
});
```

See `test/services/pin_security_service_test.dart` for full reference.

## Integration Tests

**Requirements:** Integration tests require `duniter-mocks` running in sealing mode:
```bash
cd ../duniter-mocks && ./run.sh restart --sealing && ./run.sh wait-ready
flutter test test/integration/migrate_identity_test.dart
```

**Setup:** Integration tests initialize real `Durt` (not test mode), mock `path_provider` via `MethodChannel`, and connect to `ws://localhost:9944`:
```dart
TestWidgetsFlutterBinding.ensureInitialized();

setUpAll(() async {
  // Mock path_provider for ObjectBox
  final tempDir = await Directory.systemTemp.createTemp('gecko_test_');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (MethodCall methodCall) async => tempDir.path,
  );

  await Durt().init(network: Networks.local, keyPairType: KeyPairType.ed25519);
  Durt.i.configBox.putValue('customEndpoint', 'ws://localhost:9944');
  await Durt.i.connect(initDuniter: true, initSquid: false, initDatapod: false, verbose: true);
});
```

**Sealing mode block production:** In sealing mode, blocks are not produced automatically. Manually spawn them when a transaction is pending:
```dart
if (status.state == TransactionState.pending) {
  await Durt.i.duniter.spawnBlock();
}
```

**Teardown:** Call `Durt.i.dispose()` wrapped in a try/catch (known durt2 teardown issue with concurrent stream iteration).

## Coverage

**Requirements:** No enforced coverage threshold.

**Run coverage:**
```bash
flutter test --coverage
# (then use lcov or genhtml to view)
```

## Test Types Summary

**Unit Tests (`test/providers/`, `test/services/`):**
- Scope: single provider or service in isolation
- Mock: all external dependencies via `ProviderContainer` overrides or mock classes
- No UI: pure logic testing

**Widget Tests (`test/widgets/`):**
- Scope: widget callback logic (stream handling, provider mutation)
- Approach: minimal stub widget replicating only the logic under test
- Dependencies: `ProviderContainer` + `UncontrolledProviderScope` + `MaterialApp`

**Integration Tests (`test/integration/`):**
- Scope: full blockchain transaction flows against duniter-mocks
- Requirements: external `duniter-mocks` process running
- Not run in CI by default; run manually

## Common Patterns

**Regression test naming:** Tests documenting fixed bugs use `'Bug: ...'` prefix:
```dart
test('Bug: recentCert (completed) doit primer sur certState.canCert', () async { ... });
test('Bug: certification en cours doit afficher "inProgress" et non "disabled"', () async { ... });
```

**Iteration over similar states:**
```dart
for (final status in [d.CertStatus.canRenewIn, d.CertStatus.mustWaitBeforeCert]) {
  group('CertStatus.${status.name}', () {
    test('pas en file → addToQueue', () async { ... });
  });
}
```

**Tolerance for time-dependent assertions:**
```dart
// Allow 2-3 second tolerance for test execution time
expect(remaining, greaterThan(117));
expect(remaining, lessThanOrEqualTo(120));
```

**State mutation tests (sequence testing):**
```dart
// Record action
await PinSecurityService.recordFailedAttempt(0);
// Assert intermediate state
expect(PinSecurityService.getFailedAttempts(0), 1);
// Continue sequence
await PinSecurityService.recordFailedAttempt(0);
await PinSecurityService.recordFailedAttempt(0);
expect(PinSecurityService.isLockedOut(0), true);
```

---

*Testing analysis: 2026-03-25*
