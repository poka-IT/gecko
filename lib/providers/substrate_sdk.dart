// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:fast_base58/fast_base58.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/certification_data.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/models/membership_status.dart';
import 'package:gecko/models/migrate_wallet_checks.dart';
import 'package:gecko/models/transaction_content.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/home.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/certify/cert_state.dart';
import 'package:gecko/widgets/transaction_status.dart';
import 'package:pinenacl/ed25519.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/webviewWithExtension/types/signExtrinsicParam.dart';
import 'package:provider/provider.dart';
import 'package:pointycastle/pointycastle.dart' as pc;
import "package:hex/hex.dart";
import 'package:uuid/uuid.dart' show Uuid;

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
  Map<String, TransactionContent> transactionStatus = {};
  final int initSs58 = 42;
  Map<String, int> currencyParameters = {};
  final csSalt = TextEditingController();
  final csPassword = TextEditingController();
  String g1V1NewAddress = '';
  String g1V1OldPubkey = '';
  bool isCesiumIDVisible = false;
  bool isCesiumAddresLoading = false;
  final Map<String, CertificationData> certsCounterCache = {};
  Map<String, List> oldOwnerKeys = {};

  // Cache pour idtyStatus
  final Map<String, IdtyStatus> _idtyStatusCache = {};

  // Getter public pour accéder au statut en cache
  IdtyStatus? getCachedIdtyStatus(String address) {
    return _idtyStatusCache[address];
  }

  /////////////////////////////////////
  ////////// 1: API METHODS ///////////
  /////////////////////////////////////

  Map<String, TransactionStatus> statusMap = {
    'sending': TransactionStatus.sending,
    'Ready': TransactionStatus.propagation,
    'Broadcast': TransactionStatus.validating,
    'Finalized': TransactionStatus.finalized
  };

  Future _executeCall(TransactionContent transcationContent, TxInfoData txInfo, txOptions, String password, [String? rawParams]) async {
    final walletOptions = Provider.of<WalletOptionsProvider>(homeContext, listen: false);
    final walletProfiles = Provider.of<WalletsProfilesProvider>(homeContext, listen: false);
    final currentTransactionId = transcationContent.transactionId;
    transactionStatus.putIfAbsent(currentTransactionId, () => transcationContent);
    notifyListeners();

    try {
      final hash = await sdk.api.tx.signAndSend(txInfo, txOptions, password, rawParam: rawParams, onStatusChange: (newStatus) {
        transactionStatus.update(currentTransactionId, (trans) {
          trans.status = statusMap[newStatus]!;
          return trans;
        }, ifAbsent: () {
          transcationContent.status = statusMap[newStatus]!;
          return transcationContent;
        });
        notifyListeners();
      }).timeout(
        const Duration(seconds: 18),
        onTimeout: () => {},
      );
      log.d(hash);
      if (hash.isEmpty) {
        transactionStatus.update(
          currentTransactionId,
          (trans) {
            trans.status = TransactionStatus.timeout;
            return trans;
          },
          ifAbsent: () {
            transcationContent.status = TransactionStatus.timeout;
            return transcationContent;
          },
        );
        notifyListeners();
      } else {
        // Success !
        transactionStatus.update(currentTransactionId, (trans) {
          trans.status = TransactionStatus.success;
          return trans;
        }, ifAbsent: () {
          transcationContent.status = TransactionStatus.success;
          return transcationContent;
        });
        notifyListeners();
        walletOptions.reload();
        walletProfiles.reload();
      }
    } catch (e) {
      transactionStatus.update(
        currentTransactionId,
        (trans) {
          trans.status = TransactionStatus.failed;
          trans.error = e.toString();
          return trans;
        },
        ifAbsent: () {
          transcationContent.status = TransactionStatus.failed;
          transcationContent.error = e.toString();
          return transcationContent;
        },
      );
      notifyListeners();
    }
    // transactionStatus.remove(currentTransactionId);
  }

  Future _getStorage(String call) async {
    try {
      // log.d(call);
      return await sdk.webView!.evalJavascript('api.query.$call');
    } catch (e) {
      log.e("_getStorage error: $e");
      throw Exception("_getStorage error: $e");
    }
  }

  Future<List<int>> _getStorageConst(List<String> calls) async {
    final result = await sdk.webView!.evalJavascript(
      'Object.values(Object.fromEntries([${calls.map((call) => '["$call", api.consts.$call[0]]').join(',')}]))',
      wrapPromise: false,
    );

    return (result as List).map((dynamic value) => checkInt(value) ?? 0).toList();
  }

  int? checkInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<TxSenderData> _setSender(String address) async {
    final fromPubkey = await sdk.api.account.decodeAddress([address]);
    return TxSenderData(
      address,
      fromPubkey!.keys.first,
    );
  }

  Future<String> _signMessage(Uint8List message, String address, String password) async {
    final params = SignAsExtensionParam();
    params.msgType = "pub(bytes.sign)";
    params.request = {
      "address": address,
      "data": message,
    };

    final res = await sdk.api.keyring.signAsExtension(password, params);
    return res?.signature ?? '';
  }

  Future<String> signDatapod(String document, String address) async {
    final myWalletProvider = Provider.of<MyWalletsProvider>(homeContext, listen: false);
    final messageToSign = Uint8List.fromList(document.codeUnits);

    final signatureString = await _signMessage(messageToSign, address, myWalletProvider.pinCode);
    final signatureInt = HEX.decode(signatureString.substring(2));
    final signature64 = base64Encode(signatureInt);

    return signature64;
  }

  ////////////////////////////////////////////
  ////////// 2: GET ONCHAIN STORAGE //////////
  ////////////////////////////////////////////

  Future<int?> _getIdentityIndexOf(String address) async {
    return await _getStorage('identity.identityIndexOf("$address")');
  }

  Future<List<int?>> _getIdentityIndexOfMulti(List<String> addresses) async {
    String jsonString = jsonEncode(addresses);
    return List<int?>.from(await _getStorage('identity.identityIndexOf.multi($jsonString)'));
  }

  Future<CertificationData> getCertsCounter(String address) async {
    // On fait toujours la requête en background
    final idtyIndex = await _getIdentityIndexOf(address);
    if (idtyIndex == null) {
      final emptyList = CertificationData(receivedCount: 0, sentCount: 0);
      // Si le compteur a changé (était non vide avant), on notifie
      if (certsCounterCache[address]?.receivedCount != 0 || certsCounterCache[address]?.sentCount != 0) {
        certsCounterCache[address] = emptyList;
        notifyListeners();
      }
      return emptyList;
    }

    final certsReceiver = await _getStorage('certification.storageIdtyCertMeta($idtyIndex)') ?? [];
    final List<int> newCerts = [certsReceiver['receivedCount'] as int, certsReceiver['issuedCount'] as int];

    // Si le compteur a changé, on met à jour le cache et on notifie
    if (certsCounterCache[address]?.receivedCount != newCerts[0] || certsCounterCache[address]?.sentCount != newCerts[1]) {
      certsCounterCache[address] = CertificationData(receivedCount: newCerts[0], sentCount: newCerts[1]);
      notifyListeners();
    }

    return certsCounterCache[address]!;
  }

  Future<DateTime?> membershipExpireIn(String address) async {
    final idtyIndex = await _getIdentityIndexOf(address);
    if (idtyIndex == null) return null;

    final expireOnMap = await _getStorage('membership.membership($idtyIndex)') ?? {};
    final expireOn = expireOnMap['expireOn'] as int;

    // Calculate time difference from current block (6 seconds per block)
    final blockDifference = expireOn - blocNumber;

    // Returns expiration date by adding (or subtracting if expired) time from now
    return DateTime.now().add(Duration(seconds: blockDifference * 6));
  }

  Future<int> getCertValidityPeriod(String from, String to) async {
    final idtyIndexFrom = await _getIdentityIndexOf(from);
    final idtyIndexTo = await _getIdentityIndexOf(to);

    if (idtyIndexFrom == null || idtyIndexTo == null) return 0;

    final List certData = await _getStorage('certification.certsByReceiver($idtyIndexTo)') ?? [];

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
    return !(consumers == 0);
  }

  Future<int> getUdValue() async => int.parse(await _getStorage('universalDividend.currentUd()'));

  Future<int> getBalanceRatio() async {
    udValue = await getUdValue();
    return balanceRatio = (configBox.get('isUdUnit') ?? false) ? udValue : 1;
  }

  Future<Map<String, Map<String, int>>> getBalanceMulti(List<String> addresses) async {
    List stringifyAddresses = [];
    for (var element in addresses) {
      stringifyAddresses.add('"$element"');
    }

    // Get onchain storage values
    final List<Map> accountMulti =
        (await _getStorage('system.account.multi($stringifyAddresses)') as List).map((dynamic e) => e as Map<String, dynamic>).toList();

    final List<int?> idtyIndexList = (await _getStorage('identity.identityIndexOf.multi($stringifyAddresses)') as List).map((dynamic e) => e as int?).toList();

    //FIXME: With local dev duniter node only, need to switch null values by unused init as index to have good idtyDataList...
    final List<int> idtyIndexListNoNull = idtyIndexList.map((item) => item ?? 99999999).toList();

    final List<Map?> idtyDataList = (idtyIndexListNoNull.isEmpty ? [] : (await _getStorage('identity.identities.multi($idtyIndexListNoNull)')) as List)
        .map((dynamic e) => e as Map<String, dynamic>?)
        .toList();

    int nbr = 0;
    Map<String, Map<String, int>> finalBalancesList = {};
    for (Map account in accountMulti) {
      final computedBalance = await _computeBalance(idtyDataList[nbr], account);
      finalBalancesList.putIfAbsent(addresses[nbr], () => computedBalance);
      nbr++;
    }

    return finalBalancesList;
  }

  Future<Map<String, int>> getBalance(String address) async {
    if (!nodeConnected) {
      return {
        'transferableBalance': 0,
        'free': 0,
        'unclaimedUds': 0,
        'reserved': 0,
      };
    }

    // Get onchain storage values
    final Map account = await _getStorage('system.account("$address")');
    final int? idtyIndex = await _getStorage('identity.identityIndexOf("$address")');
    final Map? idtyData = idtyIndex == null ? null : await _getStorage('identity.identities($idtyIndex)');

    return _computeBalance(idtyData, account);
  }

  Future<Map<String, int>> _computeBalance(Map? idtyData, Map account) async {
    final List pastReevals = await _getStorage('universalDividend.pastReevals()');
    // Compute amount of claimable UDs
    currentUdIndex = await getCurrentUdIndex();

    final idtyStatus = mapStatus[idtyData?['status']] ?? IdtyStatus.none;

    final int unclaimedUds = _computeUnclaimUds(
      firstEligibleUd: idtyData?['data']?['firstEligibleUd'] ?? 0,
      pastReevals: pastReevals,
      idtyStatus: idtyStatus,
    );

    // Calculate transferable and potential balance
    final int transferableBalance = (account['data']['free'] + unclaimedUds);

    return {
      'transferableBalance': transferableBalance,
      'free': account['data']['free'],
      'unclaimedUds': unclaimedUds,
      'reserved': account['data']['reserved'],
    };
  }

  int _computeUnclaimUds({
    required int firstEligibleUd,
    required List pastReevals,
    required IdtyStatus idtyStatus,
  }) {
    int totalAmount = 0;

    if (firstEligibleUd == 0 || idtyStatus != IdtyStatus.member) return 0;

    for (final List reval in pastReevals.reversed) {
      final int udIndex = reval[0];
      final int udValue = reval[1];

      // Loop each UDs revaluations and sum unclaimed balance
      if (udIndex <= firstEligibleUd) {
        final count = currentUdIndex - firstEligibleUd;
        totalAmount += count * udValue;
        break;
      } else {
        final count = currentUdIndex - udIndex;
        totalAmount += count * udValue;
        currentUdIndex = udIndex;
      }
    }

    return totalAmount;
  }

  Future<CertState> certState(String to) async {
    final toStatus = (await idtyStatusMulti([to])).first;
    final myWallets = Provider.of<MyWalletsProvider>(homeContext, listen: false);
    final walletOptions = Provider.of<WalletOptionsProvider>(homeContext, listen: false);
    final from = myWallets.idtyWallet?.address;

    if (from == null || from == to || !myWallets.getWalletDataByAddress(from)!.isMembre) {
      return CertState(status: CertStatus.none);
    }

    // Vérification du solde
    final balance = walletOptions.balanceCache[to] ?? 0;
    if (balance == 0) {
      return CertState(status: CertStatus.emptyWallet);
    }

    final removableOn = await getCertValidityPeriod(from, to);
    final certMeta = await getCertMeta(from);
    final int nextIssuableOn = certMeta['nextIssuableOn'] ?? 0;
    final certRemovableDuration = (removableOn - blocNumber) * 6;
    const int renewDelay = 2 * 30 * 24 * 3600; // 2 months

    if (certRemovableDuration >= renewDelay) {
      final certRenewDuration = certRemovableDuration - renewDelay;
      return CertState(status: CertStatus.canRenewIn, duration: Duration(seconds: certRenewDuration));
    } else if (nextIssuableOn > blocNumber) {
      final certDelayDuration = (nextIssuableOn - blocNumber) * 6;
      return CertState(status: CertStatus.mustWaitBeforeCert, duration: Duration(seconds: certDelayDuration));
    } else if (toStatus == IdtyStatus.unconfirmed) {
      return CertState(status: CertStatus.mustConfirmIdentity);
    } else {
      return CertState(status: CertStatus.canCert);
    }
  }

  Future<Map> getCertMeta(String address) async {
    var idtyIndex = await _getIdentityIndexOf(address);

    final certMeta = await _getStorage('certification.storageIdtyCertMeta($idtyIndex)') ?? '';

    return certMeta;
  }

  Future<List> getOldOwnerKey(String address) async {
    // final walletOptions =
    //     Provider.of<WalletOptionsProvider>(homeContext, listen: false);

    var idtyIndex = await _getIdentityIndexOf(address);
    if (idtyIndex == null) return [];

    final Map? idtyData = await _getStorage('identity.identities($idtyIndex)');
    if (idtyData == null || idtyData['oldOwnerKey'] == null) return [];

    List oldKeys = idtyData['oldOwnerKey'] ?? [];
    if (oldKeys.isEmpty) return [];

    oldKeys[1] = blocNumberToDate(oldKeys[1]);
    oldOwnerKeys.putIfAbsent(address, () => oldKeys);

    return oldKeys;
  }

  DateTime blocNumberToDate(int blocNumber) {
    return startBlockchainTime.add(Duration(seconds: blocNumber * 6));
  }

  final mapStatus = {
    null: IdtyStatus.none,
    'Unconfirmed': IdtyStatus.unconfirmed,
    'Unvalidated': IdtyStatus.unvalidated,
    'Member': IdtyStatus.member,
    'NotMember': IdtyStatus.notMember,
    'Revoked': IdtyStatus.revoked,
    'unknown': IdtyStatus.unknown,
  };

  Future<IdtyStatus> idtyStatus(String address) async {
    // On fait toujours la requête en background
    final status = await _idtyStatus(address);

    // Si le statut a changé, on met à jour le cache et on notifie
    if (_idtyStatusCache[address] != status) {
      _idtyStatusCache[address] = status;
      notifyListeners();
    }

    // On retourne le statut du cache s'il existe, sinon le nouveau statut
    return _idtyStatusCache[address] ?? status;
  }

  Future<IdtyStatus> _idtyStatus(String address) async {
    final idtyIndex = await _getIdentityIndexOf(address);
    if (idtyIndex == null) return IdtyStatus.none;
    final idtyStatus = await idtyStatusByIndex(idtyIndex);
    return idtyStatus;
  }

  Future<List<IdtyStatus>> idtyStatusMulti(List<String> addresses) async {
    final idtyIndexes = await _getIdentityIndexOfMulti(addresses);

    //FIXME: should not have to replace null values by 99999999
    final idtyIndexesFix = idtyIndexes.map((item) => item ?? 99999999).toList();
    final jsonString = jsonEncode(idtyIndexesFix);
    final List idtyStatusList = await _getStorage('identity.identities.multi($jsonString)');

    List<IdtyStatus> resultStatus = [];

    for (final idtyStatus in idtyStatusList) {
      if (idtyStatus == null) {
        resultStatus.add(IdtyStatus.none);
      } else {
        resultStatus.add(mapStatus[idtyStatus['status']] ?? IdtyStatus.unknown);
      }
    }
    return resultStatus;
  }

  Future<IdtyStatus> idtyStatusByIndex(int idtyIndex) async {
    final idtyStatus = await _getStorage('identity.identities($idtyIndex)');
    return mapStatus[idtyStatus['status']] ?? IdtyStatus.unknown;
  }

  Future<bool> isSmith(String address) async {
    var idtyIndex = await _getIdentityIndexOf(address);
    if (idtyIndex == -1) return false;

    final isSmith = await _getStorage('smithMembers.smiths($idtyIndex)');
    return !(isSmith == null);
  }

  Future<String> getGenesisHash() async {
    final String genesisHash = await sdk.webView!.evalJavascript(
          'api.genesisHash.toHex()',
          wrapPromise: false,
        ) ??
        [];
    return genesisHash;
  }

  Future<Uint8List> addressToPubkey(String address) async {
    final pubkey = await sdk.api.account.decodeAddress([address]);
    final String pubkeyHex = pubkey!.keys.first;
    final pubkeyByte = HEX.decode(pubkeyHex.substring(2)) as Uint8List;
    // final pubkey58 = Base58Encode(pubkeyByte);

    return pubkeyByte;
  }

  Future<String> addressToPubkeyB58(String address) async {
    return Base58Encode(await addressToPubkey(address));
  }

  Future<String> pubkeyV1ToAddress(String pubkey) async {
    pubkey = pubkey.split(':')[0];
    final pubkeyByte = Base58Decode(pubkey);
    final String pubkeyHex = '0x${HEX.encode(pubkeyByte)}';
    final address = await sdk.api.account.encodeAddress([pubkeyHex]);
    return address!.values.first;
  }

  Future initCurrencyParameters() async {
    const currencyParametersNames = {
      'ss58': 'system.ss58Prefix.words',
      'minCertForMembership': 'wot.minCertForMembership.words',
      'existentialDeposit': 'balances.existentialDeposit.words',
      'certPeriod': 'certification.certPeriod.words',
      'certMaxByIssuer': 'certification.maxByIssuer.words',
      'certValidityPeriod': 'certification.validityPeriod.words',
      'membershipRenewalPeriod': 'membership.membershipRenewalPeriod.words',
      'membershipPeriod': 'membership.membershipPeriod.words',
    };

    try {
      final values = await _getStorageConst(currencyParametersNames.values.toList());

      int i = 0;
      for (final param in currencyParametersNames.keys) {
        currencyParameters[param] = values[i];
        i++;
      }
    } catch (e) {
      log.e('error while getting currency parameters: $e');
    }
    log.i('currencyParameters: $currencyParameters');
  }

  void cesiumIDisVisible() {
    isCesiumIDVisible = !isCesiumIDVisible;
    notifyListeners();
  }

  Future<double> txFees(String fromAddress, String destAddress, double amount) async {
    if (amount == 0) return 0;
    final sender = await _setSender(fromAddress);
    final txInfo = TxInfoData('balances', 'transferKeepAlive', sender);
    final bigAmount = BigInt.from(amount * 100);
    if (bigAmount > BigInt.from(9007199254740991)) {
      throw Exception('Amount too large for JavaScript safe integer');
    }
    final amountUnit = bigAmount.toInt();

    final estimateFees = await sdk.api.tx.estimateFees(txInfo, [destAddress, amountUnit]);

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

    // log.d('Blockchain start: $dateText');
    return DateFormat();
  }

  Future<String> getLastFinilizedHash() async => await sdk.webView!.evalJavascript('api.rpc.chain.getFinalizedHead()');

  Future<int> getBlockNumberByHash(String hash) async {
    final result = await sdk.webView!.evalJavascript('api.rpc.chain.getBlock("$hash")');
    return result['block']['header']['number'] as int;
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
    if (!sdkReady) return null;
    return sdk.api.connectedNode?.endpoint;
  }

  Future<void> connectNode() async {
    final homeProvider = Provider.of<HomeProvider>(homeContext, listen: false);
    final myWalletProvider = Provider.of<MyWalletsProvider>(homeContext, listen: false);

    homeProvider.changeMessage("connectionPending".tr());

    // configBox.delete('customEndpoint');
    final List<NetworkParams> listEndpoints = configBox.containsKey('customEndpoint') ? [getDuniterCustomEndpoint()] : getDuniterBootstrap();

    int timeout = 15;

    if (sdk.api.connectedNode?.endpoint != null) {
      await sdk.api.setting.unsubscribeBestNumber();
    }

    isLoadingEndpoint = true;
    notifyListeners();
    final resNode = await sdk.api.connectNode(keyring, listEndpoints).timeout(
          Duration(seconds: timeout),
          onTimeout: () => null,
        );
    isLoadingEndpoint = false;
    notifyListeners();
    if (resNode != null) {
      nodeConnected = true;

      // Subscribe bloc number
      sdk.api.setting.subscribeBestNumber((res) {
        blocNumber = int.parse(res.toString());
        if (sdk.api.connectedNode?.endpoint == null) {
          nodeConnected = false;
          homeProvider.changeMessage("networkLost".tr());
        } else {
          nodeConnected = true;
        }
        notifyListeners();
      });
      currentUdIndex = await getCurrentUdIndex();
      await getBalanceRatio();

      // Currency parameters
      await initCurrencyParameters();

      notifyListeners();
      homeProvider.changeMessage("wellConnectedToNode".tr(args: [getConnectedEndpoint()!.split('/')[2]]));
    } else {
      nodeConnected = false;
      notifyListeners();
      homeProvider.changeMessage("noDuniterEndointAvailable".tr());
      if (!myWalletProvider.isWalletsExists()) snackNode(false);
    }

    log.i('Connected to node: ${sdk.api.connectedNode?.endpoint}');
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

  Future<int> getCurrentUdIndex() async {
    return int.parse(await _getStorage('universalDividend.currentUdIndex()'));
  }

  NetworkParams getDuniterCustomEndpoint() {
    final nodeParams = NetworkParams();
    nodeParams.name = currencyName;
    nodeParams.endpoint = configBox.get('customEndpoint');
    nodeParams.ss58 = currencyParameters['ss58'] ?? initSs58;
    return nodeParams;
  }

  Future<String> importAccount({String mnemonic = '', String derivePath = '', required String password, CryptoType cryptoType = CryptoType.sr25519}) async {
    const keytype = KeyType.mnemonic;
    if (mnemonic != '') generatedMnemonic = mnemonic;

    importIsLoading = true;
    notifyListeners();

    final json = await sdk.api.keyring
        .importAccount(keyring, keyType: keytype, key: generatedMnemonic, name: derivePath, password: password, derivePath: derivePath, cryptoType: cryptoType)
        .catchError((e) {
      importIsLoading = false;
      notifyListeners();
      return e;
    });
    if (json == null) return '';
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
    return keyring.keyPairs.firstWhere((kp) => kp.address == address, orElse: (() => KeyPairData()));
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
    if (seed == null || seed.seed == null) {
      seedText = '';
    } else {
      seedText = seed.seed!.split('//')[0];
    }

    return seedText;
  }

  Future<KeyPairData?> changePassword(BuildContext context, String address, String passOld, String passNew) async {
    final account = getKeypair(address);
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);
    keyring.setCurrent(account);
    myWalletProvider.debounceResetPinCode();

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
    final gen = await sdk.api.keyring.generateMnemonic(currencyParameters['ss58'] ?? initSs58);
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

  KeyPairData getCurrentKeyPair() {
    try {
      final acc = keyring.current;
      return acc;
    } catch (e) {
      return KeyPairData();
    }
  }

  Future<String> derive(BuildContext context, String address, int number, String password) async {
    final keypair = getKeypair(address);

    final seedMap = await keyring.store.getDecryptedSeed(keypair.pubKey, password);

    if (seedMap?['type'] != 'mnemonic') return '';
    final List seedList = seedMap!['seed'].split('//');
    generatedMnemonic = seedList[0];

    return await importAccount(mnemonic: generatedMnemonic, derivePath: '//$number', password: password);
  }

  Future<String> generateRootKeypair(String address, String password) async {
    final keypair = getKeypair(address);

    final seedMap = await keyring.store.getDecryptedSeed(keypair.pubKey, password);

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
    final newAddress = await sdk.api.keyring.addressFromRawSeed(currencyParameters['ss58']!, cryptoType: CryptoType.ed25519, rawSeed: rawSeedHex);

    SigningKey rootKey = SigningKey(seed: rawSeed);
    g1V1OldPubkey = Base58Encode(rootKey.publicKey);

    g1V1NewAddress = newAddress.address!;
    notifyListeners();
    return g1V1NewAddress;
  }

  Future<MigrateWalletChecks> getBalanceAndIdtyStatus(String fromAddress, String toAddress) async {
    bool canValidate = false;
    String validationStatus = '';

    final fromBalance = fromAddress == '' ? {'transferableBalance': 0} : await getBalance(fromAddress);

    final transferableBalance = fromBalance['transferableBalance'];

    final statusList = await idtyStatusMulti([fromAddress, toAddress]);
    final fromIdtyStatus = statusList[0];
    final fromHasConsumer = fromAddress == '' ? false : await hasAccountConsumers(fromAddress);
    final toIdtyStatus = statusList[1];
    final isSmithData = await isSmith(fromAddress);

    // Check conditions to set 'canValidate' and 'validationStatus'
    if (isSmithData) {
      validationStatus = 'smithCantMigrateIdentity'.tr();
    } else if (fromHasConsumer) {
      validationStatus = 'youMustWaitBeforeCashoutThisAccount'.tr();
    } else if (transferableBalance == 0) {
      validationStatus = 'thisAccountIsEmpty'.tr();
    } else if (toIdtyStatus != IdtyStatus.none && fromIdtyStatus != IdtyStatus.none) {
      validationStatus = 'youCannotMigrateIdentityToExistingIdentity'.tr();
    } else if (fromIdtyStatus == IdtyStatus.none || toIdtyStatus == IdtyStatus.none) {
      canValidate = true;
    }

    return MigrateWalletChecks(
      fromBalance: fromBalance,
      fromIdtyStatus: fromIdtyStatus,
      toIdtyStatus: toIdtyStatus,
      validationStatus: validationStatus,
      canValidate: canValidate,
    );
  }

  //////////////////////////////////////
  ///////// 5: CALLS EXECUTION /////////
  //////////////////////////////////////

  Future<void> pay({
    required String fromAddress,
    required String destAddress,
    required double amount,
    required String password,
    required String transactionId,
    required String comment,
  }) async {
    final walletOptions = Provider.of<WalletOptionsProvider>(homeContext, listen: false);
    final sender = await _setSender(fromAddress);

    final globalBalance = await getBalance(fromAddress);
    final defaultWalletBalance = walletOptions.balanceCache[fromAddress] ?? 0;
    TxInfoData txInfo;
    List txOptions = [];
    String? rawParams;
    final bool isUdUnit = configBox.get('isUdUnit') ?? false;
    late String palette;
    late String call;
    late String tx2;
    late String tx3;

    // Computed amount in absolute value
    final int amountUnit = (amount * (isUdUnit ? 1000 : 100)).toInt();

    // Préparer la transaction de transfert
    if (amount == -1 || amountUnit == defaultWalletBalance) {
      palette = 'balances';
      call = 'transferAll';
      txOptions = [destAddress, false];
      tx2 = 'api.tx.balances.transferAll("$destAddress", false)';
    } else {
      if (isUdUnit) {
        palette = 'universalDividend';
        call = 'transferUd';
      } else {
        palette = 'balances';
        call = 'transferKeepAlive';
      }
      txOptions = [destAddress, amountUnit];
      tx2 = 'api.tx.$palette.$call("$destAddress", $amountUnit)';
    }

    // Si on a un commentaire, on doit utiliser batchAll dans tous les cas
    final unclaimedUds = (globalBalance['unclaimedUds'] ?? 0) as num;
    if (comment.isNotEmpty || unclaimedUds > 0) {
      txInfo = TxInfoData('utility', 'batchAll', sender);

      List<String> txs = [];
      if (unclaimedUds > 0) {
        txs.add('api.tx.universalDividend.claimUds()');
      }
      txs.add(tx2);
      if (comment.isNotEmpty) {
        tx3 = 'api.tx.system.remarkWithEvent("$comment")';
        txs.add(tx3);
      }
      rawParams = '[[${txs.join(', ')}]]';
    } else {
      // Transaction simple sans batch
      txInfo = TxInfoData(palette, call, sender);
    }

    final transactionContent = TransactionContent(
      transactionId: transactionId,
      status: TransactionStatus.sending,
      from: fromAddress,
      to: destAddress,
      amount: amount,
    );
    log.d('txInfoo: ${txInfo.module}.${txInfo.call} -- $txOptions -- $rawParams');
    _executeCall(transactionContent, txInfo, txOptions, password, rawParams);
  }

  Future<String> certify(String fromAddress, String destAddress, String password) async {
    final statusList = await idtyStatusMulti([fromAddress, destAddress]);
    final myIdtyStatus = statusList[0];
    final toIdtyStatus = statusList[1];

    final toIndex = await _getIdentityIndexOf(destAddress);

    if (myIdtyStatus != IdtyStatus.member) {
      return 'notMember';
    }

    final sender = await _setSender(fromAddress);
    TxInfoData txInfo;
    List txOptions = [];
    String? rawParams;

    var toCerts = await getCertsCounter(destAddress);
    if (toCerts.receivedCount == 0 && toCerts.sentCount == 0) {
      toCerts = CertificationData(receivedCount: 0, sentCount: 0);
    }
    log.d("debug toCert: ${toCerts.receivedCount} --- ${currencyParameters['minCertForMembership']!} --- $toIdtyStatus");

    if (toIdtyStatus == IdtyStatus.none) {
      txInfo = TxInfoData(
        'identity',
        'createIdentity',
        sender,
      );
      txOptions = [destAddress];
    } else if (toIdtyStatus == IdtyStatus.member || toIdtyStatus == IdtyStatus.unvalidated) {
      if (toCerts.receivedCount >= currencyParameters['minCertForMembership']! - 1 && toIdtyStatus != IdtyStatus.member) {
        log.d('Batch cert and membership validation');
        txInfo = TxInfoData(
          'utility',
          'batchAll',
          sender,
        );
        final tx1 = 'api.tx.certification.addCert($toIndex)';
        final tx2 = 'api.tx.distance.requestDistanceEvaluationFor($toIndex)';

        rawParams = '[[$tx1, $tx2]]';
      } else {
        txInfo = TxInfoData(
          'certification',
          'addCert',
          sender,
        );
        txOptions = [toIndex];
      }
    } else {
      log.e('cantBeCert: $toIdtyStatus');
      return 'cantBeCert';
    }

    log.d('Cert action: ${txInfo.module!}.${txInfo.call!}');
    final transactionId = const Uuid().v4();
    final transactionContent = TransactionContent(
      transactionId: transactionId,
      status: TransactionStatus.sending,
      from: fromAddress,
      to: destAddress,
      amount: -1,
    );
    _executeCall(transactionContent, txInfo, txOptions, password, rawParams);
    return transactionId;
  }

  Future<String> confirmIdentity(String fromAddress, String name, String password) async {
    final sender = await _setSender(fromAddress);

    final txInfo = TxInfoData(
      'identity',
      'confirmIdentity',
      sender,
    );
    final txOptions = [name];

    final transactionId = const Uuid().v4();
    final transactionContent = TransactionContent(
      transactionId: transactionId,
      status: TransactionStatus.sending,
      from: fromAddress,
      to: fromAddress,
      amount: -1,
    );
    _executeCall(transactionContent, txInfo, txOptions, password);

    return transactionId;
  }

  Future<String> migrateIdentity(
      {required String fromAddress,
      required String destAddress,
      required String fromPassword,
      required String destPassword,
      required Map fromBalance,
      bool withBalance = false}) async {
    final sender = await _setSender(fromAddress);

    TxInfoData txInfo;
    List txOptions = [];
    String? rawParams;

    final prefix = 'icok'.codeUnits;
    final genesisHashString = await getGenesisHash();
    final genesisHash = HEX.decode(genesisHashString.substring(2)) as Uint8List;
    final idtyIndex = int32bytes((await _getIdentityIndexOf(fromAddress))!);
    final oldPubkey = await addressToPubkey(fromAddress);
    final messageToSign = Uint8List.fromList(prefix + genesisHash + idtyIndex + oldPubkey);
    final messageToSignHex = HEX.encode(messageToSign);
    final newKeySig = await _signMessage(messageToSign, destAddress, destPassword);
    final newKeySigType = '{"Sr25519": "$newKeySig"}';

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
newKeySig: $newKeySigType""");

    if (withBalance) {
      txInfo = TxInfoData(
        'utility',
        'batchAll',
        sender,
      );

      const tx1 = 'api.tx.universalDividend.claimUds()';
      final tx2 = 'api.tx.identity.changeOwnerKey("$destAddress", $newKeySigType)';
      final tx3 = 'api.tx.balances.transferAll("$destAddress", false)';

      rawParams = fromBalance['unclaimedUds'] == 0 ? '[[$tx2, $tx3]]' : '[[$tx1, $tx2, $tx3]]';
    } else {
      txInfo = TxInfoData(
        'identity',
        'changeOwnerKey',
        sender,
      );

      txOptions = [destAddress, newKeySigType];
    }

    final transactionId = const Uuid().v4();
    final transactionContent = TransactionContent(
      transactionId: transactionId,
      status: TransactionStatus.sending,
      from: fromAddress,
      to: fromAddress,
      amount: -1,
    );
    _executeCall(transactionContent, txInfo, txOptions, fromPassword, rawParams);
    return transactionId;
  }

  Future revokeIdentity(String address, String password) async {
    final idtyIndex = await _getIdentityIndexOf(address);
    final sender = await _setSender(address);

    final prefix = 'revo'.codeUnits;
    final genesisHashString = await getGenesisHash();
    final genesisHash = HEX.decode(genesisHashString.substring(2)) as Uint8List;
    final idtyIndexBytes = int32bytes(idtyIndex!);
    final messageToSign = Uint8List.fromList(prefix + genesisHash + idtyIndexBytes);
    final revocationSig = (await _signMessage(messageToSign, address, password)).substring(2);
    final revocationSigTyped = '0x01$revocationSig';

    final txInfo = TxInfoData(
      'identity',
      'revokeIdentity',
      sender,
    );

    final txOptions = [idtyIndex, address, revocationSigTyped];
    final transactionId = const Uuid().v4();
    final transactionContent = TransactionContent(
      transactionId: transactionId,
      status: TransactionStatus.sending,
      from: address,
      to: address,
      amount: -1,
    );
    _executeCall(transactionContent, txInfo, txOptions, password);
    return transactionId;
  }

  Future<String> migrateCsToV2(
    String salt,
    String password,
    String destAddress, {
    required destPassword,
    required Map fromBalance,
    IdtyStatus fromIdtyStatus = IdtyStatus.none,
    IdtyStatus toIdtyStatus = IdtyStatus.none,
  }) async {
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

    final json = await sdk.api.keyring.importAccount(
      keyring,
      keyType: KeyType.rawSeed,
      key: rawSeedHex,
      name: 'test',
      password: 'password',
      derivePath: '',
      cryptoType: CryptoType.ed25519,
    );

    final keypair = await sdk.api.keyring.addAccount(
      keyring,
      keyType: KeyType.rawSeed,
      acc: json!,
      password: password,
    );

    var transactionId = const Uuid().v4();

    if (fromIdtyStatus == IdtyStatus.none) {
      await pay(
        fromAddress: keypair.address!,
        destAddress: destAddress,
        amount: -1,
        password: 'password',
        transactionId: transactionId,
        comment: 'ĞECKO:CSMIGRATION',
      );
    } else if (fromBalance['transferableBalance'] != 0) {
      await migrateIdentity(
          fromAddress: keypair.address!,
          destAddress: destAddress,
          fromPassword: 'password',
          destPassword: destPassword,
          withBalance: true,
          fromBalance: fromBalance);
    } else {
      transactionId = '';
    }

    await sdk.api.keyring.deleteAccount(keyring, keypair);
    return transactionId;
  }

  Future spawnBlock([int number = 1, int until = 0]) async {
    if (!kDebugMode) return;
    if (blocNumber < until) {
      number = until - blocNumber;
    }
    for (var i = 1; i <= number; i++) {
      await sdk.webView!.evalJavascript('api.rpc.engine.createBlock(true, true)');
    }
  }

  void reload() {
    notifyListeners();
  }

  Future<String> renewMembership(String address, String password) async {
    final sender = await _setSender(address);

    final txInfo = TxInfoData(
      'distance',
      'requestDistanceEvaluation',
      sender,
    );

    final transactionId = const Uuid().v4();
    final transactionContent = TransactionContent(
      transactionId: transactionId,
      status: TransactionStatus.sending,
      from: address,
      to: address,
      amount: -1,
    );
    _executeCall(transactionContent, txInfo, [], password);
    return transactionId;
  }

  Future<MembershipStatus> getMembershipStatus(String address) async {
    final sub = Provider.of<SubstrateSdk>(homeContext, listen: false);
    final idtyIndex = await _getIdentityIndexOf(address);
    if (idtyIndex == null) return MembershipStatus.empty();

    final idtyStatus = await sub.idtyStatusByIndex(idtyIndex);

    // Vérifier si une évaluation est en cours
    final hasPendingRenewal = await _getStorage('distance.pendingEvaluationRequest($idtyIndex)') != null;

    final Map<String, dynamic> expireOnMap = await _getStorage('membership.membership($idtyIndex)') ?? {};

    if (expireOnMap.isEmpty && idtyStatus == IdtyStatus.notMember) {
      return MembershipStatus(
        expireDate: null,
        hasPendingRenewal: hasPendingRenewal,
        renewalStartDate: null,
        idtyStatus: idtyStatus,
      );
    }

    final expireOn = expireOnMap['expireOn'] as int;

    // Calculate time difference from current block (6 seconds per block)
    final blockDifference = expireOn - blocNumber;

    // Returns expiration date by adding (or subtracting if expired) time from now
    final expireDate = DateTime.now().add(Duration(seconds: blockDifference * 6));

    final membershipPeriod = currencyParameters['membershipPeriod']!;
    final membershipRenewalPeriod = currencyParameters['membershipRenewalPeriod']!;
    final renewalStartDate = expireDate.subtract(Duration(seconds: (membershipPeriod - membershipRenewalPeriod).round() * 6));

    return MembershipStatus(
      expireDate: expireDate,
      hasPendingRenewal: hasPendingRenewal,
      renewalStartDate: renewalStartDate,
      idtyStatus: idtyStatus,
    );
  }
}
