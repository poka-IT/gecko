import 'package:durt2/durt2.dart' show WalletEntity;
import 'package:flutter/material.dart';
import 'package:gecko/screens/myWallets/wallet_options.dart';
import 'package:gecko/services/wallet_name_service.dart';
import 'package:gecko/widgets/desktop/desktop_modal.dart';

/// Shows wallet options inside a desktop modal.
Future<void> showDesktopWalletOptionsModal(BuildContext context, {required WalletEntity wallet}) {
  final displayName = WalletNameService.displayName(wallet.name);

  return showDesktopModal(
    context: context,
    title: displayName,
    size: DesktopModalSize.medium,
    contentPadding: EdgeInsets.zero,
    builder: (context) => WalletOptions(wallet: wallet, embeddedMode: true),
  );
}
