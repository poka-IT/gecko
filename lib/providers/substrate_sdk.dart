// ignore_for_file: avoid_print

import 'dart:convert';
import "package:hex/hex.dart";
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:fast_base58/fast_base58.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/localStorage.dart';
import 'package:polkawallet_sdk/utils/index.dart';
import 'package:polkawallet_sdk/utils/localStorage.dart';
import 'package:truncate/truncate.dart';
import 'package:get_storage/get_storage.dart';
import 'package:aes_ecb_pkcs5_flutter/aes_ecb_pkcs5_flutter.dart';

class SubstrateSdk with ChangeNotifier {
  final List subNode = ['127.0.0.1:9944', '192.168.1.85:9944'];
  final bool isSsl = false;
  final int ss58 = 42;

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
    await keyring.init([ss58]);
    keyring.setSS58(ss58);

    await sdk.init(keyring);
    sdkReady = true;
    sdkLoading = false;
    notifyListeners();
  }

  Future<void> connectNode() async {
    final String socketKind = isSsl ? 'wss' : 'ws';
    List<NetworkParams> node = [];
    for (final sn in subNode) {
      final n = NetworkParams();
      n.name = 'duniter';
      n.endpoint = '$socketKind://$sn';
      n.ss58 = ss58;
      node.add(n);
    }
    final res = await sdk.api.connectNode(keyring, node).timeout(
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

  Future<bool> importAccount(
      {bool fromMnemonic = false, String derivePath = ''}) async {
    final KeyType keytype;
    final String keyToImport;
    if (fromMnemonic) {
      keytype = KeyType.mnemonic;
      keyToImport = generatedMnemonic;
    } else {
      keytype = KeyType.keystore;
      keyToImport = jsonKeystore.text.replaceAll("'", "\\'");
    }

    importIsLoading = true;
    notifyListeners();
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) jsonKeystore.text = clipboardData!.text!;
    var json = await sdk.api.keyring
        .importAccount(keyring,
            keyType: keytype,
            key: keyToImport,
            name: 'testKey',
            password: keystorePassword.text,
            derivePath: derivePath)
        .catchError((e) {
      importIsLoading = false;
      notifyListeners();
    });
    if (json == null) return false;
    print(json);
    try {
      final acc = await sdk.api.keyring.addAccount(
        keyring,
        keyType: KeyType.mnemonic,
        acc: json,
        password: keystorePassword.text,
      );
      Clipboard.setData(ClipboardData(text: jsonEncode(acc.toJson())));
    } catch (e) {
      importIsLoading = false;
      notifyListeners();
    }

    // await keystoreBox.clear();
    // await keystoreBox.add(acc.toJson());
    importIsLoading = false;
    await Future.delayed(const Duration(milliseconds: 20));
    notifyListeners();
    return true;
  }

  void reload() {
    notifyListeners();
  }

  Future<List<AddressInfo>> getKeyStoreAddress() async {
    List<AddressInfo> result = [];

    // sdk.api.account.unsubscribeBalance();
    for (var element in keyring.allAccounts) {
      // Clipboard.setData(ClipboardData(text: jsonEncode(element)));
      final account = AddressInfo(address: element.address);
      // await sdk.api.account.subscribeBalance(element.address, (p0) {
      //   account.balance = int.parse(p0.freeBalance) / 100;
      // });
      // sdk.api.setting.unsubscribeBestNumber();
      if (nodeConnected) {
        final brutBalance = await sdk.api.account.queryBalance(element.address);
        account.balance = int.parse(brutBalance!.freeBalance) / 100;
      }
      result.add(account);
    }

    return result;
  }

  Future<void> deleteAllAccounts() async {
    for (var account in keyring.allAccounts) {
      await sdk.api.keyring.deleteAccount(keyring, account);
    }
  }

  Future<bool> generateMnemonic() async {
    final gen = await sdk.api.keyring.generateMnemonic(ss58);
    generatedMnemonic = gen.mnemonic!;

    final res = await importAccount(fromMnemonic: true);

    return res;
  }

  pay(BuildContext context, String address, double amount,
      String password) async {
    final sender = TxSenderData(
      keyring.current.address,
      keyring.current.pubKey,
    );
    final txInfo = TxInfoData('balances', 'transfer', sender);
    try {
      final hash = await sdk.api.tx.signAndSend(
        txInfo,
        [address, amount * 100],
        password,
        onStatusChange: (status) {
          print('status: ' + status);
          if (status == 'Ready') {
            snack(context, 'Paiement effectué avec succès !');
          }
        },
      );
      print(hash.toString());
    } catch (err) {
      print(err.toString());
    }
  }

  derive(BuildContext context, String address, double amount,
      String password) async {
    final keypair =
        keyring.keyPairs.firstWhere((element) => element.address == address);

    // KeyringStorage _storage = KeyringStorage();
    // print(_storage.encryptedMnemonics.val);

    // final keyPairs = [].val('keyPairs', getBox: _storage);
    // final encryptedRawSeeds = {}.val('encryptedRawSeeds', getBox: _storage);

    print(await sdk.api.keyring.getDecryptedSeed(keyring, password));
    print(await keyring.store.getDecryptedSeed(keypair.pubKey, password));
    print(
        await keyring.store.checkSeedExist(KeyType.keystore, keypair.pubKey!));

    print(
        await keyring.store.checkSeedExist(KeyType.mnemonic, keypair.pubKey!));

    _storage() => GetStorage(sdk_storage_key);
    final encryptedMnemonics = {}.val('encryptedMnemonics', getBox: _storage);

    // await keyring.store.updateEncryptedSeed(keypair.pubKey, password, '012');
    final enc = encryptedMnemonics.val[keypair.pubKey!];
    // final key = Encrypt.passwordToEncryptKey(password);
    // const enc =
    //     '69E16A6F8CD15799FC036B3D71FC3C53EFCEDB6A2D4F2A743555809DC5B48D6FC25E96E5CFF8E7DF4FCE1AE9AFC61A0D85CDCAD945C5371F11DEBA1BF362B8124A4C8D264A05AC1D72F5A9566D0D3B35';

    final LocalStorage _storageOld = LocalStorage();

    print(enc);
    print(await _storageOld.getAccountList());
    print(await _storageOld.getSeeds('keystore'));
    // print(await FlutterAesEcbPkcs5.decryptString(enc, key));

    // generatedMnemonic = keypair.encoded;

    // importAccount();
  }
}

void snack(BuildContext context, String message, {int duration = 2}) {
  final snackBar =
      SnackBar(content: Text(message), duration: Duration(seconds: duration));
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

class AddressInfo {
  final String? address;
  double balance;

  AddressInfo({@required this.address, this.balance = 0});
}

String getShortPubkey(String pubkey) {
  List<int> pubkeyByte = Base58Decode(pubkey);
  Digest pubkeyS256 = sha256.convert(sha256.convert(pubkeyByte).bytes);
  String pubkeyCheksum = Base58Encode(pubkeyS256.bytes);
  String pubkeyChecksumShort =
      truncate(pubkeyCheksum, 3, omission: "", position: TruncatePosition.end);

  String pubkeyShort = truncate(pubkey, 5,
          omission: String.fromCharCode(0x2026),
          position: TruncatePosition.end) +
      truncate(pubkey, 4, omission: "", position: TruncatePosition.start) +
      ':$pubkeyChecksumShort';

  return pubkeyShort;
}
