import 'dart:async';
import 'package:durt2/durt2.dart' show SafeEntity;
import 'package:durt2/objectbox.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:provider/provider.dart' as old_provider;

class SafeProvider with ChangeNotifier {
  late ProviderContainer _container;

  SafeProvider() {
    _container = ProviderContainer();
  }

  @override
  void dispose() {
    _container.dispose();
    super.dispose();
  }

  void reload() {
    notifyListeners();
  }

  Future forgetSafe(BuildContext context, SafeEntity safe) async {
    final bool? answer = await (_confirmDeletingSafe(context, safe.name));
    // ignore: use_build_context_synchronously
    if (answer ?? false) {
      await _container.read(walletServiceProvider).deleteSafe(safe.number);
      final myWalletProvider =
          // ignore: use_build_context_synchronously
          old_provider.Provider.of<MyWalletsProvider>(context, listen: false);

      myWalletProvider.pinCode = '';

      if (_container.read(walletServiceProvider).safeBox.isEmpty()) {
        _container.read(walletServiceProvider).setDefaultSafeBoxNumber(0);
        // Clear the wallet list when no safes remain
        myWalletProvider.listWallets = [];
      } else {
        final int lastSafe = _container
            .read(walletServiceProvider)
            .safeBox
            .query()
            .build()
            .property(SafeEntity_.number)
            .max();
        _container.read(walletServiceProvider).setDefaultSafeBoxNumber(lastSafe);

        // Reload wallets for the new default safe
        await myWalletProvider.readAllWallets(safeBoxNumber: lastSafe);
      }

      myWalletProvider.notifyListeners();

      Navigator.popUntil(
        // ignore: use_build_context_synchronously
        context,
        ModalRoute.withName('/'),
      );
      notifyListeners();
    }
  }

  List<String> getSafeWallets(SafeEntity safe) {
    return safe.wallets.map((wallet) => wallet.address).toList();
  }

  Future<bool?> _confirmDeletingSafe(BuildContext context, String walletName) async {
    return showConfirmationDialog(
      context: context,
      type: ConfirmationDialogType.warning,
      message: 'areYouSureToForgetSafe'.tr(args: [walletName]),
    );
  }
}
