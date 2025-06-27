// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:durt2/durt2.dart' show IdtyStatus, CertificationData, Durt, MembershipData;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gecko/exceptions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/membership_status.dart';
import 'package:gecko/models/transaction_content.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/transaction_status.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/webviewWithExtension/types/signExtrinsicParam.dart';
import 'package:provider/provider.dart';
import 'package:pointycastle/pointycastle.dart' as pc;
import "package:hex/hex.dart";
import 'package:uuid/uuid.dart' show Uuid;

@Deprecated('Use Durt 2 instead')
class SubstrateSdk with ChangeNotifier {
  final WalletSDK sdk = WalletSDK();
  final Keyring keyring = Keyring();
  String generatedMnemonic = '';
  bool sdkReady = false;
  bool sdkLoading = false;
  // bool Durt.i.isConnected = false;
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

    final globalBalance = await Durt.i.storage.getBalance(fromAddress);
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
    final unclaimedUds = globalBalance.unclaimedUds;
    if (comment.isNotEmpty || unclaimedUds > BigInt.zero) {
      txInfo = TxInfoData('utility', 'batchAll', sender);

      List<String> txs = [];
      if (unclaimedUds > BigInt.zero) {
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
    final statusList = await Durt.i.storage.getIdtyStatusMulti([fromAddress, destAddress]);
    final myIdtyStatus = statusList[0];
    final toIdtyStatus = statusList[1];

    final toIndex = await Durt.i.storage.getIdentityIndexOf(destAddress);

    if (myIdtyStatus != IdtyStatus.validated) {
      throw NotMemberException();
    }

    final sender = await _setSender(fromAddress);
    TxInfoData txInfo;
    List txOptions = [];
    String? rawParams;

    var toCerts = await Durt.i.storage.getCertsCounter(destAddress);
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
    } else if (toIdtyStatus == IdtyStatus.validated || toIdtyStatus == IdtyStatus.confirmed) {
      if (toCerts.receivedCount >= currencyParameters['minCertForMembership']! - 1 && toIdtyStatus != IdtyStatus.validated) {
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
      throw CantBeCertException(toIdtyStatus.name);
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
      required Map<String, dynamic> fromBalance,
      bool withBalance = false}) async {
    final sender = await _setSender(fromAddress);

    TxInfoData txInfo;
    List txOptions = [];
    String? rawParams;

    final prefix = 'icok'.codeUnits;
    final genesisHashString = await Durt.i.storage.getBlockHash(0);
    final genesisHash = HEX.decode(genesisHashString.substring(2)) as Uint8List;
    final idtyIndex = int32bytes((await Durt.i.storage.getIdentityIndexOf(fromAddress))!);
    final oldPubkey = await Durt.i.utils.addressToPubkey(fromAddress);
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

  Future<String> revokeIdentity(String address, String password) async {
    final idtyIndex = await Durt.i.storage.getIdentityIndexOf(address);
    final sender = await _setSender(address);

    final prefix = 'revo'.codeUnits;
    final genesisHashString = await Durt.i.storage.getBlockHash(0);
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
    required Map<String, dynamic> fromBalance,
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
    final idtyIndex = await Durt.i.storage.getIdentityIndexOf(address);
    if (idtyIndex == null) return MembershipStatus.empty();

    final idtyStatus = await Durt.i.storage.getIdtyStatus(address);

    // Vérifier si une évaluation est en cours
    final hasPendingRenewal = await Durt.instance.gdev.query.distance.pendingEvaluationRequest(idtyIndex) != null;

    final MembershipData? membershipData = await Durt.instance.gdev.query.membership.membership(idtyIndex);

    if (membershipData == null && idtyStatus == IdtyStatus.confirmed) {
      return MembershipStatus(
        expireDate: null,
        hasPendingRenewal: hasPendingRenewal,
        renewalStartDate: null,
        idtyStatus: idtyStatus,
      );
    }

    final expireOn = membershipData!.expireOn;

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
