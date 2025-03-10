import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:gecko/generated/gdev/gdev.dart';
import 'package:gecko/generated/gdev/types/tuples.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/balance.dart';
import 'package:gecko/models/membership_status.dart';
import 'package:gecko/models/migrate_wallet_checks.dart';
import 'package:gecko/models/network_config.dart';
import 'package:gecko/models/transaction_content.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/home.dart';
import 'package:gecko/services/network_config.service.dart';
import 'package:gecko/widgets/certify/cert_state.dart';
import 'package:gecko/widgets/transaction_status.dart';
import 'package:polkadart/polkadart.dart' as polkadart;
import 'package:provider/provider.dart';
import 'package:gecko/generated/gdev/types/pallet_identity/types/idty_status.dart' as generated_idty_status;
import 'package:ss58/ss58.dart';

/// Service responsable de l'interaction avec la blockchain via Polkadart
class PolkadartService with ChangeNotifier {
  // État de la connexion
  bool isConnected = false;
  bool isConnecting = false;
  String? connectedEndpoint;
  int blocNumber = 0;

  // Instance de l'API Polkadart
  Gdev? _api;

  // Paramètres de la blockchain
  Map<String, int> currencyParameters = {};
  int currentUdIndex = 0;
  int udValue = 0;

  // Cache pour les statuts d'identité
  final Map<String, generated_idty_status.IdtyStatus?> _idtyStatusCache = {};

  // Cache pour les compteurs de certifications
  Map<String, List<int>> certsCounterCache = {};

  // Statut des transactions
  Map<String, TransactionContent> transactionStatus = {};

  // Mapping des statuts de transaction
  final Map<String, TransactionStatus> statusMap = {
    'Ready': TransactionStatus.propagation,
    'Broadcast': TransactionStatus.validating,
    'InBlock': TransactionStatus.validating,
    'Finalized': TransactionStatus.finalized
  };

  /// Teste la connexion à un nœud de manière approfondie
  /// Vérifie non seulement si le nœud répond, mais aussi s'il est fonctionnel
  Future<Map<String, dynamic>> testEndPointThorough(String node, {Duration timeout = const Duration(seconds: 10)}) async {
    try {
      final provider = polkadart.Provider.fromUri(Uri.parse(node));
      final api = Gdev(provider);

      // Récupérer plusieurs informations pour vérifier la validité du nœud
      final results = await Future.wait([
        api.query.system.number().timeout(timeout),
        api.rpc.system.chain().timeout(timeout),
        api.rpc.system.name().timeout(timeout),
        api.rpc.system.version().timeout(timeout),
      ]);

      final blockNumber = results[0] as int;
      final chain = results[1] as String;
      final name = results[2] as String;
      final version = results[3] as String;

      // Vérifier si le nœud est valide
      final isValid = blockNumber > 0 && chain.isNotEmpty && name.isNotEmpty && version.isNotEmpty;

      // Calculer un score de qualité pour le nœud
      // Plus le score est élevé, meilleur est le nœud
      int qualityScore = 0;

      // Un nœud avec un numéro de bloc élevé est probablement plus à jour
      qualityScore += blockNumber;

      // Bonus pour les nœuds qui répondent rapidement
      // Nous allons essayer de faire une deuxième requête pour mesurer la latence
      final startTime = DateTime.now();
      try {
        await api.query.system.number().timeout(const Duration(seconds: 2));
        final endTime = DateTime.now();
        final latency = endTime.difference(startTime).inMilliseconds;

        // Moins la latence est élevée, meilleur est le score
        // Nous inversons la latence pour que les nœuds rapides aient un meilleur score
        qualityScore += (1000 - latency).clamp(0, 1000);
      } catch (_) {
        // Si la requête échoue, nous pénalisons le nœud
        qualityScore -= 500;
      }

      return {
        'isValid': isValid,
        'blockNumber': blockNumber,
        'chain': chain,
        'name': name,
        'version': version,
        'qualityScore': qualityScore,
        'api': api,
      };
    } catch (e) {
      // log.w("Erreur lors du test approfondi du nœud $node: $e");
      return {'isValid': false};
    }
  }

  /// Récupère la liste des nœuds disponibles depuis la configuration réseau
  Future<List<String>> getAvailableNodes() async {
    try {
      final NetworkConfig config = await NetworkConfigService.getNetworkConfig();
      return config.rpc;
    } catch (e) {
      log.e("Erreur lors de la récupération des nœuds disponibles: $e");
      return configBox.get('endpoint') ?? [];
    }
  }

  /// Se connecte au meilleur nœud disponible en testant tous les nœuds en parallèle
  Future<bool> connectNode() async {
    final homeProvider = Provider.of<HomeProvider>(homeContext, listen: false);

    homeProvider.changeMessage("connectionPending".tr());

    isConnecting = true;
    notifyListeners();

    try {
      // Récupérer la liste des nœuds disponibles
      List<String> nodes = [];

      // Utiliser un nœud personnalisé s'il existe
      if (configBox.containsKey('customEndpoint')) {
        nodes.add(configBox.get('customEndpoint'));
      } else {
        nodes = await getAvailableNodes();
      }

      if (nodes.isEmpty) {
        isConnected = false;
        isConnecting = false;
        homeProvider.changeMessage("noDuniterEndointAvailable".tr());
        notifyListeners();
        return false;
      }

      // Créer un completer pour pouvoir retourner dès qu'un nœud valide est trouvé
      final completer = Completer<Map<String, dynamic>>();

      // Liste pour stocker les résultats des tests
      final List<Map<String, dynamic>> validNodes = [];

      // Compteur pour suivre le nombre de tests terminés
      int completedTests = 0;

      // Tester tous les nœuds en parallèle
      for (final node in nodes) {
        testEndPointThorough(node).then((result) {
          completedTests++;

          // Si le nœud est valide, l'ajouter à la liste des nœuds valides
          if (result['isValid'] == true) {
            result['node'] = node;
            validNodes.add(result);

            // Si c'est le premier nœud valide trouvé, compléter le completer
            if (!completer.isCompleted) {
              completer.complete(result);
            }
          }

          // Si tous les tests sont terminés et qu'aucun nœud valide n'a été trouvé
          if (completedTests == nodes.length && !completer.isCompleted) {
            completer.complete({'isValid': false});
          }
        }).catchError((e) {
          completedTests++;
          log.e("Erreur lors du test du nœud $node: $e");

          // Si tous les tests sont terminés et qu'aucun nœud valide n'a été trouvé
          if (completedTests == nodes.length && !completer.isCompleted) {
            completer.complete({'isValid': false});
          }
        });
      }

      // Attendre qu'un nœud valide soit trouvé ou que tous les tests soient terminés
      final result = await completer.future;

      // Si aucun nœud valide n'a été trouvé
      if (result['isValid'] != true) {
        isConnected = false;
        isConnecting = false;
        homeProvider.changeMessage("noDuniterEndointAvailable".tr());
        notifyListeners();
        return false;
      }

      // Trier les nœuds valides par score de qualité (du plus élevé au plus bas)
      validNodes.sort((a, b) => (b['qualityScore'] as int).compareTo(a['qualityScore'] as int));

      // Utiliser le nœud avec le meilleur score
      final bestNode = validNodes.first;
      final node = bestNode['node'] as String;

      // Initialiser la connexion avec le meilleur nœud
      _api = bestNode['api'] as Gdev;

      // Mettre à jour l'état
      connectedEndpoint = node;
      isConnected = true;

      // S'abonner aux mises à jour du numéro de bloc
      _subscribeToBlockNumber();

      // Initialiser les paramètres de la blockchain
      await _initCurrencyParameters();
      await _initUdValue();

      homeProvider.changeMessage("wellConnectedToNode".tr(args: [node.split('/')[2]]));

      isConnecting = false;
      notifyListeners();

      return true;
    } catch (e) {
      log.e("Erreur lors de la connexion: $e");
      isConnected = false;
      isConnecting = false;
      homeProvider.changeMessage("noDuniterEndointAvailable".tr());
      notifyListeners();

      return false;
    }
  }

  /// S'abonne aux mises à jour du numéro de bloc
  void _subscribeToBlockNumber() {
    if (_api == null) return;

    // Récupérer le numéro de bloc initial
    _api!.query.system.number.call().then((value) {
      blocNumber = value;
      notifyListeners();
    });

    // Pour l'instant, on utilise un Timer pour simuler une souscription
    Timer.periodic(const Duration(seconds: 6), (timer) async {
      if (_api == null || !isConnected) {
        timer.cancel();
        return;
      }

      try {
        final newBlockNumber = await _api!.query.system.number();
        if (newBlockNumber != blocNumber) {
          blocNumber = newBlockNumber;
          notifyListeners();
        }
      } catch (e) {
        log.e("Erreur lors de la récupération du numéro de bloc: $e");
      }
    });
  }

  /// Initialise les paramètres de la blockchain
  Future<void> _initCurrencyParameters() async {
    if (_api == null) return;

    try {
      // Récupérer les paramètres de la blockchain depuis le pallet parameters
      final params = await _api!.query.parameters.parametersStorage();

      currencyParameters = {
        'ss58': await _api!.query.system.number(),
        'minCertForMembership': params.smithWotMinCertForMembership,
        'existentialDeposit': 100, // Cette valeur n'est pas dans les paramètres, à vérifier
        'certPeriod': params.certPeriod,
        'certMaxByIssuer': params.certMaxByIssuer,
        'certValidityPeriod': params.certValidityPeriod,
        'membershipRenewalPeriod': params.membershipRenewalPeriod,
        'membershipPeriod': params.membershipPeriod,
      };

      log.i('Paramètres de la blockchain initialisés: $currencyParameters');
    } catch (e) {
      log.e('Erreur lors de l\'initialisation des paramètres de la blockchain: $e');
    }
  }

  /// Initialise la valeur du dividende universel
  Future<void> _initUdValue() async {
    if (_api == null) return;

    try {
      // Récupérer la valeur du UD et l'index depuis le pallet universal_dividend
      udValue = (await _api!.query.universalDividend.currentUd()).toInt();
      currentUdIndex = await _api!.query.universalDividend.currentUdIndex();

      log.i('Valeur du UD: $udValue, Index du UD: $currentUdIndex');
    } catch (e) {
      log.e('Erreur lors de l\'initialisation de la valeur du UD: $e');
    }
  }

  /// Récupère le statut d'identité d'une adresse
  Future<generated_idty_status.IdtyStatus?> idtyStatus(String address) async {
    if (_api == null || !isConnected) throw Exception('Not connected');

    try {
      // Vérifier si le statut est en cache
      if (_idtyStatusCache.containsKey(address)) {
        return _idtyStatusCache[address]!;
      }

      final account = Address.decode(address);

      // Récupérer l'index de l'identité
      final idtyIndex = await _api!.query.identity.identityIndexOf(account.pubkey);

      if (idtyIndex == null) return null;

      // Récupérer les données de l'identité et du membership
      final idtyData = await _api!.query.identity.identities(idtyIndex);
      final membershipData = await _api!.query.membership.membership(idtyIndex);

      // Déterminer le statut en fonction des réponses
      generated_idty_status.IdtyStatus? status;
      if (idtyData == null) {
        status = null;
      } else if (membershipData != null) {
        status = generated_idty_status.IdtyStatus.member;
      } else {
        status = idtyData.status;
      }

      // Mettre en cache le statut
      _idtyStatusCache[address] = status;
      return status;
    } catch (e) {
      log.e('Erreur lors de la récupération du statut d\'identité: $e');
      rethrow;
    }
  }

  /// Récupère le statut d'identité de plusieurs adresses
  Future<List<IdtyStatus>> idtyStatusMulti(List<String> addresses) async {
    if (_api == null || !isConnected) {
      return List.filled(addresses.length, IdtyStatus.unknown);
    }

    try {
      // TODO: Implémenter avec les vraies méthodes quand l'API sera disponible
      return List.filled(addresses.length, IdtyStatus.unknown);
    } catch (e) {
      log.e('Erreur lors de la récupération des statuts d\'identité: $e');
      return List.filled(addresses.length, IdtyStatus.unknown);
    }
  }

  /// Récupère le solde d'une adresse
  Future<BalanceData> getBalance(String address) async {
    if (_api == null || !isConnected) {
      return BalanceData(
        transferableBalance: BigInt.zero,
        free: BigInt.zero,
        reserved: BigInt.zero,
        unclaimedUds: BigInt.zero,
      );
    }

    try {
      final account = Address.decode(address);

      // Récupérer les données du compte
      final accountData = await _api!.query.system.account(account.pubkey).timeout(const Duration(seconds: 7));

      // Récupérer les verrous
      final locks = await _api!.query.balances.locks(account.pubkey);

      // Calculer le montant verrouillé
      final lockedAmount = locks.fold<BigInt>(
        BigInt.zero,
        (sum, lock) => sum + lock.amount,
      );

      // Récupérer les UDs non réclamés
      final unclaimedUds = await getUnclaimedUds(address);

      return BalanceData(
        transferableBalance: accountData.data.free - lockedAmount + unclaimedUds,
        free: accountData.data.free,
        reserved: accountData.data.reserved,
        unclaimedUds: unclaimedUds,
      );
    } catch (e) {
      log.e('Erreur lors de la récupération du solde: $e');
      return BalanceData(
        transferableBalance: BigInt.zero,
        free: BigInt.zero,
        reserved: BigInt.zero,
        unclaimedUds: BigInt.zero,
      );
    }
  }

  Future<BigInt> getUnclaimedUds(String address) async {
    final account = Address.decode(address);
    final pastReevals = await _api!.query.universalDividend.pastReevals();
    final idtyIndex = await _api!.query.identity.identityIndexOf(account.pubkey);
    if (idtyIndex == null) return BigInt.zero;

    final idtyData = await _api!.query.identity.identities(idtyIndex);
    if (idtyData == null) return BigInt.zero;

    return _computeUnclaimUds(firstEligibleUd: idtyData.data.firstEligibleUd, pastReevals: pastReevals, idtyStatus: idtyData.status);
  }

  /// Calcule les UDs non réclamés
  BigInt _computeUnclaimUds({
    required int firstEligibleUd,
    required List<Tuple2<int, BigInt>> pastReevals,
    required generated_idty_status.IdtyStatus idtyStatus,
  }) {
    BigInt totalAmount = BigInt.zero;
    int tempCurrentUdIndex = currentUdIndex;

    if (firstEligibleUd == 0 || idtyStatus != generated_idty_status.IdtyStatus.member) return BigInt.zero;

    for (final Tuple2<int, BigInt> reval in pastReevals.reversed) {
      final int udIndex = reval.value0;
      final BigInt udValue = reval.value1;

      // Parcourir chaque réévaluation des UDs et additionner le solde non réclamé
      if (udIndex <= firstEligibleUd) {
        final count = tempCurrentUdIndex - firstEligibleUd;
        totalAmount += udValue * BigInt.from(count);
        break;
      } else {
        final count = tempCurrentUdIndex - udIndex;
        totalAmount += udValue * BigInt.from(count);
        tempCurrentUdIndex = udIndex;
      }
    }

    return totalAmount;
  }

  /// Récupère le nombre de certifications reçues et émises pour une adresse
  Future<List<int>> getCertsCounter(String address) async {
    if (_api == null || !isConnected) {
      return [0, 0];
    }

    try {
      // Vérifier si le compteur est en cache
      if (certsCounterCache.containsKey(address)) {
        return certsCounterCache[address]!;
      }

      final account = Address.decode(address);

      // Récupérer l'index de l'identité
      final idtyIndex = await _api!.query.identity.identityIndexOf(account.pubkey);

      if (idtyIndex == null) {
        certsCounterCache[address] = [0, 0];
        return [0, 0];
      }

      // Récupérer les métadonnées de certification
      final certMeta = await _api!.query.certification.storageIdtyCertMeta(idtyIndex);

      // Mettre en cache et retourner le résultat
      final result = [certMeta.receivedCount, certMeta.issuedCount];
      certsCounterCache[address] = result;
      return result;
    } catch (e) {
      log.e('Erreur lors de la récupération du nombre de certifications: $e');
      return [0, 0];
    }
  }

  /// Vérifie si un compte a des consommateurs
  Future<bool> hasAccountConsumers(String address) async {
    if (_api == null || !isConnected) return false;

    try {
      // TODO: Implémenter avec les vraies méthodes quand l'API sera disponible
      return false;
    } catch (e) {
      log.e('Erreur lors de la vérification des consommateurs du compte: $e');
      return false;
    }
  }

  /// Récupère l'état de certification entre deux adresses
  Future<CertState> certState(String from, String to) async {
    if (_api == null || !isConnected) {
      return CertState(status: CertStatus.none);
    }

    try {
      // Convertir les adresses en AccountId32 (liste de bytes)
      final fromAccountId = List<int>.from(from.codeUnits);
      final toAccountId = List<int>.from(to.codeUnits);

      // Récupérer les index des identités
      final fromIdtyIndex = await _api!.query.identity.identityIndexOf(fromAccountId);
      final toIdtyIndex = await _api!.query.identity.identityIndexOf(toAccountId);

      if (fromIdtyIndex == null || toIdtyIndex == null) {
        return CertState(status: CertStatus.mustConfirmIdentity);
      }

      // Récupérer les métadonnées de certification de l'émetteur
      final fromCertMeta = await _api!.query.certification.storageIdtyCertMeta(fromIdtyIndex);

      // Vérifier si l'émetteur a assez de certifications reçues pour certifier
      if (fromCertMeta.receivedCount < 3) {
        // minReceivedCertToBeAbleToIssueCert
        return CertState(status: CertStatus.none);
      }

      // Vérifier si l'émetteur n'a pas dépassé le nombre maximum de certifications émises
      if (fromCertMeta.issuedCount >= 100) {
        // maxByIssuer
        return CertState(status: CertStatus.none);
      }

      // Récupérer le numéro de bloc actuel
      final currentBlock = await _api!.query.system.number();

      // Vérifier si l'émetteur doit attendre avant de pouvoir certifier à nouveau
      if (fromCertMeta.nextIssuableOn > currentBlock) {
        final waitBlocks = fromCertMeta.nextIssuableOn - currentBlock;
        return CertState(
          status: CertStatus.mustWaitBeforeCert,
          duration: Duration(seconds: waitBlocks * 6),
        );
      }

      // Récupérer les certifications reçues par le destinataire
      final certsByReceiver = await _api!.query.certification.certsByReceiver(toIdtyIndex);

      // Vérifier si une certification existe déjà entre l'émetteur et le destinataire
      final existingCert = certsByReceiver.where((cert) => cert.value0 == fromIdtyIndex).firstOrNull;

      if (existingCert != null) {
        // Calculer le temps restant avant de pouvoir renouveler
        final validityPeriod = currencyParameters['certValidityPeriod'] ?? 2102400;
        final renewalBlock = existingCert.value1 + validityPeriod;

        if (currentBlock < renewalBlock) {
          final waitBlocks = renewalBlock - currentBlock;
          return CertState(
            status: CertStatus.canRenewIn,
            duration: Duration(seconds: waitBlocks * 6),
          );
        }
      }

      // Si toutes les conditions sont remplies, on peut certifier
      return CertState(status: CertStatus.canCert);
    } catch (e) {
      log.e('Erreur lors de la récupération de l\'état de certification: $e');
      return CertState(status: CertStatus.none);
    }
  }

  /// Récupère les vérifications pour la migration de portefeuille
  Future<MigrateWalletChecks> getBalanceAndIdtyStatus(String fromAddress, String toAddress) async {
    if (_api == null || !isConnected) {
      return const MigrateWalletChecks.defaultValues();
    }

    try {
      // TODO: Implémenter avec les vraies méthodes quand l'API sera disponible
      return const MigrateWalletChecks.defaultValues();
    } catch (e) {
      log.e('Erreur lors de la récupération des vérifications pour la migration de portefeuille: $e');
      return const MigrateWalletChecks.defaultValues();
    }
  }

  /// Vérifie si une adresse est un smith
  Future<bool> isSmith(String address) async {
    if (_api == null || !isConnected || address.isEmpty) return false;

    try {
      // TODO: Implémenter avec les vraies méthodes quand l'API sera disponible
      return false;
    } catch (e) {
      log.e('Erreur lors de la vérification si l\'adresse est un smith: $e');
      return false;
    }
  }

  /// Récupère la période de validité d'une certification
  Future<int> getCertValidityPeriod(String from, String to) async {
    if (_api == null || !isConnected) return 0;

    try {
      // Utiliser directement la valeur des paramètres de la blockchain
      return currencyParameters['certValidityPeriod'] ?? 0;
    } catch (e) {
      log.e('Erreur lors de la récupération de la période de validité de la certification: $e');
      return 0;
    }
  }

  /// Récupère les métadonnées de certification
  Future<Map> getCertMeta(String address) async {
    if (_api == null || !isConnected) return {};

    try {
      // Convertir l'adresse en AccountId32 (liste de bytes)
      final account = Address.decode(address);

      // Récupérer l'index de l'identité
      final idtyIndex = await _api!.query.identity.identityIndexOf(account.pubkey);

      if (idtyIndex == null) {
        return {};
      }

      // Récupérer les métadonnées de certification
      final certMeta = await _api!.query.certification.storageIdtyCertMeta(idtyIndex);

      return {
        'receivedCount': certMeta.receivedCount,
        'issuedCount': certMeta.issuedCount,
        'nextIssuableOn': certMeta.nextIssuableOn,
      };
    } catch (e) {
      log.e('Erreur lors de la récupération des métadonnées de certification: $e');
      return {};
    }
  }

  /// Récupère le statut de membre d'une adresse
  Future<MembershipStatus> getMembershipStatus(String address) async {
    if (_api == null || !isConnected) {
      return MembershipStatus.empty();
    }

    try {
      // Convertir l'adresse en AccountId32 (liste de bytes)
      final account = Address.decode(address);

      // Récupérer l'index de l'identité
      final idtyIndex = await _api!.query.identity.identityIndexOf(account.pubkey);

      if (idtyIndex == null) {
        return MembershipStatus.empty();
      }

      // Récupérer les données du membership
      final membershipData = await _api!.query.membership.membership(idtyIndex);

      if (membershipData == null) {
        return MembershipStatus.empty();
      }

      // Récupérer le numéro de bloc actuel
      final currentBlock = await _api!.query.system.number();

      // Calculer la date d'expiration
      final expireDate = DateTime.now().add(
        Duration(seconds: (membershipData.expireOn - currentBlock) * 6),
      );

      // Récupérer le statut d'identité
      final status = await idtyStatus(address);

      return MembershipStatus(
        expireDate: expireDate,
        hasPendingRenewal: false, // TODO: Implémenter quand l'API sera disponible
        renewalStartDate: null, // TODO: Implémenter quand l'API sera disponible
        idtyStatus: status,
      );
    } catch (e) {
      log.e('Erreur lors de la récupération du statut de membre: $e');
      return MembershipStatus.empty();
    }
  }

  /// Convertit un numéro de bloc en date
  DateTime blocNumberToDate(int blockNumber) {
    return startBlockchainTime.add(Duration(seconds: blockNumber * 6));
  }

  /// Convertit des bytes en entier 32 bits
  Uint8List int32bytes(int value) => Uint8List(4)..buffer.asInt32List()[0] = value;
}
