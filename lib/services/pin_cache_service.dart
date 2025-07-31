import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/routes.dart';

class PinCodeService {
  static const String _storageKey = 'isCacheChecked';

  static String pinCode = '';

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
  static Future debounceResetPinCode([int minutes = 15]) async {
    lockPin++;
    final actualLock = lockPin;
    final pinCacheState = isEnabled;

    await Future.delayed(Duration(seconds: pinCacheState ? minutes * 60 : 1));
    log.i('reset pin code, lock $actualLock ...');
    if (actualLock == lockPin) pinCode = '';
  }

  static Future<bool> askPinCode({bool force = false, bool canSwitch = false}) async {
    final container = ProviderContainer();
    final defaultWallet = container.read(walletServiceProvider).defaultWallet!;

    if (pinCode.isEmpty || force) {
      pinCode = '';
      final result = await Navigator.pushNamed(
        homeContext,
        RouteNames.unlockingWallet,
        arguments: UnlockingWalletArguments(wallet: defaultWallet, canSwitch: canSwitch),
      );
      // Only continue if we actually got a valid PIN back
      if (result == null) return false;
    }
    return pinCode.isNotEmpty;
  }
}
