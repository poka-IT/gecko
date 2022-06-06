// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:provider/provider.dart';

class SubscribeBalances with ChangeNotifier {
  Map<String, double> balances = {};

  Future<Map<String, double>> getBalance(
      BuildContext context, String address) async {
    SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);
    // double balance = 0;

    if (_sub.nodeConnected) {
      await _sub.sdk.api.account.subscribeBalance(
        address,
        (p0) {
          balances.clear();
          // balances[address] = int.parse(p0.freeBalance) / 100;
          balances.putIfAbsent(address, () => int.parse(p0.freeBalance) / 100);
          // balances.update(address, (_) => int.parse(p0.freeBalance) / 100);
          log.d('tatatatataata : ' + balances.toString());

          notifyListeners();
          // return balance;
        },
      );
    }
    log.d(balances);
    return balances;
  }

  void reload() {
    notifyListeners();
  }
}
