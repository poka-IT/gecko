import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:provider/provider.dart';

class ChestProvider with ChangeNotifier {
  void reload() {
    notifyListeners();
  }

  Future<void> forgetSafe(BuildContext context, ChestData chest) async {
    final bool? answer = await (_confirmDeletingChest(context, chest.name));

    if (answer ?? false) {
      // ignore: use_build_context_synchronously
      final myWallets = Provider.of<MyWalletsProvider>(context, listen: false);
      await myWallets.clearWallets(chest);

      Navigator.popUntil(
        // ignore: use_build_context_synchronously
        context,
        ModalRoute.withName('/'),
      );
      notifyListeners();
    }
  }

  ChestData get currentChestData => getChestData(getCurrentChestNumber());

  int getCurrentChestNumber() {
    if (configBox.get('currentChest') == null) {
      configBox.put('currentChest', 0);
      return 0;
    }

    return configBox.get('currentChest');
  }

  List<String> getChestWallets(ChestData chest) {
    List<String> toDelete = [];
    walletBox.toMap().forEach((key, WalletData value) {
      if (value.chest == chest.key) {
        toDelete.add(value.address);
      }
    });
    return toDelete;
  }

  ChestData getChestData(int chestNumber) {
    return chestBox.get(chestNumber)!;
  }

  Future<bool?> _confirmDeletingChest(BuildContext context, String? walletName) async {
    return showConfirmationDialog(
      context: context,
      type: ConfirmationDialogType.warning,
      message: 'areYouSureToForgetSafe'.tr(args: [walletName!]),
    );
  }
}
