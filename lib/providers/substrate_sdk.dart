import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/home.dart';
import 'package:gecko/providers/my_wallets.dart';
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
  int ss58 = 42;

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
    HomeProvider homeProvider = Provider.of<HomeProvider>(ctx, listen: false);

    homeProvider.changeMessage("connectionPending".tr(), 0);

    // configBox.delete('customEndpoint');
    final List<NetworkParams> listEndpoints =
        configBox.containsKey('customEndpoint')
            ? [getDuniterCustomEndpoint()]
            : getDuniterBootstrap();

    int timeout = 10000;

    if (sdk.api.connectedNode?.endpoint != null) {
      await sdk.api.setting.unsubscribeBestNumber();
    }

    isLoadingEndpoint = true;
    notifyListeners();
    final res = await sdk.api.connectNode(keyring, listEndpoints).timeout(
          Duration(milliseconds: timeout),
          onTimeout: () => null,
        );
    isLoadingEndpoint = false;
    notifyListeners();
    if (res != null) {
      nodeConnected = true;
      // await getSs58Prefix();

      // Subscribe bloc number
      sdk.api.setting.subscribeBestNumber((res) {
        blocNumber = int.parse(res.toString());
        // log.d(sdk.api.connectedNode?.endpoint);
        if (sdk.api.connectedNode?.endpoint == null) {
          nodeConnected = false;
          homeProvider.changeMessage("networkLost".tr(), 0);
        } else {
          nodeConnected = true;
        }
        notifyListeners();
      });

      // currencyName = await getCurencyName();
      notifyListeners();
      homeProvider.changeMessage(
          "wellConnectedToNode"
              .tr(args: [getConnectedEndpoint()!.split('/')[2]]),
          5);
      // snackNode(ctx, true);
    } else {
      nodeConnected = false;
      debugConnection = res.toString();
      notifyListeners();
      homeProvider.changeMessage("noDuniterEndointAvailable".tr(), 0);
      // snackNode(ctx, false);
    }

    log.d(sdk.api.connectedNode?.endpoint);
  }

  List<NetworkParams> getDuniterBootstrap() {
    List<NetworkParams> node = [];

    for (String endpoint in configBox.get('endpoint')) {
      final n = NetworkParams();
      n.name = currencyName;
      n.endpoint = endpoint;
      n.ss58 = ss58;
      node.add(n);
    }
    return node;
  }

  NetworkParams getDuniterCustomEndpoint() {
    final nodeParams = NetworkParams();
    nodeParams.name = currencyName;
    nodeParams.endpoint = configBox.get('customEndpoint');
    nodeParams.ss58 = ss58;
    return nodeParams;
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
    // log.d(json);
    try {
      await sdk.api.keyring.addAccount(
        keyring,
        keyType: keytype,
        acc: json,
        password: password,
      );
    } catch (e) {
      log.e(e);
      importIsLoading = false;
      notifyListeners();
    }

    importIsLoading = false;

    notifyListeners();
    return keyring.allAccounts.last.address!;
  }

  void reload() {
    notifyListeners();
  }

  Future<List<AddressInfo>> getKeyStoreAddress() async {
    List<AddressInfo> result = [];

    for (var element in keyring.allAccounts) {
      final account = AddressInfo(address: element.address);
      account.balance = await getBalance(element.address!);
      result.add(account);
    }

    return result;
  }

  Future<int> getIdentityIndexOf(String address) async {
    return await sdk.webView!
            .evalJavascript('api.query.identity.identityIndexOf("$address")') ??
        0;
  }

  Future<List<int>> getCerts(String address) async {
    final idtyIndex = await getIdentityIndexOf(address);
    final certsReceiver = await sdk.webView!
            .evalJavascript('api.query.cert.storageIdtyCertMeta($idtyIndex)') ??
        [];

    return [certsReceiver['receivedCount'], certsReceiver['issuedCount']];
  }

  Future<int> getCertValidityPeriod(String from, String to) async {
    final idtyIndexFrom = await getIdentityIndexOf(from);
    final idtyIndexTo = await getIdentityIndexOf(to);

    if (idtyIndexFrom == 0 || idtyIndexTo == 0) return 0;

    final List certData = await sdk.webView!
            .evalJavascript('api.query.cert.certsByReceiver($idtyIndexTo)') ??
        [];

    if (certData.isEmpty) return 0;
    for (List certInfo in certData) {
      if (certInfo[0] == idtyIndexFrom) {
        return certInfo[1];
      }
    }

    return 0;
  }

  Future<Map<String, dynamic>> getParameters() async {
    final currencyParameters = await sdk.webView!
            .evalJavascript('api.query.parameters.parametersStorage()') ??
        {};
    return currencyParameters;
  }

  Future<bool> hasAccountConsumers(String address) async {
    final accountInfo = await sdk.webView!
        .evalJavascript('api.query.system.account("$address")');
    final consumers = accountInfo['consumers'];
    return consumers == 0 ? false : true;
  }

  Future<double> getBalance(String address) async {
    double balance = 0.0;

    if (nodeConnected) {
      final brutBalance = await sdk.api.account.queryBalance(address);
      // log.d(brutBalance?.toJson());
      balance = int.parse(brutBalance!.freeBalance) / 100;
    } else {
      balance = -1;
    }
    return balance;
  }

  Future<double> getUnclaimedUd(String address) async {
// TODO: Implement unclaimedUd evaluation
// Pour ce faire, il vous faut requêter cinq éléments de storage :

//     system.account(address)
//     identity.identityIndexOf(address)
//     identity.identities(idtyIndex)
//     universalDividend.currentUdIndex()
//     universalDividend.pastReevals()

// const api = await ApiPromise.create(...);
// const { data: balance } = await api.query.system.account(address);
// const idtyIndex = await api.query.identity.identityIndexOf(address);
// const { data: idtyData } = await api.query.identity.identies(idtyIndex);
// const currentUdIndex = await api.query.universalDividend.currentUdIndex();
// const pastReevals = await api.query.universalDividend.pastReevals();

// let newUdsAmount = computeClaimUds(currentUdIndex, idtyData.firstEligibleUd, pastReevals);
// let transferableBalance = balance.free + newUdsAmount;
// let potentialBalance = balance.reserved + transferableBalance;

    double balance = 0.0;

    final brutBalance = await sdk.api.account.queryBalance(address);
    // log.d(brutBalance?.toJson());
    balance = int.parse(brutBalance!.freeBalance) / 100;

    return balance;
  }

  Future<double> subscribeBalance(String address, {bool isUd = false}) async {
    double balance = 0.0;
    if (nodeConnected) {
      await sdk.api.account.subscribeBalance(address, (balanceData) {
        balance = int.parse(balanceData.freeBalance) / 100;
        notifyListeners();
      });
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

  Future<String> getSeed(String address, String pin) async {
    final account = getKeypair(address);
    keyring.setCurrent(account);

    final seed = await sdk.api.keyring.getDecryptedSeed(keyring, pin);

    String seedText;
    if (seed == null) {
      seedText = '';
    } else {
      seedText = seed.seed!.split('//')[0];
    }

    log.d(seedText);
    return seedText;
  }

  int getDerivationNumber(String address) {
    final account = getKeypair(address);
    final deriveNbr = account.name!.split('//')[1];
    return int.parse(deriveNbr);
  }

  Future<KeyPairData?> changePassword(BuildContext context, String address,
      String passOld, String? passNew) async {
    final account = getKeypair(address);
    MyWalletsProvider myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);
    keyring.setCurrent(account);
    myWalletProvider.resetPinCode();

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

    return gen.mnemonic!;
  }

  Future<String> setCurrentWallet(WalletData wallet) async {
    final currentChestNumber = configBox.get('currentChest');
    ChestData newChestData = chestBox.get(currentChestNumber)!;
    newChestData.defaultWallet = wallet.number;
    await chestBox.put(currentChestNumber, newChestData);

    try {
      final acc = getKeypair(wallet.address!);
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

    log.d(keyring.current.address);
    log.d(fromAddress);
    log.d(password);

    final fromPubkey = await sdk.api.account.decodeAddress([fromAddress]);
    log.d(fromPubkey!.keys.first);
    final sender = TxSenderData(
      fromAddress,
      fromPubkey.keys.first,
    );
    final txInfo = TxInfoData(
        'balances', amount == -1 ? 'transferAll' : 'transferKeepAlive', sender);

    final int amountUnit = (amount * 100).toInt();
    try {
      final hash = await sdk.api.tx.signAndSend(
        txInfo,
        [destAddress, amount == -1 ? false : amountUnit],
        password,
        onStatusChange: (status) {
          log.d('Transaction status: $status');
          transactionStatus = status;
          notifyListeners();
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

    log.d('me: $fromAddress');
    log.d('to: $toAddress');

    final myIdtyStatus = await idtyStatus(fromAddress);
    final toIdtyStatus = await idtyStatus(toAddress);

    final fromIndex = await getIdentityIndexOf(fromAddress);
    final toIndex = await getIdentityIndexOf(toAddress);

    log.d(myIdtyStatus);
    log.d(toIdtyStatus);

    if (myIdtyStatus != 'Validated') {
      transactionStatus = 'notMember';
      notifyListeners();
      return 'notMember';
    }

    final toCerts = await getCerts(toAddress);
    final currencyParameters = await getParameters();

    final sender = TxSenderData(
      keyring.current.address,
      keyring.current.pubKey,
    );
    TxInfoData txInfo;

    if (toIdtyStatus == 'noid') {
      txInfo = TxInfoData(
        'identity',
        'createIdentity',
        sender,
      );
    } else if (toIdtyStatus == 'Validated' ||
        toIdtyStatus == 'ConfirmedByOwner') {
      if (toCerts[0] >= currencyParameters['wotMinCertForMembership'] &&
          toIdtyStatus != 'Validated') {
        log.i('Batch cert and membership validation');
        txInfo = TxInfoData(
          'utility',
          'batchAll',
          sender,
        );
      } else {
        txInfo = TxInfoData(
          'cert',
          'addCert',
          sender,
        );
      }
    } else {
      transactionStatus = 'cantBeCert';
      notifyListeners();
      return 'cantBeCert';
    }

    log.d('Cert action: ${txInfo.call!}');

    try {
      List txOptions = [];
      if (txInfo.call == 'batchAll') {
        txOptions = [
          'cert.addCert($fromIndex, $toIndex)',
          'identity.validateIdentity($toIndex)'
        ];
      } else if (txInfo.call == 'createIdentity') {
        txOptions = [toAddress];
      } else if (txInfo.call == 'addCert') {
        txOptions = [fromIndex, toIndex];
      } else {
        log.e('TX call is unexpected');
        return 'Ğecko says: TX call is unexpected';
      }
      final hash = await sdk.api.tx
          .signAndSend(
            txInfo,
            txOptions,
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

  Future<String> idtyStatus(String address, [bool smooth = true]) async {
    var idtyIndex = await getIdentityIndexOf(address);

    if (idtyIndex == 0) {
      return 'noid';
    }

    final idtyStatus = await sdk.webView!
        .evalJavascript('api.query.identity.identities($idtyIndex)');

    if (idtyStatus != null) {
      final String status = idtyStatus['status'];

      return (status);
    } else {
      return 'expired';
    }
  }

  Future<String> confirmIdentity(
      String fromAddress, String name, String password) async {
    log.d('me: ${keyring.current.address!}');

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
      final hash = await sdk.api.tx.signAndSend(
        txInfo,
        [name],
        password,
        onStatusChange: (status) {
          log.d('Transaction status: $status');
          transactionStatus = status;
          notifyListeners();
        },
      ).timeout(
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
    } on Exception catch (e) {
      log.e(e);
      transactionStatus = e.toString();
      notifyListeners();
      return e.toString();
    }
  }

  Future<bool> isMemberGet(String address) async {
    return await idtyStatus(address) == 'Validated';
  }

  Future<String> getMemberAddress() async {
    // TODOO: Continue digging memberAddress detection
    String memberAddress = '';
    walletBox.toMap().forEach((key, value) async {
      final bool isMember = await isMemberGet(value.address!);
      log.d(isMember);
      if (isMember) {
        final currentChestNumber = configBox.get('currentChest');
        ChestData newChestData = chestBox.get(currentChestNumber)!;
        newChestData.memberWallet = value.number;
        await chestBox.put(currentChestNumber, newChestData);
        memberAddress = value.address!;
        return;
      }
    });
    log.d(memberAddress);
    return memberAddress;
  }

  Future<Map<String, int>> certState(String from, String to) async {
    Map<String, int> result = {};
    if (from != to && await isMemberGet(from)) {
      final removableOn = await getCertValidityPeriod(from, to);
      final certMeta = await getCertMeta(from);
      final int nextIssuableOn = certMeta['nextIssuableOn'] ?? 0;
      final certRemovableDuration = (removableOn - blocNumber) * 6;
      const int renewDelay = 2 * 30 * 24 * 3600; // 2 months

      if (certRemovableDuration >= renewDelay) {
        final certRenewDuration = certRemovableDuration - renewDelay;
        result.putIfAbsent('certRenewable', () => certRenewDuration);
      } else if (nextIssuableOn > blocNumber) {
        final certDelayDuration = (nextIssuableOn - blocNumber) * 6;
        result.putIfAbsent('certDelay', () => certDelayDuration);
      } else {
        result.putIfAbsent('canCert', () => 0);
      }
    }
    return result;
  }

  Future<Map> getCertMeta(String address) async {
    var idtyIndex = await getIdentityIndexOf(address);

    final certMeta = await sdk.webView!
            .evalJavascript('api.query.cert.storageIdtyCertMeta($idtyIndex)') ??
        '';

    return certMeta;
  }

  Future revokeIdentity(String address, String password) async {
    final idtyIndex = await getIdentityIndexOf(address);

    final sender = TxSenderData(
      keyring.current.address,
      keyring.current.pubKey,
    );

    log.d(sender.address);
    TxInfoData txInfo;

    txInfo = TxInfoData(
      'membership',
      'revokeMembership',
      sender,
    );

    try {
      final hash = await sdk.api.tx
          .signAndSend(
            txInfo,
            [idtyIndex],
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

  Future getCurencyName() async {}

  Future<String> derive(
      BuildContext context, String address, int number, String password) async {
    final keypair = getKeypair(address);

    final seedMap =
        await keyring.store.getDecryptedSeed(keypair.pubKey, password);

    if (seedMap?['type'] != 'mnemonic') return '';
    final List seedList = seedMap!['seed'].split('//');
    generatedMnemonic = seedList[0];

    return await importAccount(
        mnemonic: generatedMnemonic,
        fromMnemonic: true,
        derivePath: '//$number',
        password: password);
  }

  Future<String> generateRootKeypair(String address, String password) async {
    final keypair = getKeypair(address);

    final seedMap =
        await keyring.store.getDecryptedSeed(keypair.pubKey, password);

    if (seedMap?['type'] != 'mnemonic') return '';
    final List seedList = seedMap!['seed'].split('//');
    generatedMnemonic = seedList[0];

    return await importAccount(fromMnemonic: true, password: password);
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

  Future<int> getSs58Prefix() async {
    final List res = await sdk.webView!.evalJavascript(
            'api.consts.system.ss58Prefix.words',
            wrapPromise: false) ??
        [42];

    ss58 = res[0];
    log.d(ss58);
    return ss58;
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
  String message;
  if (!isConnected) {
    message =
        "${"noDuniterNodeAvailableTryLater".tr()}:\n${configBox.get('endpoint').first}";
  } else {
    SubstrateSdk sub = Provider.of<SubstrateSdk>(context, listen: false);

    message =
        "${"youAreConnectedToNode".tr()}\n${sub.getConnectedEndpoint()!.split('//')[1]}";
  }
  final snackBar = SnackBar(
      padding: const EdgeInsets.all(20),
      content: Text(message, style: const TextStyle(fontSize: 16)),
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
