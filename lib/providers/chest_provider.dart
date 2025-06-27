import 'dart:async';
import 'package:durt2/durt2.dart' show Durt, SafeBox, WalletData;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:provider/provider.dart';

class ChestProvider with ChangeNotifier {
  void reload() {
    notifyListeners();
  }

  Future forgetSafe(BuildContext context, SafeBox safe) async {
    final bool? answer = await (_confirmDeletingChest(context, safe.name));
    // ignore: use_build_context_synchronously
    if (answer ?? false) {
      await Durt.i.walletService.deleteSafe(safe.key);
      final myWalletProvider =
          // ignore: use_build_context_synchronously
          Provider.of<MyWalletsProvider>(context, listen: false);

      myWalletProvider.pinCode = '';

      if (Durt.i.walletService.safeBox.isEmpty) {
        await Durt.i.walletService.setDefaultSafeBoxNumber(0);
      } else {
        final int lastSafe = Durt.i.walletService.safeBox.toMap().keys.first;
        await Durt.i.walletService.setDefaultSafeBoxNumber(lastSafe);
      }

      Navigator.popUntil(
        // ignore: use_build_context_synchronously
        context,
        ModalRoute.withName('/'),
      );
      notifyListeners();
    }
  }

  List<String> getChestWallets(SafeBox safe) {
    List<String> toDelete = [];
    Durt.i.walletService.walletDataBox.toMap().forEach((key, WalletData value) {
      if (value.safeBoxNumber == safe.key) {
        toDelete.add(value.address);
      }
    });
    return toDelete;
  }

  Future<bool?> _confirmDeletingChest(BuildContext context, String? walletName) async {
    return showConfirmationDialog(
      context: context,
      type: ConfirmationDialogType.warning,
      message: 'areYouSureToForgetSafe'.tr(args: [walletName!]),
    );
  }
}
