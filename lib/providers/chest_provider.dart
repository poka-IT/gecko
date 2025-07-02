import 'dart:async';
import 'package:durt2/durt2.dart' show Durt, SafeEntity;
import 'package:durt2/objectbox.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:provider/provider.dart';

class ChestProvider with ChangeNotifier {
  void reload() {
    notifyListeners();
  }

  Future forgetSafe(BuildContext context, SafeEntity safe) async {
    final bool? answer = await (_confirmDeletingChest(context, safe.name));
    // ignore: use_build_context_synchronously
    if (answer ?? false) {
      await Durt.i.wallets.deleteSafe(safe.id);
      final myWalletProvider =
          // ignore: use_build_context_synchronously
          Provider.of<MyWalletsProvider>(context, listen: false);

      myWalletProvider.pinCode = '';

      if (Durt.i.wallets.safeBox.isEmpty()) {
        Durt.i.wallets.setDefaultSafeBoxNumber(0);
      } else {
        final int lastSafe = Durt.i.wallets.safeBox.query().build().property(SafeEntity_.number).max();
        Durt.i.wallets.setDefaultSafeBoxNumber(lastSafe);
      }

      Navigator.popUntil(
        // ignore: use_build_context_synchronously
        context,
        ModalRoute.withName('/'),
      );
      notifyListeners();
    }
  }

  List<String> getChestWallets(SafeEntity safe) {
    return safe.wallets.map((wallet) => wallet.address).toList();
  }

  Future<bool?> _confirmDeletingChest(BuildContext context, String walletName) async {
    return showConfirmationDialog(
      context: context,
      type: ConfirmationDialogType.warning,
      message: 'areYouSureToForgetSafe'.tr(args: [walletName]),
    );
  }
}
