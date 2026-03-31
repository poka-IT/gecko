import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/services/wallet_name_service.dart';
import 'package:gecko/widgets/desktop/desktop_modal.dart';
import 'package:gecko/screens/myWallets/safe_options.dart';

/// Shows the safe options inside a desktop modal.
///
/// If [safeNumber] is provided, shows options for that specific safe.
/// Otherwise, shows options for the default (current) safe.
Future<void> showDesktopSafeOptionsModal(BuildContext context, WidgetRef ref, {int? safeNumber, VoidCallback? onBack}) {
  final walletService = ref.read(walletServiceProvider);
  if (walletService.safeBox.isEmpty()) return Future.value();

  // Resolve safe name
  final String safeName;
  if (safeNumber != null) {
    final allSafes = walletService.safeBox.getAll();
    final safe = allSafes.where((s) => s.number == safeNumber).firstOrNull;
    safeName = WalletNameService.displayName(safe?.name ?? '');
  } else {
    safeName = WalletNameService.displayName(walletService.defaultSafeBox.name);
  }

  return showDesktopModal(
    context: context,
    title: safeName,
    size: DesktopModalSize.small,
    contentPadding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
    onBack: onBack,
    builder: (context) => SingleChildScrollView(child: SafeOptionsContent(safeNumber: safeNumber)),
  );
}
