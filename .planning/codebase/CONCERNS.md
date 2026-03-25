# Codebase Concerns

**Analysis Date:** 2026-03-25

---

## Tech Debt

**Biometric provider marked as temporary implementation:**
- Issue: `BiometricNotifier` in `lib/providers/biometric_provider.dart` is explicitly marked "temporary implementation using local storage" across three methods (`enrollBiometric`, `authenticateWithBiometric`, `disableBiometric`). Waiting for durt2 to provide a proper biometric API.
- Files: `lib/providers/biometric_provider.dart` (lines 61, 188, 222, 267)
- Impact: If durt2's biometric API changes its interface, this layer will need a full rewrite. Also uses `Future.delayed(100ms)` as a race-condition workaround during state refresh.
- Fix approach: Remove temporary markers once durt2 exposes a stable biometric API. Replace polling delay with proper reactive pattern.

**NUCLEAR provider invalidation on Squid endpoint change:**
- Issue: `squid_invalidation_provider.dart` uses a self-described "NUCLEAR APPROACH" that invalidates `squidServiceProvider`, `durtProvider`, `genesisTimeProvider`, increments a cache-buster, and calls `invalidateSelf()` — all on every Squid endpoint change.
- Files: `lib/providers/squid_invalidation_provider.dart`, `lib/providers/squid_cache_buster.dart`
- Impact: Every network switch triggers a full provider tree rebuild. Heavy-handed; could cause visible UI flashes or redundant blockchain calls.
- Fix approach: Use targeted invalidation of only the Squid-dependent providers (transaction history, certifications) rather than nuking `durtProvider` wholesale.

**`provider` package is a declared dependency but mostly unused:**
- Issue: `pubspec.yaml` lists `provider: ^6.1.5+1`. The codebase has fully migrated to Riverpod. The package remains to satisfy transitive deps or occasional `ProviderScope.containerOf(context)` calls — but no `ChangeNotifier` classes or `MultiProvider` trees remain.
- Files: `pubspec.yaml`, `lib/utils/debug_test_wallet.dart` (uses `ProviderScope.containerOf`)
- Impact: Unnecessary dependency weight; signals incomplete migration to new reviewers.
- Fix approach: Audit whether `ProviderScope.containerOf` can be replaced by passing `WidgetRef`, then remove the `provider` package.

**Onboarding screens named with bare numerals (`1.dart` through `10.dart`):**
- Issue: All onboarding step files violate Dart file naming conventions and require `// ignore_for_file: file_names` at the top of 10 files.
- Files: `lib/screens/onBoarding/1.dart` through `lib/screens/onBoarding/10.dart`
- Impact: Poor discoverability; searching for "onboarding step 4" requires knowing the file is `4.dart`.
- Fix approach: Rename to `onboarding_step_01.dart` etc. and update route imports.

**`hive_generator` dependency is commented out due to build toolchain conflict:**
- Issue: `dev_dependencies` in `pubspec.yaml` has `# hive_generator: ^2.0.1 # Commented out: requires build ^2.0.0, incompatible with polkadart 1.0.0 (needs build ^4.0.3)`. The `.g.dart` Hive adapter files (`lib/models/g1_wallets_list.g.dart`, `lib/models/wallet_header_data.g.dart`) exist but cannot be regenerated.
- Files: `pubspec.yaml`, `lib/models/g1_wallets_list.g.dart`, `lib/models/wallet_header_data.g.dart`
- Impact: If the Hive model schema needs to change, the adapter code must be edited by hand.
- Fix approach: Migrate these two remaining Hive models to ObjectBox (where all primary wallet data already lives), or wait for a hive_generator version compatible with the polkadart dependency tree.

**`dart_code_linter` is disabled due to analyzer version conflict:**
- Issue: `dev_dependencies` has `# dart_code_linter: ^2.0.0 # Commented out: requires analyzer ^6.0.0, incompatible with polkadart 1.0.0 (needs analyzer >=9.0.0)`. Only `flutter_lints` is active, which is a minimal ruleset.
- Files: `pubspec.yaml`, `analysis_options.yaml`
- Impact: More advanced lint rules (unused code, missing docs, complex metrics) are not enforced.
- Fix approach: Re-enable once polkadart ships a compatible analyzer version.

---

## Known Bugs / Fragile Areas

**ObjectBox `ToMany` backlink cache returns stale data:**
- Issue: In at least 4 places the code explicitly works around a known ObjectBox bug where `safe.wallets.toList()` returns a stale cached list after wallet creation or deletion. Direct queries are used instead.
- Files: `lib/providers/wallets_provider.dart` (line 161), `lib/providers/safe_data_provider.dart` (line 89), `lib/providers/identity_providers.dart` (lines 247, 460), `lib/screens/myWallets/wallets_home.dart` (line 47)
- Impact: Any new code that naively uses `safe.wallets` or other `ToMany` backlinkings will silently operate on stale data.
- Fix approach: Document the pattern as a project-wide rule in CONVENTIONS.md. Consider an ObjectBox version upgrade to see if the bug is fixed upstream.

**`TransactionStatusCache` uses static mutable maps (unbounded growth):**
- Issue: `TransactionStatusCache._cache` and `TransactionStatusCache._temporaryToRealKeyMap` are static `Map` instances in `lib/widgets/transaction_in_progress_tile.dart`. `clearCache()` must be called manually; there is no TTL or size cap.
- Files: `lib/widgets/transaction_in_progress_tile.dart` (lines 29–31, 108–111)
- Impact: After many transactions over a long session, memory grows unboundedly. Cache is never pruned automatically.
- Fix approach: Add a LRU-style size limit (e.g. keep last 50 entries) or migrate to a Riverpod provider that auto-disposes.

**Arbitrary `Future.delayed` sleeps used as state synchronisation guards:**
- Issue: Multiple places use `Future.delayed(Duration(milliseconds: N))` to wait for presumed storage or widget state to settle, instead of waiting on actual completion signals.
- Files:
  - `lib/providers/biometric_provider.dart` (100ms, 50ms)
  - `lib/providers/safe_provider.dart` (50ms, 50ms)
  - `lib/screens/myWallets/unlocking_wallet.dart` (20ms, 100ms)
  - `lib/services/wallet_deletion_service.dart` (50ms)
- Impact: Race conditions on slower/faster devices. Flaky behaviour under load.
- Fix approach: Replace each delay with a proper await on the operation that must complete (ObjectBox async put, provider future, etc.).

**`_handleDataVersionCompatibility` silently wipes all user data on schema upgrade:**
- Issue: When `config.dataVersion < dataVersion` (i.e. any schema bump), the code immediately calls `config.clearAll()`, `Hive.deleteBoxFromDisk(...)`, and `walletService.clearWallets()` after showing a single "reinstall required" dialog. There is no migration path — only destruction.
- Files: `lib/providers/home_providers.dart` (lines 316–348)
- Impact: Any dataVersion bump (`const int dataVersion = 13` in `lib/globals.dart`) destroys all contacts, wallet header cache, and G1 wallet name cache on the user's device. The ObjectBox wallet/safe data itself is preserved, but auxiliary data is lost.
- Fix approach: Implement per-version migration steps instead of full wipe. At minimum, log what is being deleted and only delete caches that are actually incompatible.

**`AppInitNotifier.initApp` takes `BuildContext` and `WidgetRef` as parameters:**
- Issue: `lib/providers/home_providers.dart` line 284 exposes `initApp({required BuildContext context, required WidgetRef widgetRef})`. Providers must not hold context references because they can outlive the widget tree.
- Files: `lib/providers/home_providers.dart`, `lib/screens/home/home_screen.dart`
- Impact: If the widget is disposed while `initApp` runs (e.g. quick app restart), `context.mounted` checks inside will silently no-op instead of properly unwinding. Also makes testing harder.
- Fix approach: Pass context-sensitive operations (dialogs, navigation) via callbacks or events emitted to the UI layer.

---

## Security Considerations

**SSL bad-certificate acceptance in non-release builds:**
- Issue: `SslConfigService.configureSslCertificateHandling(allowBadCertificates: !kReleaseMode)` means profile and debug builds accept ANY certificate without validation.
- Files: `lib/main.dart` (line 111)
- Impact: During development/testing against real nodes or staging endpoints, MITM attacks are silently accepted.
- Fix approach: Use a separate allowlist for known self-signed Duniter node certificates rather than a global bypass.

**No certificate pinning for CesiumPlus profile API:**
- Issue: There is a `// TODO: Implement per-endpoint certificate pinning for CesiumPlus profile API.` comment in `lib/main.dart` (line 110).
- Files: `lib/main.dart` (line 110)
- Impact: CesiumPlus API responses (profile photos, usernames) can be spoofed by a MITM without detection.
- Fix approach: Implement certificate pinning or at minimum verify the CesiumPlus endpoint hostname against a known-good list.

**PIN stored in plain static memory (`PinCodeService._pinCode`):**
- Issue: `lib/services/pin_cache_service.dart` caches the raw PIN string as a plain `static String _pinCode`. This persists in process memory for up to 5 minutes (or 1 second if caching is disabled).
- Files: `lib/services/pin_cache_service.dart`
- Impact: Memory inspection / heap dump would expose the PIN in plaintext. On rooted Android devices or jailbroken iOS, this is exploitable.
- Fix approach: Zero-out the string on clear (Dart strings are immutable so this requires a different data structure), or never cache the PIN string and instead cache a session key derived from it.

**Debug cheat code `'triche'` bypasses mnemonic verification in debug mode:**
- Issue: Three locations accept the string `'triche'` as a valid mnemonic confirmation in `kDebugMode`.
- Files: `lib/providers/mnemonic_providers.dart` (line 318), `lib/providers/mnemonic_challenge_provider.dart` (lines 160, 180), `lib/widgets/desktop/modals/onboarding_modal.dart` (line 682)
- Impact: Acceptable in debug builds. Risk is low as `kDebugMode` is compile-time; release builds exclude these branches.
- Safe modification: This is intentional; no action needed unless a profile-mode build is distributed externally.

---

## Performance Bottlenecks

**`DistanceNotifier` uses a static per-process cache with 3-hour TTL:**
- Issue: `lib/providers/distance_provider.dart` stores results in `static final Map<String, _CachedResult> _cache` with a 3-hour TTL. This cache is shared across all `DistanceNotifier` instances and is never invalidated on network switch.
- Files: `lib/providers/distance_provider.dart` (lines 36–37)
- Impact: After a network switch (e.g. gdev → g1), distance data from the previous network is served stale for up to 3 hours.
- Fix approach: Include the active network identifier as part of the cache key, or clear the cache in `_invalidateSquidDependentProviders`.

**`walletHeaderDataBox` written on every profile view visit:**
- Issue: `lib/screens/profile_view.dart` (line 78) writes to `walletHeaderDataBox` every time a profile is viewed, using `await walletHeaderDataBox.put(address, data)`.
- Files: `lib/screens/profile_view.dart`
- Impact: Hive writes are synchronous disk I/O on the main thread for every profile screen visit. Noticeable on low-end Android devices.
- Fix approach: Debounce writes or only write when data actually changes.

---

## Scaling Limits

**30-wallet-per-safe hard cap:**
- Current capacity: `lib/globals.dart` defines `const int maxWalletsInSafe = 30`. The wallet scan logic in `lib/providers/wallet_scan_providers.dart` defaults `maxDerivations = 30`.
- Limit: Users with more than 30 derivations in a single safe cannot import all of them.
- Scaling path: Increase the constant, or implement paginated scanning that asks users to confirm additional derivations.

---

## Dependencies at Risk

**`provider` package unused but declared:**
- Risk: Listed in `pubspec.yaml` as `provider: ^6.1.5+1` but no `ChangeNotifier` code remains. Adds confusion and transitive dependency surface.
- Impact: Minimal runtime impact, but misleads future developers about the architecture.
- Migration plan: Verify `ProviderScope.containerOf` usages can be eliminated, then remove the dependency.

**`hive_flutter` / Hive used for three separate concerns (contacts, G1 wallet name cache, wallet header cache):**
- Risk: Core wallet data is now in ObjectBox (via durt2). Hive is kept only for contacts, name cache, and wallet header cache — but the generator is broken (see Tech Debt above).
- Impact: Model schema changes require manual `.g.dart` edits.
- Migration plan: Migrate contacts and wallet header cache to ObjectBox or SQLite (already used via `riverpod_sqflite`).

**`intl` version override:**
- Risk: `pubspec.yaml` has `dependency_overrides: intl: ^0.20.0` overriding `^0.19.0`. This means the version constraint is being force-overridden; if `easy_localization` or another package has a hard incompatibility at 0.20.x, the app may produce subtle i18n regressions.
- Files: `pubspec.yaml`
- Migration plan: Remove override once `easy_localization` updates its own `intl` constraint.

**Local `durt2` path override active in checked-in `pubspec.yaml`:**
- Risk: `dependency_overrides: durt2: path: ../durt2` is committed to the repo. Any developer who does not have `../durt2` checked out locally will get a build failure.
- Files: `pubspec.yaml`
- Impact: CI/CD and new developer onboarding fails unless `../durt2` is present.
- Fix approach: Make the override opt-in via a local `pubspec_overrides.yaml` (gitignored) rather than committed to `pubspec.yaml`.

---

## Test Coverage Gaps

**Unit test count: 5 files for 321 production source files (~1.6% file coverage):**
- What's not tested: All UI screens, all providers except `cert_button_state`, most services, all Riverpod stream providers, all migration flows.
- Files: `test/providers/cert_button_state_test.dart`, `test/services/pin_security_service_test.dart`, `test/widgets/transaction_in_progress_test.dart`, `test/integration/migrate_identity_test.dart`
- Risk: Regressions in core wallet flows (pay, certify, migrate) are only caught by manual QA or Sentry crash reports from production users.
- Priority: High

**No test coverage for biometric provider:**
- What's not tested: Enrollment, authentication, safe-mismatch detection, `refreshForSafe`.
- Files: `lib/providers/biometric_provider.dart`
- Risk: Silent regressions in biometric unlock — the most security-critical code path.
- Priority: High

**No test coverage for PIN cache service:**
- What's not tested: `debounceResetPinCode`, safe-number mismatch detection, cache-disable path.
- Files: `lib/services/pin_cache_service.dart`
- Risk: PIN exposed longer than intended, or auth bypassed by safe-number confusion.
- Priority: High

**No test coverage for data version migration wipe path:**
- What's not tested: `_handleDataVersionCompatibility` in `lib/providers/home_providers.dart`.
- Risk: A `dataVersion` bump silently wipes user contact data and caches with no recovery.
- Priority: Medium

**No test coverage for `squid_invalidation_provider` nuclear invalidation:**
- What's not tested: The cascade of invalidations triggered by an endpoint switch.
- Files: `lib/providers/squid_invalidation_provider.dart`
- Risk: Endpoint switches may leave stale state in some providers while others are rebuilt.
- Priority: Medium

---

*Concerns audit: 2026-03-25*
