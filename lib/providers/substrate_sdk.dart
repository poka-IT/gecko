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

  /////////////////////////////////////
  ////////// 1: API METHODS ///////////
  /////////////////////////////////////

  Future<String> executeCall(TxInfoData txInfo, txOptions, String password,
      [String? rawParams]) async {
    try {
      final hash = await sdk.api.tx
          .signAndSend(txInfo, txOptions, password, rawParam: rawParams)
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

  Future getStorage(String call) async {
    return await sdk.webView!.evalJavascript('api.query.$call');
  }

  TxSenderData _setSender() {
    return TxSenderData(
      keyring.current.address,
      keyring.current.pubKey,
    );
  }

  ////////////////////////////////////////////
  ////////// 2: GET ONCHAIN STORAGE //////////
  ////////////////////////////////////////////

  Future<int> getIdentityIndexOf(String address) async {
    return await getStorage('identity.identityIndexOf("$address")') ?? 0;
  }

  Future<List<int>> getCerts(String address) async {
    final idtyIndex = await getIdentityIndexOf(address);
    final certsReceiver =
        await getStorage('cert.storageIdtyCertMeta($idtyIndex)') ?? [];

    return [certsReceiver['receivedCount'], certsReceiver['issuedCount']];
  }

  Future<int> getCertValidityPeriod(String from, String to) async {
    final idtyIndexFrom = await getIdentityIndexOf(from);
    final idtyIndexTo = await getIdentityIndexOf(to);

    if (idtyIndexFrom == 0 || idtyIndexTo == 0) return 0;

    final List certData =
        await getStorage('cert.certsByReceiver($idtyIndexTo)') ?? [];

    if (certData.isEmpty) return 0;
    for (List certInfo in certData) {
      if (certInfo[0] == idtyIndexFrom) {
        return certInfo[1];
      }
    }

    return 0;
  }

  Future<Map<String, dynamic>> getParameters() async {
    final currencyParameters =
        await getStorage('parameters.parametersStorage()') ?? {};
    return currencyParameters;
  }

  Future<bool> hasAccountConsumers(String address) async {
    final accountInfo = await getStorage('system.account("$address")');
    final consumers = accountInfo['consumers'];
    return consumers == 0 ? false : true;
  }

  // Future<double> getBalance(String address) async {
  //   double balance = 0.0;

  //   if (nodeConnected) {
  //     final brutBalance = await sdk.api.account.queryBalance(address);
  //     // log.d(brutBalance?.toJson());
  //     balance = int.parse(brutBalance!.freeBalance) / 100;
  //   } else {
  //     balance = -1;
  //   }

  //   await getUnclaimedUd(address);
  //   return balance;
  // }

  Future<Map<String, double>> getBalance(String address) async {
    if (!nodeConnected) {
      return {
        'transferableBalance': 0,
        'free': 0,
        'unclaimedUds': 0,
        'reserved': 0,
      };
    }

    // Get onchain storage values
    final Map balanceGlobal = await getStorage('system.account("$address")');
    final int? idtyIndex =
        await getStorage('identity.identityIndexOf("$address")');
    final Map? idtyData = idtyIndex == null
        ? null
        : await getStorage('identity.identities($idtyIndex)');
    final int currentUdIndex =
        int.parse(await getStorage('universalDividend.currentUdIndex()'));
    final List pastReevals =
        await getStorage('universalDividend.pastReevals()');

    // Compute amount of claimable UDs
    final int unclaimedUds = _computeUnclaimUds(currentUdIndex,
        idtyData?['data']?['firstEligibleUd'] ?? 0, pastReevals);

    // Calculate transferable and potential balance
    final int transferableBalance =
        (balanceGlobal['data']['free'] + unclaimedUds);

    Map<String, double> finalBalances = {
      'transferableBalance': transferableBalance / 100,
      'free': balanceGlobal['data']['free'] / 100,
      'unclaimedUds': unclaimedUds / 100,
      'reserved': balanceGlobal['data']['reserved'] / 100,
    };

    // log.i(finalBalances);

    return finalBalances;
  }

  int _computeUnclaimUds(
      int currentUdIndex, int firstEligibleUd, List pastReevals) {
    int totalAmount = 0;

    if (firstEligibleUd == 0) return 0;

    for (final List reval in pastReevals.reversed) {
      final int revalNbr = reval[0];
      final int revalValue = reval[1];

      // Loop each UDs revaluations and sum unclaimed balance
      if (revalNbr <= firstEligibleUd) {
        final count = currentUdIndex - firstEligibleUd;
        totalAmount += count * revalValue;
        break;
      } else {
        final count = currentUdIndex - revalNbr;
        totalAmount += count * revalValue;
        currentUdIndex = revalNbr;
      }
    }

    return totalAmount;
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

  Future<bool> isMemberGet(String address) async {
    return await idtyStatus(address) == 'Validated';
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
      log.d('tatatatata: ${nextIssuableOn - blocNumber}');
    }

    return result;
  }

  Future<Map> getCertMeta(String address) async {
    var idtyIndex = await getIdentityIndexOf(address);

    final certMeta =
        await getStorage('cert.storageIdtyCertMeta($idtyIndex)') ?? '';

    return certMeta;
  }

  Future<String> idtyStatus(String address, [bool smooth = true]) async {
    var idtyIndex = await getIdentityIndexOf(address);

    if (idtyIndex == 0) {
      return 'noid';
    }

    final idtyStatus = await getStorage('identity.identities($idtyIndex)');

    if (idtyStatus != null) {
      final String status = idtyStatus['status'];

      return (status);
    } else {
      return 'expired';
    }
  }

  Future getCurencyName() async {}

  /////////////////////////////////////
  ////// 3: SUBSTRATE CONNECTION //////
  /////////////////////////////////////

  Future<void> initApi() async {
    sdkLoading = true;
    await keyring.init([ss58]);
    keyring.setSS58(ss58);

    await sdk.init(keyring);
    sdkReady = true;
    sdkLoading = false;
    notifyListeners();
  }

  String? getConnectedEndpoint() {
    return sdk.api.connectedNode?.endpoint;
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

  //////////////////////////////////
  /////// 4: CRYPTOGRAPHY //////////
  //////////////////////////////////

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

  //////////////////////////////////////
  ///////// 5: CALLS EXECUTION /////////
  //////////////////////////////////////

  Future<String> pay(
      {required String fromAddress,
      required String destAddress,
      required double amount,
      required String password}) async {
    transactionStatus = '';
    final fromPubkey = await sdk.api.account.decodeAddress([fromAddress]);
    final int amountUnit = (amount * 100).toInt();

    final sender = TxSenderData(
      fromAddress,
      fromPubkey!.keys.first,
    );

    final globalBalance = await getBalance(fromAddress);
    TxInfoData txInfo;
    List txOptions = [];
    String? rawParams;

    if (globalBalance['unclaimedUds'] == 0) {
      txInfo = TxInfoData('balances',
          amount == -1 ? 'transferAll' : 'transferKeepAlive', sender);
      txOptions = [destAddress, amount == -1 ? false : amountUnit];
    } else {
      txInfo = TxInfoData(
        'utility',
        'batchAll',
        sender,
      );
      const tx1 = 'api.tx.universalDividend.claimUds()';
      final tx2 = amount == -1
          ? 'api.tx.balances.transferAll(false)'
          : 'api.tx.balances.transferKeepAlive("$destAddress", $amountUnit)';

      rawParams = '[[$tx1, $tx2]]';
    }

    // log.d('pay args:  ${txInfo.module}, ${txInfo.call}, $txOptions, $rawParams');
    return await executeCall(txInfo, txOptions, password, rawParams);
  }

  Future<String> certify(
      String fromAddress, String password, String toAddress) async {
    transactionStatus = '';

    final myIdtyStatus = await idtyStatus(fromAddress);
    final toIdtyStatus = await idtyStatus(toAddress);

    final fromIndex = await getIdentityIndexOf(fromAddress);
    final toIndex = await getIdentityIndexOf(toAddress);

    if (myIdtyStatus != 'Validated') {
      transactionStatus = 'notMember';
      notifyListeners();
      return 'notMember';
    }

    final sender = _setSender();
    TxInfoData txInfo;
    List txOptions = [];
    String? rawParams;

    final toCerts = await getCerts(toAddress);
    final currencyParameters = await getParameters();

    if (toIdtyStatus == 'noid') {
      txInfo = TxInfoData(
        'identity',
        'createIdentity',
        sender,
      );
      txOptions = [toAddress];
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
        final tx1 = 'cert.addCert($fromIndex, $toIndex)';
        final tx2 = 'identity.validateIdentity($toIndex)';

        rawParams = '[[$tx1, $tx2]]';
      } else {
        txInfo = TxInfoData(
          'cert',
          'addCert',
          sender,
        );
        txOptions = [fromIndex, toIndex];
      }
    } else {
      transactionStatus = 'cantBeCert';
      notifyListeners();
      return 'cantBeCert';
    }

    log.d('Cert action: ${txInfo.call!}');
    return await executeCall(txInfo, txOptions, password, rawParams);
  }

  // Future claimUDs(String password) async {
  //   final sender = TxSenderData(
  //     keyring.current.address,
  //     keyring.current.pubKey,
  //   );

  //   final txInfo = TxInfoData(
  //     'universalDividend',
  //     'claimUds',
  //     sender,
  //   );

  //   return await executeCall(txInfo, [], password);
  // }

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
    final txOptions = [name];

    return await executeCall(txInfo, txOptions, password);
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

    final txOptions = [idtyIndex];

    return await executeCall(txInfo, txOptions, password);
  }

  void reload() {
    notifyListeners();
  }
}

////////////////////////////////////////////
/////// 6: UI ELEMENTS (off class) /////////
////////////////////////////////////////////

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
