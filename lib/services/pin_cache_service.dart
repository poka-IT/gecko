import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/main.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/services/config_service.dart';
import 'package:gecko/widgets/desktop/desktop_utils.dart';
import 'package:gecko/widgets/desktop/modals/pin_modal.dart';

/// PIN authentication service.
///
/// Exposes a **single canonical authentication entry point**,
/// [askPinCodeAndCapture], which every flow (crypto use or gate) must go
/// through. Direct access to the cached PIN value is deliberately impossible
/// from outside this class — the only way to obtain a usable PIN is via the
/// [String] returned by [askPinCodeAndCapture].
///
/// See `CLAUDE.md` → "PIN Code Authentication — Single API Rule" for the
/// full contract and usage patterns.
class PinCodeService {
  /// The cached PIN. **Never exposed publicly** — read via
  /// [askPinCodeAndCapture] (which returns a local copy) and write via
  /// [cachePin] / [clearPin]. Callers must never hold a reference to the
  /// static field itself because [debounceResetPinCode] clears it on a
  /// short timer.
  static String _pinCode = '';

  /// The safe number that [_pinCode] was validated against. Ensures the
  /// cached PIN is only reused for the same safe.
  static int? _authenticatedSafeNumber;

  /// Monotonic counter used by [debounceResetPinCode] to cancel pending
  /// clears when a fresh authentication happens.
  static int _lockPin = 0;

  static ConfigService get _config => ConfigService(configBox);

  /// `true` when a valid PIN is currently cached. Use this instead of
  /// reading the PIN value to detect authentication state (e.g. to decide
  /// whether to play an unlock animation).
  static bool get isUnlocked => _pinCode.isNotEmpty;

  /// Store a freshly-entered PIN in the cache. Called by PIN entry screens
  /// (onboarding, unlocking, change pin, restore, legacy import) after
  /// successful validation. Must be followed by [setAuthenticatedSafe]
  /// to record which safe the PIN was validated against, and by
  /// [debounceResetPinCode] on unlock flows to schedule auto-clearing.
  /// Pass the PIN through [clearPin] instead of an empty string.
  static void cachePin(String pin) {
    assert(pin.isNotEmpty, 'cachePin requires a non-empty PIN; use clearPin() instead');
    _pinCode = pin;
  }

  /// Clear the cached PIN immediately and forget the authenticated safe.
  /// Called on logout, wallet/safe deletion, and switch-safe flows.
  static void clearPin() {
    _pinCode = '';
    _authenticatedSafeNumber = null;
  }

  /// Record that the currently-cached PIN was authenticated for the given
  /// [safeNumber]. Called by PIN entry screens right after [cachePin].
  static void setAuthenticatedSafe(int safeNumber) {
    _authenticatedSafeNumber = safeNumber;
  }

  /// Whether the PIN cache config allows reusing the PIN across a long
  /// session (5 min) or forces a short-lived cache (1 s).
  static bool get isEnabled => _config.isCacheChecked;

  /// Toggle the PIN cache config. Called from the settings UI.
  static void toggle() {
    _config.isCacheChecked = !_config.isCacheChecked;
  }

  /// Clears the cached PIN after a delay.
  /// When cache is enabled: clears after [minutes] (default 5 min).
  /// When cache is disabled: clears after 1 second.
  static Future<void> debounceResetPinCode([int minutes = 5]) async {
    _lockPin++;
    final actualLock = _lockPin;
    final pinCacheState = isEnabled;

    await Future.delayed(Duration(seconds: pinCacheState ? minutes * 60 : 1));
    log.i('reset pin code, lock $actualLock ...');
    if (actualLock == _lockPin) clearPin();
  }

  /// Prompts the user for their PIN (or reuses the cache) and returns the
  /// captured PIN as a local [String].
  ///
  /// **This is the single, canonical authentication API.** Every flow that
  /// needs to authenticate the user — whether to subsequently use the PIN
  /// for a crypto operation or simply as an access gate — MUST go through
  /// this method. Do not access the cached PIN directly: it is cleared by
  /// [debounceResetPinCode] 1 second after successful authentication when
  /// the PIN cache is disabled (the default safe setting), so any code
  /// that reads it after an async gap is guaranteed to race the cache.
  ///
  /// The returned [String] is a local copy that survives the cache
  /// clearing. Forward it explicitly through your call chain (parameters,
  /// constructors, closures). Helpers that perform crypto
  /// (`CertificationTransactionHelper.executeCertification`,
  /// `walletActionsProvider.generateNewDerivation`, `paymentPopup`, etc.)
  /// require the PIN as a required parameter — the compiler enforces it.
  ///
  /// For **authentication gates** (flows that do not use the PIN for a
  /// crypto operation — e.g. navigation gates, "open screen X"), check
  /// `(await askPinCodeAndCapture(...)) != null` and discard the returned
  /// value. There is deliberately no boolean-only variant: every
  /// authentication point uses the same method, which makes the codebase
  /// impossible to mis-use.
  ///
  /// Returns `null` when the user cancels the PIN entry or authentication
  /// fails. Never returns an empty string.
  ///
  /// [force] re-prompts even if the PIN is cached.
  /// [canSwitch] allows the user to switch to another safe from the PIN
  /// dialog.
  /// [wallet] selects which safe's PIN to validate against (defaults to
  /// the current safe's first wallet).
  static Future<String?> askPinCodeAndCapture(
    BuildContext context, {
    bool force = false,
    bool canSwitch = false,
    d.WalletEntity? wallet,
  }) async {
    if (!await _promptPin(context, force: force, canSwitch: canSwitch, wallet: wallet)) {
      return null;
    }
    final captured = _pinCode;
    if (captured.isEmpty) {
      // Defensive: this should be unreachable because `_promptPin` only
      // returns `true` when `_pinCode` is non-empty. Log and bail out rather
      // than returning an empty string that downstream code would treat as
      // a valid PIN.
      log.e('askPinCodeAndCapture: PIN was empty immediately after _promptPin returned true');
      return null;
    }
    return captured;
  }

  /// Internal implementation of the PIN prompt flow. Not exposed publicly —
  /// all callers must go through [askPinCodeAndCapture] so that the PIN is
  /// captured into a local [String] and cannot race [debounceResetPinCode].
  ///
  /// Returns `true` when [_pinCode] is set to a valid PIN for the target
  /// safe (either from cache reuse or from a fresh prompt), `false` when
  /// the user cancelled or authentication failed.
  /// Resolves the Riverpod container from [context], falling back to the root
  /// navigator context when [context] is detached. A widget can be disposed
  /// during an awaited dialog before the PIN flow runs, leaving its context
  /// without a ProviderScope ancestor — `ProviderScope.containerOf` then throws
  /// "No ProviderScope found" (was AXIOM-TEAM-PE). The root navigator context
  /// always sits under the app's ProviderScope.
  static ProviderContainer _resolveContainer(BuildContext context) {
    try {
      return ProviderScope.containerOf(context);
    } catch (_) {
      final fallback = Gecko.navigatorContext;
      if (fallback != null) {
        return ProviderScope.containerOf(fallback);
      }
      rethrow;
    }
  }

  static Future<bool> _promptPin(
    BuildContext context, {
    bool force = false,
    bool canSwitch = false,
    d.WalletEntity? wallet,
  }) async {
    final container = _resolveContainer(context);
    final targetWallet = wallet ?? container.read(walletServiceProvider).defaultWallet;
    final targetSafeNumber = targetWallet.safe.target?.number;

    // Force re-auth if the cached PIN belongs to a different safe,
    // or if we don't know which safe it was validated against.
    final safeMismatch = isUnlocked && targetSafeNumber != null && _authenticatedSafeNumber != targetSafeNumber;

    if (!isUnlocked || force || safeMismatch) {
      clearPin();

      // Use desktop modal on wide screens, full-screen route on mobile
      final Object? result;
      if (isDesktopLayout(context)) {
        result = await showDesktopPinModal(context, canSwitch: canSwitch, wallet: targetWallet);
      } else {
        result = await Navigator.pushNamed(
          context,
          RouteNames.unlockingWallet,
          arguments: UnlockingWalletArguments(wallet: targetWallet, canSwitch: canSwitch),
        );
      }
      // Only continue if we actually got a valid PIN back
      if (result == null) return false;
    }
    return isUnlocked;
  }
}
