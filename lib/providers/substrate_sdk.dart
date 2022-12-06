// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:fast_base58/fast_base58.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/home.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:pinenacl/ed25519.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/webviewWithExtension/types/signExtrinsicParam.dart';
import 'package:provider/provider.dart';
import 'package:truncate/truncate.dart';
import 'package:pointycastle/pointycastle.dart' as pc;
import "package:hex/hex.dart";

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
  final int initSs58 = 42;
  Map<String, int> currencyParameters = {};
  TextEditingController csSalt = TextEditingController();
  TextEditingController csPassword = TextEditingController();
  String g1V1NewAddress = '';
  String g1V1OldPubkey = '';
  bool isCesiumIDVisible = false;
  bool isCesiumAddresLoading = false;
  late int udValue;
  Map<String, List<int>> certsCounterCache = {};

  /////////////////////////////////////
  ////////// 1: API METHODS ///////////
  /////////////////////////////////////

  Future<String> _executeCall(TxInfoData txInfo, txOptions, String password,
      [String? rawParams]) async {
    final walletOptions =
        Provider.of<WalletOptionsProvider>(homeContext, listen: false);
    final walletProfiles =
        Provider.of<WalletsProfilesProvider>(homeContext, listen: false);
    try {
      final hash = await sdk.api.tx.signAndSend(txInfo, txOptions, password,
          rawParam: rawParams, onStatusChange: (p0) {
        transactionStatus = p0;
        notifyListeners();
      }).timeout(
        const Duration(seconds: 18),
        onTimeout: () => {},
      );
      log.d(hash);
      if (hash.isEmpty) {
        transactionStatus = 'timeout';
        notifyListeners();

        return 'timeout';
      } else {
        // Success !
        transactionStatus = hash.toString();
        notifyListeners();
        walletOptions.reload();
        walletProfiles.reload();
        return hash.toString();
      }
    } catch (e) {
      transactionStatus = e.toString();
      notifyListeners();
      return e.toString();
    }
  }

  Future _getStorage(String call) async {
    return await sdk.webView!.evalJavascript('api.query.$call');
  }

  Future _getStorageConst(String call) async {
    return (await sdk.webView!
            .evalJavascript('api.consts.$call', wrapPromise: false) ??
        [null])[0];
  }

  Future<TxSenderData> _setSender(String address) async {
    final fromPubkey = await sdk.api.account.decodeAddress([address]);
    return TxSenderData(
      address,
      fromPubkey!.keys.first,
    );
  }

  Future<String> _signMessage(
      Uint8List message, String address, String password) async {
    final params = SignAsExtensionParam();
    params.msgType = "pub(bytes.sign)";
    params.request = {
      "address": address,
      "data": message,
    };

    final res = await sdk.api.keyring.signAsExtension(password, params);
    return res?.signature ?? '';
  }

  ////////////////////////////////////////////
  ////////// 2: GET ONCHAIN STORAGE //////////
  ////////////////////////////////////////////

  Future<int> _getIdentityIndexOf(String address) async {
    return await _getStorage('identity.identityIndexOf("$address")') ?? 0;
  }

  Future<List<int>> getCertsCounter(String address) async {
    final idtyIndex = await _getIdentityIndexOf(address);
    final certsReceiver =
        await _getStorage('cert.storageIdtyCertMeta($idtyIndex)') ?? [];

    if (certsCounterCache[address] == null) {
      certsCounterCache.putIfAbsent(address, () => []);
    }
    certsCounterCache.update(
        address,
        (value) =>
            [certsReceiver['receivedCount'], certsReceiver['issuedCount']]);

    return certsCounterCache[address]!;
  }

  Future<int> getCertValidityPeriod(String from, String to) async {
    final idtyIndexFrom = await _getIdentityIndexOf(from);
    final idtyIndexTo = await _getIdentityIndexOf(to);

    if (idtyIndexFrom == 0 || idtyIndexTo == 0) return 0;

    final List certData =
        await _getStorage('cert.certsByReceiver($idtyIndexTo)') ?? [];

    if (certData.isEmpty) return 0;
    for (List certInfo in certData) {
      if (certInfo[0] == idtyIndexFrom) {
        return certInfo[1];
      }
    }

    return 0;
  }

  Future<bool> hasAccountConsumers(String address) async {
    final accountInfo = await _getStorage('system.account("$address")');
    final consumers = accountInfo['consumers'];
    return consumers == 0 ? false : true;
  }

  Future<int> getUdValue() async {
    udValue = int.parse(await _getStorage('universalDividend.currentUd()'));
    return udValue;
  }

  Future<double> getBalanceRatio() async {
    udValue = await getUdValue();
    balanceRatio =
        (configBox.get('isUdUnit') ?? false) ? round(udValue / 100, 6) : 1;
    return balanceRatio;
  }

  Future<Map<String, double>> getBalance(String address) async {
    // log.d('currencyParameters: $currencyParameters');

    if (!nodeConnected) {
      return {
        'transferableBalance': 0,
        'free': 0,
        'unclaimedUds': 0,
        'reserved': 0,
      };
    }

    // Get onchain storage values
    final Map balanceGlobal = await _getStorage('system.account("$address")');
    final int? idtyIndex =
        await _getStorage('identity.identityIndexOf("$address")');
    final Map? idtyData = idtyIndex == null
        ? null
        : await _getStorage('identity.identities($idtyIndex)');
    final int currentUdIndex =
        int.parse(await _getStorage('universalDividend.currentUdIndex()'));
    final List pastReevals =
        await _getStorage('universalDividend.pastReevals()');

    // Compute amount of claimable UDs
    final int unclaimedUds = _computeUnclaimUds(currentUdIndex,
        idtyData?['data']?['firstEligibleUd'] ?? 0, pastReevals);

    // Calculate transferable and potential balance
    final int transferableBalance =
        (balanceGlobal['data']['free'] + unclaimedUds);

    // log.d('udValue: $udValue');

    Map<String, double> finalBalances = {
      'transferableBalance': round((transferableBalance / balanceRatio) / 100),
      'free': round((balanceGlobal['data']['free'] / balanceRatio) / 100),
      'unclaimedUds': round((unclaimedUds / balanceRatio) / 100),
      'reserved':
          round((balanceGlobal['data']['reserved'] / balanceRatio) / 100),
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

  Future<bool> isMemberGet(String address) async {
    return await idtyStatus(address) == 'Validated';
  }

  Future<bool> isSmithGet(String address) async {
    var idtyIndex = await _getIdentityIndexOf(address);

    final Map smithExpireOn =
        (await _getStorage('smithsMembership.membership($idtyIndex)')) ?? {};

    if (smithExpireOn.isEmpty) {
      return false;
    } else {
      return true;
    }
  }

  Future<Map<String, int>> certState(String from, String to) async {
    Map<String, int> result = {};
    final toStatus = await idtyStatus(to);

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
      } else if (toStatus == 'Created') {
        result.putIfAbsent('toStatus', () => 1);
      } else if (toStatus == 'noid') {
        result.putIfAbsent('toStatus', () => 2);
        result.putIfAbsent('canCert', () => 0);
      } else {
        result.putIfAbsent('canCert', () => 0);
      }
    }

    // if (toStatus == 'Created') result.putIfAbsent('toStatus', () => 1);

    return result;
  }

  Future<Map> getCertMeta(String address) async {
    var idtyIndex = await _getIdentityIndexOf(address);

    final certMeta =
        await _getStorage('cert.storageIdtyCertMeta($idtyIndex)') ?? '';

    return certMeta;
  }

  Future<String> idtyStatus(String address) async {
    // final walletOptions =
    //     Provider.of<WalletOptionsProvider>(homeContext, listen: false);

    var idtyIndex = await _getIdentityIndexOf(address);

    if (idtyIndex == 0) {
      return 'noid';
    }

    final idtyStatus = await _getStorage('identity.identities($idtyIndex)');

    if (idtyStatus != null) {
      final String status = idtyStatus['status'];

      // if (address == walletOptions.address.text && status == 'Validated') {
      //   walletOptions.reloadBuild();
      // }

      return (status);
    } else {
      return 'expired';
    }
  }

  Future<bool> isSmith(String address) async {
    var idtyIndex = await _getIdentityIndexOf(address);
    if (idtyIndex == 0) return false;

    final isSmith =
        await _getStorage('smithsMembership.membership($idtyIndex)');
    return isSmith == null ? false : true;
  }

  Future<String> getGenesisHash() async {
    final String genesisHash = await sdk.webView!.evalJavascript(
          'api.genesisHash.toHex()',
          wrapPromise: false,
        ) ??
        [];
    // log.d('genesisHash: $genesisHash');
    // log.d('genesisHash: ${HEX.decode(genesisHash.substring(2))}');
    return genesisHash;
  }

  Future<Uint8List> addressToPubkey(String address) async {
    final pubkey = await sdk.api.account.decodeAddress([address]);
    final String pubkeyHex = pubkey!.keys.first;
    final pubkeyByte = HEX.decode(pubkeyHex.substring(2)) as Uint8List;
    // final pubkey58 = Base58Encode(pubkeyByte);

    return pubkeyByte;
  }

  // Future pubkeyToAddress(String pubkey) async {
  //   await sdk.api.account.encodeAddress([pubkey]);
  // }

  Future initCurrencyParameters() async {
    currencyParameters['ss58'] =
        await _getStorageConst('system.ss58Prefix.words');
    currencyParameters['minCertForMembership'] =
        await _getStorageConst('wot.minCertForMembership.words');
    currencyParameters['newAccountPrice'] =
        await _getStorageConst('account.newAccountPrice.words');
    currencyParameters['existentialDeposit'] =
        await _getStorageConst('balances.existentialDeposit.words');
    currencyParameters['certPeriod'] =
        await _getStorageConst('cert.certPeriod.words');
    currencyParameters['certMaxByIssuer'] =
        await _getStorageConst('cert.maxByIssuer.words');
    currencyParameters['certValidityPeriod'] =
        await _getStorageConst('cert.validityPeriod.words');

    log.i('currencyParameters: $currencyParameters');
  }

  void cesiumIDisVisible() {
    isCesiumIDVisible = !isCesiumIDVisible;
    notifyListeners();
  }

  Future<double> txFees(
      String fromAddress, String destAddress, double amount) async {
    if (amount == 0) return 0;
    final sender = await _setSender(fromAddress);
    final txInfo = TxInfoData('balances', 'transferKeepAlive', sender);
    final amountUnit = (amount * 100).toInt();

    final estimateFees =
        await sdk.api.tx.estimateFees(txInfo, [destAddress, amountUnit]);

    return estimateFees.partialFee / 100;
  }

  int hexStringToUint16(String input) {
    // Slice the string in 2-char substrings and parse it from hex to decimal
    final bytes = sliceString(input, 2).map((s) => int.parse(s, radix: 16));

    // Create a Uint8 from the 2-bytes list
    final u8list = Uint8List.fromList(bytes.toList());

    // Return a Uint16 little endian representation
    return ByteData.view(u8list.buffer).getUint16(0, Endian.little);
  }

  List<String> sliceString(String input, int count) {
    if (input.isEmpty) return [];

    if (input.length % count != 0) {
      throw ArgumentError("Cannot slice $input in $count slices.");
    }
    // final slices = List<String>(count);
    var slices = List<String>.filled(count, '');

    int len = input.length;
    int sliceSize = len ~/ count;

    for (var i = 0; i < count; i++) {
      var start = i * sliceSize;
      slices[i] = input.substring(start, start + sliceSize);
    }

    return List.unmodifiable(slices);
  }

  Future<DateFormat> getBlockchainStart() async {
    ////// Manu indexer
    //// Extract block date. Ugly, I can't find a better way to get the date of the block ?
    //// The only polkadot issue for that : https://github.com/polkadot-js/api/issues/2603
    // const created_at = new Date(
    //   signedBlock.block.extrinsics
    //     .filter(
    //       ({ method: { section, method } }) =>
    //         section === 'timestamp' && method === 'set'
    //     )[0]
    //     .args[0].toNumber()
    // )
    //// manu rpc
    // genesis: api.genesisHash.toHex(),
    // chain: await api.rpc.chain.getHeader(),
    // chainInfo: await api.registry.getChainProperties(),
    // test: await api.rpc.state.getPairs('0x')
    // query block finalisé qui ne change jamais.
    // api.rpc.chain.subscribeFinalizedHeads
    // events: await api.rpc.state.getStorage('0x26aa394eea5630e07c48ae0c9558cef780d41e5e16056765bc8461851072c9d7'),
    // lastFinalizedBlock: await api.rpc.chain.getFinalizedHead()
    // get block
    // api.rpc.chain.getFinalizedHead

    // shit
    // final blockHash =
    //     await sdk.webView!.evalJavascript('api.rpc.chain.getBlockHash(1)');
    // final Map blockContent = await sdk.webView!
    //     .evalJavascript('api.rpc.chain.getBlock("$blockHash")');
    // final String dateBrut = blockContent['block']['extrinsics'][0];

    // final dateTextByte = hex.decode(dateBrut.substring(2));

    // final dateText = await sdk.webView!
    //     .evalJavascript('api.tx($dateTextByte)', wrapPromise: false);

    // log.d('aaaaaaaaaaaaaaaaaaaaa: $dateText');
    return DateFormat();
  }

  /////////////////////////////////////
  ////// 3: SUBSTRATE CONNECTION //////
  /////////////////////////////////////

  Future<void> initApi() async {
    sdkLoading = true;
    await keyring.init([initSs58]);
    keyring.setSS58(initSs58);

    await sdk.init(keyring);
    sdkReady = true;
    sdkLoading = false;
    notifyListeners();
  }

  String? getConnectedEndpoint() {
    return sdk.api.connectedNode?.endpoint;
  }

  Future<void> connectNode(BuildContext ctx) async {
    final homeProvider = Provider.of<HomeProvider>(ctx, listen: false);
    final myWalletProvider = Provider.of<MyWalletsProvider>(ctx, listen: false);

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

      await getBalanceRatio();

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
      if (!myWalletProvider.checkIfWalletExist()) snackNode(homeContext, false);
    }

    log.d(sdk.api.connectedNode?.endpoint);
  }

  List<NetworkParams> getDuniterBootstrap() {
    List<NetworkParams> node = [];

    for (String endpoint in configBox.get('endpoint')) {
      final n = NetworkParams();
      n.name = currencyName;
      n.endpoint = endpoint;
      n.ss58 = currencyParameters['ss58'] ?? initSs58;
      node.add(n);
    }
    return node;
  }

  NetworkParams getDuniterCustomEndpoint() {
    final nodeParams = NetworkParams();
    nodeParams.name = currencyName;
    nodeParams.endpoint = configBox.get('customEndpoint');
    nodeParams.ss58 = currencyParameters['ss58'] ?? initSs58;
    return nodeParams;
  }

  Future<String> importAccount(
      {String mnemonic = '',
      String derivePath = '',
      required String password}) async {
    const keytype = KeyType.mnemonic;
    if (mnemonic != '') generatedMnemonic = mnemonic;

    importIsLoading = true;
    notifyListeners();

    final json = await sdk.api.keyring
        .importAccount(keyring,
            keyType: keytype,
            key: generatedMnemonic,
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
      String passOld, String passNew) async {
    final account = getKeypair(address);
    final myWalletProvider =
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
    final gen = await sdk.api.keyring
        .generateMnemonic(currencyParameters['ss58'] ?? initSs58);
    generatedMnemonic = gen.mnemonic!;

    return gen.mnemonic!;
  }

  Future<String> setCurrentWallet(WalletData wallet) async {
    final currentChestNumber = configBox.get('currentChest');
    ChestData newChestData = chestBox.get(currentChestNumber)!;
    newChestData.defaultWallet = wallet.number;
    await chestBox.put(currentChestNumber, newChestData);

    try {
      final acc = getKeypair(wallet.address);
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

    return await importAccount(password: password);
  }

  Future<bool> isMnemonicValid(String mnemonic) async {
    // Needed for bad encoding of UTF-8
    mnemonic = mnemonic.replaceAll('é', 'é');
    mnemonic = mnemonic.replaceAll('è', 'è');

    return await sdk.api.keyring.checkMnemonicValid(mnemonic);
  }

  Future<String> csToV2Address(String salt, String password) async {
    final scrypt = pc.KeyDerivator('scrypt');

    scrypt.init(
      pc.ScryptParameters(
        4096,
        16,
        1,
        32,
        Uint8List.fromList(salt.codeUnits),
      ),
    );
    final rawSeed = scrypt.process(Uint8List.fromList(password.codeUnits));
    final rawSeedHex = '0x${HEX.encode(rawSeed)}';

    // Just get the address without keystore
    final newAddress = await sdk.api.keyring.addressFromRawSeed(
        currencyParameters['ss58']!,
        cryptoType: CryptoType.ed25519,
        rawSeed: rawSeedHex);

    SigningKey rootKey = SigningKey(seed: rawSeed);
    g1V1OldPubkey = Base58Encode(rootKey.publicKey);

    g1V1NewAddress = newAddress.address!;
    notifyListeners();
    return g1V1NewAddress;
  }

  Future<List> getBalanceAndIdtyStatus(
      String fromAddress, String toAddress) async {
    final fromBalance = fromAddress == ''
        ? {'transferableBalance': 0}
        : await getBalance(fromAddress);
    final fromIdtyStatus =
        fromAddress == '' ? 'noid' : await idtyStatus(fromAddress);
    final fromHasConsumer =
        fromAddress == '' ? false : await hasAccountConsumers(fromAddress);
    final toIdtyStatus = await idtyStatus(toAddress);
    final isSmithData = await isSmith(fromAddress);

    return [
      fromBalance,
      fromIdtyStatus,
      toIdtyStatus,
      fromHasConsumer,
      isSmithData
    ];
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

    final sender = await _setSender(fromAddress);

    final globalBalance = await getBalance(fromAddress);
    TxInfoData txInfo;
    List txOptions = [];
    String? rawParams;
    final bool isUdUnit = configBox.get('isUdUnit') ?? false;
    late String palette;
    late String call;
    late String tx2;

    if (amount == -1) {
      palette = 'balances';
      call = 'transferAll';
      txOptions = [destAddress, false];
      tx2 = 'api.tx.balances.transferAll("$destAddress", false)';
    } else {
      late int amountUnit;
      if (isUdUnit) {
        palette = 'universalDividend';
        call = 'transferUd';
        // amount is milliUds
        amountUnit = (amount * 1000).toInt();
      } else {
        palette = 'balances';
        call = 'transferKeepAlive';
        // amount is double at 2 decimals
        amountUnit = (amount * 100).toInt();
      }
      txOptions = [destAddress, amountUnit];
      tx2 = 'api.tx.$palette.$call("$destAddress", $amountUnit)';
    }

    if (globalBalance['unclaimedUds'] == 0) {
      txInfo = TxInfoData(palette, call, sender);
    } else {
      txInfo = TxInfoData(
        'utility',
        'batchAll',
        sender,
      );
      const tx1 = 'api.tx.universalDividend.claimUds()';
      rawParams = '[[$tx1, $tx2]]';
    }

    return await _executeCall(txInfo, txOptions, password, rawParams);
  }

  Future<String> certify(
      String fromAddress, String destAddress, String password) async {
    transactionStatus = '';

    final myIdtyStatus = await idtyStatus(fromAddress);
    final toIdtyStatus = await idtyStatus(destAddress);

    final fromIndex = await _getIdentityIndexOf(fromAddress);
    final toIndex = await _getIdentityIndexOf(destAddress);

    if (myIdtyStatus != 'Validated') {
      transactionStatus = 'notMember';
      notifyListeners();
      return 'notMember';
    }

    final sender = await _setSender(fromAddress);
    TxInfoData txInfo;
    List txOptions = [];
    String? rawParams;

    final toCerts = await getCertsCounter(destAddress);

    // log.d('debug: ${currencyParameters['minCertForMembership']}');

    if (toIdtyStatus == 'noid') {
      txInfo = TxInfoData(
        'identity',
        'createIdentity',
        sender,
      );
      txOptions = [destAddress];
    } else if (toIdtyStatus == 'Validated' ||
        toIdtyStatus == 'ConfirmedByOwner') {
      if (toCerts[0] >= currencyParameters['minCertForMembership']! - 1 &&
          toIdtyStatus != 'Validated') {
        log.i('Batch cert and membership validation');
        txInfo = TxInfoData(
          'utility',
          'batchAll',
          sender,
        );
        final tx1 = 'api.tx.cert.addCert($fromIndex, $toIndex)';
        final tx2 = 'api.tx.identity.validateIdentity($toIndex)';

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
    return await _executeCall(txInfo, txOptions, password, rawParams);
  }

  Future<String> confirmIdentity(
      String fromAddress, String name, String password) async {
    final sender = await _setSender(fromAddress);

    final txInfo = TxInfoData(
      'identity',
      'confirmIdentity',
      sender,
    );
    final txOptions = [name];

    return await _executeCall(txInfo, txOptions, password);
  }

  Future<String> migrateIdentity(
      {required String fromAddress,
      required String destAddress,
      required String fromPassword,
      required String destPassword,
      required Map fromBalance,
      bool withBalance = false}) async {
    transactionStatus = '';
    final sender = await _setSender(fromAddress);

    TxInfoData txInfo;
    List txOptions = [];
    String? rawParams;

    final prefix = 'icok'.codeUnits;
    final genesisHashString = await getGenesisHash();
    final genesisHash = HEX.decode(genesisHashString.substring(2)) as Uint8List;
    final idtyIndex = _int32bytes(await _getIdentityIndexOf(fromAddress));
    final oldPubkey = await addressToPubkey(fromAddress);
    final messageToSign =
        Uint8List.fromList(prefix + genesisHash + idtyIndex + oldPubkey);
    final messageToSignHex = HEX.encode(messageToSign);
    final newKeySig =
        await _signMessage(messageToSign, destAddress, destPassword);

    // messageToSign: [105, 99, 111, 107, 7, 193, 18, 255, 106, 185, 215, 208, 213, 49, 235, 229, 159, 152, 179, 83, 24, 178, 129, 59, 22, 85, 87, 115, 128, 129, 157, 56, 214, 24, 45, 153, 21, 0, 0, 0, 181, 82, 178, 99, 198, 4, 156, 190, 78, 35, 102, 137, 255, 7, 162, 31, 16, 79, 255, 132, 130, 237, 230, 222, 176, 88, 245, 217, 237, 78, 196, 239]

    log.d("""
fromAddress: $fromAddress
destAddress: $destAddress
genesisHashString: $genesisHashString

prefix: $prefix
genesisHash: $genesisHash
idtyIndex: $idtyIndex
oldPubkey: $oldPubkey

messageToSign: $messageToSign
messageToSignHex: $messageToSignHex
newKeySig: $newKeySig""");

    if (withBalance) {
      txInfo = TxInfoData(
        'utility',
        'batchAll',
        sender,
      );

      const tx1 = 'api.tx.universalDividend.claimUds()';
      final tx2 =
          'api.tx.identity.changeOwnerKey("$destAddress", "$newKeySig")';
      final tx3 = 'api.tx.balances.transferAll("$destAddress", false)';

      rawParams = fromBalance['unclaimedUds'] == 0
          ? '[[$tx2, $tx3]]'
          : '[[$tx1, $tx2, $tx3]]';
    } else {
      txInfo = TxInfoData(
        'identity',
        'changeOwnerKey',
        sender,
      );

      txOptions = [destAddress, newKeySig];
    }

    return await _executeCall(txInfo, txOptions, fromPassword, rawParams);
  }

  Future revokeIdentity(String address, String password) async {
    final idtyIndex = await _getIdentityIndexOf(address);
    final sender = await _setSender(address);

    final prefix = 'revo'.codeUnits;
    final genesisHashString = await getGenesisHash();
    final genesisHash = HEX.decode(genesisHashString.substring(2)) as Uint8List;
    final idtyIndexBytes = _int32bytes(idtyIndex);
    final messageToSign =
        Uint8List.fromList(prefix + genesisHash + idtyIndexBytes);
    final revocationSig =
        (await _signMessage(messageToSign, address, password)).substring(2);
    final revocationSigTyped = '0x01$revocationSig';

    final txInfo = TxInfoData(
      'identity',
      'revokeIdentity',
      sender,
    );

    final txOptions = [idtyIndex, address, revocationSigTyped];
    return await _executeCall(txInfo, txOptions, password);
  }

  Future migrateCsToV2(String salt, String password, String destAddress,
      {required destPassword,
      required Map balance,
      String idtyStatus = 'noid'}) async {
    final scrypt = pc.KeyDerivator('scrypt');

    scrypt.init(
      pc.ScryptParameters(
        4096,
        16,
        1,
        32,
        Uint8List.fromList(salt.codeUnits),
      ),
    );
    final rawSeed = scrypt.process(Uint8List.fromList(password.codeUnits));
    final rawSeedHex = '0x${HEX.encode(rawSeed)}';

    final json = await sdk.api.keyring.importAccount(keyring,
        keyType: KeyType.rawSeed,
        key: rawSeedHex,
        name: 'test',
        password: 'password',
        derivePath: '',
        cryptoType: CryptoType.ed25519);

    final keypair = await sdk.api.keyring.addAccount(
      keyring,
      keyType: KeyType.rawSeed,
      acc: json!,
      password: password,
    );

    log.d('g1migration idtyStatus: $idtyStatus');
    if (idtyStatus != 'noid') {
      await migrateIdentity(
          fromAddress: keypair.address!,
          destAddress: destAddress,
          fromPassword: 'password',
          destPassword: destPassword,
          withBalance: true,
          fromBalance: balance);
    } else if (balance['transferableBalance'] != 0) {
      await pay(
          fromAddress: keypair.address!,
          destAddress: destAddress,
          amount: -1,
          password: 'password');
    }

    await sdk.api.keyring.deleteAccount(keyring, keypair);
  }

  Future spawnBlock([int number = 1, int until = 0]) async {
    if (!kDebugMode) return;
    if (blocNumber < until) {
      number = until - blocNumber;
    }
    for (var i = 1; i <= number; i++) {
      await sdk.webView!
          .evalJavascript('api.rpc.engine.createBlock(true, true)');
    }
  }

  void reload() {
    notifyListeners();
  }
}

////////////////////////////////////////////
/////// 6: UI ELEMENTS (off class) /////////
////////////////////////////////////////////

void snackNode(BuildContext context, bool isConnected) {
  String message;
  if (!isConnected) {
    message = "noDuniterNodeAvailableTryLater".tr();
  } else {
    final sub = Provider.of<SubstrateSdk>(context, listen: false);

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

Uint8List _int32bytes(int value) =>
    Uint8List(4)..buffer.asInt32List()[0] = value;

double round(double number, [int decimal = 2]) {
  return double.parse((number.toStringAsFixed(decimal)));
}
