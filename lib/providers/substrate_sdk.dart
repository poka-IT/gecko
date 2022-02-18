import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

class SubstrateSdk with ChangeNotifier {
  final String subNode = '192.168.1.85:9944';
  final bool isSsl = false;

  final WalletSDK sdk = WalletSDK();
  final Keyring keyring = Keyring();
  String generatedMnemonic = '';
  bool sdkReady = false;
  bool sdkLoading = false;
  bool nodeConnected = false;
  bool importIsLoading = false;
  int blocNumber = 0;

  TextEditingController jsonKeystore = TextEditingController();
  TextEditingController keystorePassword = TextEditingController();

  Future<void> initApi() async {
    sdkLoading = true;
    await keyring.init([0, 2]);

    await sdk.init(keyring);
    sdkReady = true;
    sdkLoading = false;
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
    importIsLoading = true;
    notifyListeners();
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) jsonKeystore.text = clipboardData!.text!;
    final json = await sdk.api.keyring
        .importAccount(
      keyring,
      keyType: KeyType.keystore,
      key: jsonKeystore.text.replaceAll("'", "\\'"),
      name: 'testKey',
      password: keystorePassword.text,
    )
        .catchError((e) {
      importIsLoading = false;
      notifyListeners();
    });
    final acc = await sdk.api.keyring
        .addAccount(
      keyring,
      keyType: KeyType.mnemonic,
      acc: json!,
      password: keystorePassword.text,
    )
        .catchError((e) {
      importIsLoading = false;
      notifyListeners();
    });

    // await keystoreBox.clear();
    await keystoreBox.add(acc.toJson());
    Clipboard.setData(ClipboardData(text: jsonEncode(acc.toJson())));
    importIsLoading = false;
    notifyListeners();
  }

  void reload() {
    notifyListeners();
  }

  List getKeyStoreAddress() {
    List result = [];

    for (var element in keystoreBox.values) {
      // Clipboard.setData(ClipboardData(text: jsonEncode(element)));
      result.add(element['address']);
    }

    return result;
  }

  Future<String> generateMnemonic() async {
    final gen = await sdk.api.keyring.generateMnemonic(42);
    generatedMnemonic = gen.mnemonic!;
    notifyListeners();
    return gen.mnemonic!;
  }
}
