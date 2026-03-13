import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/desktop/desktop_utils.dart';
import 'package:gecko/widgets/desktop/modals/pin_modal.dart';

class PinCodeService {
  static const String _storageKey = 'isCacheChecked';

  static String _pinCode = '';

  /// The safe number that [_pinCode] was validated against.
  /// Ensures the cached PIN is only reused for the same safe.
  static int? _authenticatedSafeNumber;

  /// Get/set the cached PIN code.
  /// Setting to empty automatically clears the authenticated safe.
  static String get pinCode => _pinCode;
  static set pinCode(String value) {
    _pinCode = value;
    if (value.isEmpty) _authenticatedSafeNumber = null;
  }

  /// Get the current PIN cache state
  static bool get isEnabled => configBox.get(_storageKey) ?? false;

  /// Set the PIN cache state
  static void setEnabled(bool enabled) {
    configBox.put(_storageKey, enabled);
  }

  /// Toggle the PIN cache state
  static void toggle() {
    setEnabled(!isEnabled);
  }

  static int lockPin = 0;

  /// Clears the cached PIN after a delay.
  /// When cache is enabled: clears after [minutes] (default 5 min).
  /// When cache is disabled: clears after 1 second.
  static Future debounceResetPinCode([int minutes = 5]) async {
    lockPin++;
    final actualLock = lockPin;
    final pinCacheState = isEnabled;

    await Future.delayed(Duration(seconds: pinCacheState ? minutes * 60 : 1));
    log.i('reset pin code, lock $actualLock ...');
    if (actualLock == lockPin) pinCode = '';
  }

  /// Record that the current [pinCode] was authenticated for [safeNumber].
  static void setAuthenticatedSafe(int safeNumber) {
    _authenticatedSafeNumber = safeNumber;
  }

  static Future<bool> askPinCode({bool force = false, bool canSwitch = false, d.WalletEntity? wallet}) async {
    final container = ProviderScope.containerOf(homeContext);
    final targetWallet = wallet ?? container.read(walletServiceProvider).defaultWallet;
    final targetSafeNumber = targetWallet.safe.target?.number;

    // Force re-auth if the cached PIN belongs to a different safe,
    // or if we don't know which safe it was validated against.
    final safeMismatch = pinCode.isNotEmpty && targetSafeNumber != null && _authenticatedSafeNumber != targetSafeNumber;

    if (pinCode.isEmpty || force || safeMismatch) {
      pinCode = '';

      // Use desktop modal on wide screens, full-screen route on mobile
      final Object? result;
      if (isDesktopLayout(homeContext)) {
        result = await showDesktopPinModal(homeContext, canSwitch: canSwitch, wallet: targetWallet);
      } else {
        result = await Navigator.pushNamed(
          homeContext,
          RouteNames.unlockingWallet,
          arguments: UnlockingWalletArguments(wallet: targetWallet, canSwitch: canSwitch),
        );
      }
      // Only continue if we actually got a valid PIN back
      if (result == null) return false;
    }
    return pinCode.isNotEmpty;
  }
}
