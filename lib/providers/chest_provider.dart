import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/chest_data.dart';

class ChestProvider with ChangeNotifier {
  void rebuildWidget() {
    notifyListeners();
  }

  Future deleteChest(context, ChestData _chest) async {
    final bool? _answer = await (_confirmDeletingChest(context, _chest.name));

    if (_answer!) {
      await chestBox.delete(_chest.key);
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
