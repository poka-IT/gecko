// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:provider/provider.dart';
import 'package:truncate/truncate.dart';
// import 'package:web_socket_channel/io.dart';

class SubstrateSdk with ChangeNotifier {
  final int ss58 = 42;

  final WalletSDK sdk = WalletSDK();
  final Keyring keyring = Keyring();
  String generatedMnemonic = '';
  bool sdkReady = false;
  bool sdkLoading = false;
  bool nodeConnected = false;
  bool importIsLoading = false;
  int blocNumber = 0;
  bool isLoadingEndpoint = false;
  String debugConnection = '';
  String transactionStatus = '';

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

  Future<void> connectNode(BuildContext ctx) async {
    List<NetworkParams> node = [];

    for (String _endpoint in configBox.get('endpoint')) {
      final n = NetworkParams();
      n.name = currencyName;
      n.endpoint = _endpoint;
      n.ss58 = ss58;
      node.add(n);
    }
    int timeout = 10000;

    // if (n.endpoint!.startsWith('ws://')) {
    //   timeout = 5000;
    // }

    //// Check websocket conenction - only for wss
    // final channel = IOWebSocketChannel.connect(
    //   Uri.parse('wss://192.168.1.72:9944'),
    // );

    // channel.stream.listen(
    //   (dynamic message) {
    //     log.d('message $message');
    //   },
    //   onDone: () {
    //     log.d('ws channel closed');
    //   },
    //   onError: (error) {
    //     log.d('ws error $error');
    //   },
    // );

    if (sdk.api.connectedNode?.endpoint != null) {
      await sdk.api.setting.unsubscribeBestNumber();
    }

    isLoadingEndpoint = true;
    notifyListeners();
    final res = await sdk.api.connectNode(keyring, node).timeout(
          Duration(milliseconds: timeout),
          onTimeout: () => null,
        );
    isLoadingEndpoint = false;
    notifyListeners();
    if (res != null) {
      nodeConnected = true;

      // Subscribe bloc number
      sdk.api.setting.subscribeBestNumber((res) {
        blocNumber = int.parse(res.toString());
        notifyListeners();
      });
      notifyListeners();
      snackNode(ctx, true);
    } else {
      nodeConnected = false;
      debugConnection = res.toString();
      notifyListeners();
      snackNode(ctx, false);
    }

    log.d(sdk.api.connectedNode?.endpoint);
  }

  Future<String> importAccount(
      {String mnemonic = '',
      bool fromMnemonic = false,
      String derivePath = '',
      String password = ''}) async {
    // toy exercise immense month enter answer table prefer speed cycle gold phone
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (mnemonic != '') {
      fromMnemonic = true;
      generatedMnemonic = mnemonic;
    } else if (clipboardData!.text!.split(' ').length == 12) {
      fromMnemonic = true;
      generatedMnemonic = clipboardData.text!;
    }

    if (password == '') {
      password = keystorePassword.text;
    }

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
    if (clipboardData?.text != null) jsonKeystore.text = clipboardData!.text!;
    var json = await sdk.api.keyring
        .importAccount(keyring,
            keyType: keytype,
            key: keyToImport,
            name: derivePath,
            password: password,
            derivePath: derivePath,
            cryptoType: CryptoType.sr25519)
        .catchError((e) {
      importIsLoading = false;
      notifyListeners();
    });
    if (json == null) return '';
    print(json);
    try {
      await sdk.api.keyring.addAccount(
        keyring,
        keyType: keytype,
        acc: json,
        password: password,
      );
      // Clipboard.setData(ClipboardData(text: jsonEncode(acc.toJson())));
    } catch (e) {
      print(e);
      importIsLoading = false;
      notifyListeners();
    }

    importIsLoading = false;
    await Future.delayed(const Duration(milliseconds: 20));
    notifyListeners();
    final bakedAddress = keyring.allAccounts.last.address;
    return bakedAddress!;
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
      account.balance = await getBalance(element.address!);
      result.add(account);
    }

    return result;
  }

  Future<double> getBalance(String address, {bool isUd = false}) async {
    double balance = 0.0;
    if (nodeConnected) {
      final brutBalance = await sdk.api.account.queryBalance(address);
      balance = int.parse(brutBalance!.freeBalance) / 100;
    }
    return balance;
  }

  KeyPairData getKeypair(String address) {
    return keyring.keyPairs.firstWhere((kp) => kp.address == address,
        orElse: (() => KeyPairData()));
  }

  Future<bool> checkPassword(String address, String pass) async {
    final account = getKeypair(address);
    return await sdk.api.keyring.checkPassword(account, pass);
  }

  int getDerivationNumber(String address) {
    final account = getKeypair(address);
    final deriveNbr = account.name!.split('//')[1];
    return int.parse(deriveNbr);
  }

  Future<KeyPairData?> changePassword(
      String address, String passOld, String? passNew) async {
    final account = getKeypair(address);
    keyring.setCurrent(account);

    return await sdk.api.keyring.changePassword(keyring, passOld, passNew);
  }

  Future<void> deleteAllAccounts() async {
    for (var account in keyring.allAccounts) {
      await sdk.api.keyring.deleteAccount(keyring, account);
    }
  }

  Future<void> deleteAccounts(List<String> address) async {
    for (var a in address) {
      final account = getKeypair(a);
      await sdk.api.keyring.deleteAccount(keyring, account);
    }
  }

  Future<String> generateMnemonic({String lang = appLang}) async {
    final gen = await sdk.api.keyring.generateMnemonic(ss58);
    generatedMnemonic = gen.mnemonic!;

    // final res = await importAccount(fromMnemonic: true);
    // await Clipboard.setData(ClipboardData(text: generatedMnemonic));
    return gen.mnemonic!;
  }

  String setCurrentWallet(String address) {
    try {
      final acc = getKeypair(address);
      keyring.setCurrent(acc);
      return acc.address!;
    } catch (e) {
      return (e.toString());
    }
  }

  KeyPairData getCurrentWallet() {
    try {
      final acc = keyring.current;
      return acc;
    } catch (e) {
      return KeyPairData();
    }
  }

  Future<String> pay(
      {required String fromAddress,
      required String destAddress,
      required double amount,
      required String password}) async {
    transactionStatus = '';

    setCurrentWallet(fromAddress);

    log.d(keyring.current.address);
    log.d(fromAddress);
    log.d(password);
    log.d(await checkPassword(fromAddress, password));

    final sender = TxSenderData(
      keyring.current.address,
      keyring.current.pubKey,
    );
    final txInfo = TxInfoData('balances', 'transfer', sender);
    try {
      final hash = await sdk.api.tx.signAndSend(
        txInfo,
        [destAddress, amount * 100],
        password,
        onStatusChange: (status) {
          log.d('Transaction status: ' + status);
          if (status == 'Ready') {
            transactionStatus = 'sent';
            notifyListeners();
          }
        },
      ).timeout(
        const Duration(seconds: 12),
        onTimeout: () => {},
      );
      log.d(hash.toString());
      if (hash.isEmpty) {
        transactionStatus = 'timeout';
        notifyListeners();

        return 'timeout';
      } else {
        transactionStatus = hash.toString();
        notifyListeners();
        return hash.toString();
      }
    } catch (e) {
      transactionStatus = e.toString();
      notifyListeners();
      return e.toString();
    }
  }

  Future<String> certify(
      String fromAddress, String password, String toAddress) async {
    transactionStatus = '';

    setCurrentWallet(fromAddress);
    log.d('me: ' + fromAddress);
    log.d('to: ' + toAddress);

    final _myIdtyStatus = await idtyStatus(fromAddress);
    final _toIdtyStatus = await idtyStatus(toAddress);

    log.d(_myIdtyStatus);
    log.d(_toIdtyStatus);

    if (_myIdtyStatus != 'Validated') {
      transactionStatus = 'notMember';
      notifyListeners();
      return 'notMember';
    }

    final sender = TxSenderData(
      keyring.current.address,
      keyring.current.pubKey,
    );
    TxInfoData txInfo;

    if (_toIdtyStatus == 'noid') {
      txInfo = TxInfoData(
        'identity',
        'createIdentity',
        sender,
      );
    } else if (_toIdtyStatus == 'Validated' ||
        _toIdtyStatus == 'ConfirmedByOwner') {
      txInfo = TxInfoData(
        'cert',
        'addCert',
        sender,
      );
    } else {
      transactionStatus = 'cantBeCert';
      notifyListeners();
      return 'cantBeCert';
    }

    log.d('Cert action: ' + txInfo.call!);

    try {
      final hash = await sdk.api.tx
          .signAndSend(
            txInfo,
            [toAddress],
            password,
          )
          .timeout(
            const Duration(seconds: 12),
            onTimeout: () => {},
          );
      log.d(hash);
      if (hash.isEmpty) {
        transactionStatus = 'timeout';
        notifyListeners();

        return 'timeout';
      } else {
        transactionStatus = hash.toString();
        notifyListeners();
        return hash.toString();
      }
    } catch (e) {
      transactionStatus = e.toString();
      notifyListeners();
      return e.toString();
    }
  }

  Future<String> idtyStatus(String address) async {
    //   var tata = await sdk.webView!
    //       .evalJavascript('api.query.system.account("$address")');

    var idtyIndex = await sdk.webView!
        .evalJavascript('api.query.identity.identityIndexOf("$address")');

    if (idtyIndex == null) {
      return 'noid';
    }

    final idtyStatus = await sdk.webView!
        .evalJavascript('api.query.identity.identities($idtyIndex)');

    if (idtyStatus != null) {
      final String _status = idtyStatus['status'];
      log.d(_status);
      return (_status);
    } else {
      return 'expired';
    }
  }

  Future<String> confirmIdentity(
      String fromAddress, String name, String password) async {
    // Confirm identity
    setCurrentWallet(fromAddress);
    log.d('me: ' + keyring.current.address!);

    final sender = TxSenderData(
      keyring.current.address,
      keyring.current.pubKey,
    );

    final txInfo = TxInfoData(
      'identity',
      'confirmIdentity',
      sender,
    );

    try {
      final result = await sdk.api.tx.signAndSend(
        txInfo,
        [name],
        password,
      );
      log.d(result);
      return 'confirmed';
    } on Exception catch (e) {
      log.e(e);
      return e.toString();
    }
  }

  Future<bool> isMember(String address) async {
    return await idtyStatus(address) == 'Validated';
  }

  Future<String> derive(
      BuildContext context, String address, int number, String password) async {
    final keypair = getKeypair(address);

    final seedMap =
        await keyring.store.getDecryptedSeed(keypair.pubKey, password);

    if (seedMap?['type'] != 'mnemonic') return '';
    final List seedList = seedMap!['seed'].split('//');
    generatedMnemonic = seedList[0];

    return await importAccount(
        fromMnemonic: true, derivePath: '//$number', password: password);
  }

  Future<bool> isMnemonicValid(String mnemonic) async {
    // Needed for bad encoding of UTF-8
    mnemonic = mnemonic.replaceAll('é', 'é');
    mnemonic = mnemonic.replaceAll('è', 'è');

    return await sdk.api.keyring.checkMnemonicValid(mnemonic);
  }

  String? getConnectedEndpoint() {
    return sdk.api.connectedNode?.endpoint;
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

void snackNode(BuildContext context, bool isConnected) {
  String _message;
  if (!isConnected) {
    _message =
        "Aucun noeud Duniter disponible, veuillez réessayer ultérieurement:\n${configBox.get('endpoint').first}";
  } else {
    SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);

    _message =
        "Vous êtes connecté au noeud\n${_sub.getConnectedEndpoint()!.split('//')[1]}";
  }
  final snackBar = SnackBar(
      padding: const EdgeInsets.all(20),
      content: Text(_message, style: const TextStyle(fontSize: 16)),
      duration: const Duration(seconds: 4));
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

String getShortPubkey(String pubkey) {
  String pubkeyShort = truncate(pubkey, 7,
          omission: String.fromCharCode(0x2026),
          position: TruncatePosition.end) +
      truncate(pubkey, 6, omission: "", position: TruncatePosition.start);
  return pubkeyShort;
}

class PasswordException implements Exception {
  String cause;
  PasswordException(this.cause);
}
