import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:provider/provider.dart';

class ChestProvider with ChangeNotifier {
  void rebuildWidget() {
    notifyListeners();
  }

  Future deleteChest(context, ChestData _chest) async {
    final bool? _answer = await (_confirmDeletingChest(context, _chest.name));
    SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);
    if (_answer ?? false) {
      await _sub.deleteAccounts(getChestWallets(_chest));
      await chestBox.delete(_chest.key);
      MyWalletsProvider _myWalletProvider =
          Provider.of<MyWalletsProvider>(context, listen: false);

      _myWalletProvider.pinCode = '';

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

  List<String> getChestWallets(ChestData _chest) {
    List<String> toDelete = [];
    log.d(_chest.key);
    walletBox.toMap().forEach((key, WalletData value) {
      if (value.chest == _chest.key) {
        toDelete.add(value.address!);
      }
    });
    return toDelete;
  }

  Future<bool?> _confirmDeletingChest(context, String? _walletName) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              'Êtes-vous sûr de vouloir supprimer le coffre "$_walletName" ?'),
          actions: <Widget>[
            TextButton(
              child: const Text("Non", key: Key('cancelDeleting')),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            TextButton(
              child: const Text("Oui", key: Key('confirmDeleting')),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    );
  }
}
