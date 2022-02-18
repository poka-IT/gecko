import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/keystore_data.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

class SubstrateSdk with ChangeNotifier {
  final String subNode = '192.168.1.85:9944';
  final bool isSsl = false;

  final WalletSDK sdk = WalletSDK();
  final Keyring keyring = Keyring();
  bool sdkReady = false;
  bool nodeConnected = false;
  int blocNumber = 0;

  TextEditingController jsonKeystore = TextEditingController();
  TextEditingController keystorePassword = TextEditingController();

  Future<void> initApi() async {
    await keyring.init([0, 2]);

    await sdk.init(keyring);
    sdkReady = true;
    notifyListeners();
  }

  Future<void> connectNode() async {
    final String socketKind = isSsl ? 'wss' : 'ws';
    final node = NetworkParams();
    node.name = 'pokaniter';
    node.endpoint = '$socketKind://$subNode';
    node.ss58 = 42;
    final res = await sdk.api.connectNode(keyring, [node]).timeout(
      const Duration(seconds: 10),
      onTimeout: () => null,
    );
    if (res != null) {
      nodeConnected = true;
      notifyListeners();
    }

    // Subscribe bloc number
    sdk.api.setting.subscribeBestNumber((res) {
      blocNumber = int.parse(res.toString());
      notifyListeners();
    });
  }

  Future<void> importFromKeystore() async {
    final json = await sdk.api.keyring.importAccount(
      keyring,
      keyType: KeyType.keystore,
      key: jsonKeystore.text,
      name: 'testKey',
      password: keystorePassword.text,
    );
    final acc = await sdk.api.keyring.addAccount(
      keyring,
      keyType: KeyType.mnemonic,
      acc: json!,
      password: keystorePassword.text,
    );

    KeyStoreData _keystore = KeyStoreData(keystore: acc);
    await keystoreBox.add(_keystore);
    notifyListeners();
  }

  void reload() {
    notifyListeners();
  }
}
