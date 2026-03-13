import 'package:durt2/durt2.dart' show WalletEntity;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/widgets/desktop/desktop_modal.dart';

/// Shows the PIN entry screen inside a desktop modal.
///
/// Returns the PIN code string on success, or null if dismissed.
Future<String?> showDesktopPinModal(BuildContext context, {bool canSwitch = false, WalletEntity? wallet}) {
  return showDesktopModal<String>(
    context: context,
    size: DesktopModalSize.small,
    title: 'toUnlockEnterPassword'.tr(),
    contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final targetWallet = wallet ?? ref.read(walletServiceProvider).defaultWallet;
        return UnlockingWallet(
          key: const ValueKey('desktop_pin_modal'),
          wallet: targetWallet,
          canSwitch: canSwitch,
          embeddedMode: true,
        );
      },
    ),
  );
}
