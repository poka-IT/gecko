import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:provider/provider.dart';

class ChestProvider with ChangeNotifier {
  void reload() {
    notifyListeners();
  }

  Future deleteChest(context, ChestData chest) async {
    final bool? answer = await (_confirmDeletingChest(context, chest.name));
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    if (answer ?? false) {
      await sub.deleteAccounts(getChestWallets(chest));
      await chestBox.delete(chest.key);
      final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);

      myWalletProvider.pinCode = '';

      if (chestBox.isEmpty) {
        await configBox.put('currentChest', 0);
      } else {
        int? lastChest = chestBox.toMap().keys.first;
        await configBox.put('currentChest', lastChest);
      }

      Navigator.popUntil(
        context,
        ModalRoute.withName('/'),
      );
      notifyListeners();
    }
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

  Future<bool?> _confirmDeletingChest(context, String? walletName) async {
    return showConfirmationDialog(
      context: context,
      type: ConfirmationDialogType.warning,
      message: 'areYouSureToDeleteWallet'.tr(args: [walletName!]),
    );
  }
}
