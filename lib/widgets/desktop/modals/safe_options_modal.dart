import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/services/wallet_name_service.dart';
import 'package:gecko/widgets/desktop/desktop_modal.dart';
import 'package:gecko/screens/myWallets/safe_options.dart';

/// Shows the safe options inside a desktop modal.
Future<void> showDesktopSafeOptionsModal(BuildContext context, WidgetRef ref) {
  final walletService = ref.read(walletServiceProvider);
  if (walletService.safeBox.isEmpty()) return Future.value();

  final safeName = WalletNameService.displayName(walletService.defaultSafeBox.name);

  return showDesktopModal(
    context: context,
    title: safeName,
    size: DesktopModalSize.small,
    contentPadding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
    builder: (context) => const SingleChildScrollView(child: SafeOptionsContent()),
  );
}
