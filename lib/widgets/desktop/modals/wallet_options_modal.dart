import 'package:durt2/durt2.dart' show WalletEntity;
import 'package:flutter/material.dart';
import 'package:gecko/screens/myWallets/wallet_options.dart';
import 'package:gecko/services/wallet_name_service.dart';
import 'package:gecko/widgets/desktop/desktop_modal.dart';
import 'package:gecko/widgets/desktop/modals/qr_code_modal.dart';
import 'package:gecko/widgets/wallet_header.dart';

/// Shows wallet options inside a desktop modal.
Future<void> showDesktopWalletOptionsModal(BuildContext context, {required WalletEntity wallet, VoidCallback? onBack}) {
  final displayName = WalletNameService.displayName(wallet.name);

  return showDesktopModal(
    context: context,
    title: displayName,
    size: DesktopModalSize.medium,
    contentPadding: EdgeInsets.zero,
    onBack: onBack,
    headerActions: [DesktopQrHeaderButton(address: wallet.address, username: displayName)],
    headerBackgroundColorBuilder: (context, ref) => walletHeaderSurfaceColor(context, ref, wallet.address),
    builder: (context) => WalletOptions(wallet: wallet, embeddedMode: true),
  );
}
