import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:gecko/generated/gdev/gdev.dart';
import 'package:gecko/globals.dart';
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

/// Service responsable de l'interaction avec la blockchain via Polkadart
class PolkadartService with ChangeNotifier {
  // État de la connexion
  bool isConnected = false;
  bool isConnecting = false;
  String? connectedEndpoint;
  int blocNumber = 0;

  // Instance de l'API Polkadart
  Gdev? _api;
  polkadart.Provider? _provider;

  // Paramètres de la blockchain
  Map<String, int> currencyParameters = {};
  int currentUdIndex = 0;
  int udValue = 0;

  // Cache pour les statuts d'identité
  final Map<String, IdtyStatus> _idtyStatusCache = {};

  // Cache pour les compteurs de certifications
  Map<String, List<int>> certsCounterCache = {};

  // Statut des transactions
  Map<String, TransactionContent> transactionStatus = {};

  // Mapping des statuts de transaction
  Map<String, TransactionStatus> statusMap = {
    'Ready': TransactionStatus.propagation,
    'Broadcast': TransactionStatus.validating,
    'InBlock': TransactionStatus.validating,
    'Finalized': TransactionStatus.finalized
  };

  // Mapping des statuts d'identité
  final mapStatus = {
    null: IdtyStatus.none,
    'Unconfirmed': IdtyStatus.unconfirmed,
    'Unvalidated': IdtyStatus.unvalidated,
    'Member': IdtyStatus.member,
    'NotMember': IdtyStatus.notMember,
    'Revoked': IdtyStatus.revoked,
    'unknown': IdtyStatus.unknown,
  };

  /// Teste la connexion à un nœud
  Future<bool> testEndPoint(String node, {Duration timeout = const Duration(seconds: 10)}) async {
    try {
      final provider = polkadart.Provider.fromUri(Uri.parse(node));
      final api = Gdev(provider);

      // Récupérer le numéro de bloc pour vérifier la connexion
      final blockNumber = await api.query.system.number().timeout(timeout);
      return blockNumber > 0;
    } catch (e) {
      log.e("Erreur lors du test du nœud $node: $e");
      return false;
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

  /// Se connecte au premier nœud disponible
  Future<bool> connectToNode() async {
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

      // Tester chaque nœud jusqu'à trouver un qui fonctionne
      for (final node in nodes) {
        try {
          final isNodeWorking = await testEndPoint(node);

          if (isNodeWorking) {
            // Initialiser la connexion
            _provider = polkadart.Provider.fromUri(Uri.parse(node));
            _api = Gdev(_provider!);

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
          }
        } catch (e) {
          log.e("Erreur lors de la connexion au nœud $node: $e");
          continue;
        }
      }

      // Aucun nœud n'a fonctionné
      isConnected = false;
      isConnecting = false;
      homeProvider.changeMessage("noDuniterEndointAvailable".tr());
      notifyListeners();

      return false;
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

    // Utiliser l'API de souscription pour obtenir les mises à jour du numéro de bloc
    _api!.query.system.number.call().then((value) {
      blocNumber = value;
      notifyListeners();
    });

    // TODO: Implémenter une vraie souscription quand l'API le permettra
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
      // Récupérer les paramètres de la blockchain
      // Note: Les noms des méthodes peuvent varier selon l'API générée
      currencyParameters = {
        'ss58': await _api!.query.system.number(), // Temporaire, à remplacer par la bonne méthode
        'minCertForMembership': 5, // Valeur par défaut, à remplacer
        'existentialDeposit': 100, // Valeur par défaut, à remplacer
        'certPeriod': 432000, // Valeur par défaut, à remplacer
        'certMaxByIssuer': 100, // Valeur par défaut, à remplacer
        'certValidityPeriod': 15552000, // Valeur par défaut, à remplacer
        'membershipRenewalPeriod': 5184000, // Valeur par défaut, à remplacer
        'membershipPeriod': 31536000, // Valeur par défaut, à remplacer
      };

      // TODO: Remplacer les valeurs par défaut par les vraies valeurs quand l'API sera disponible

      log.i('Paramètres de la blockchain initialisés: $currencyParameters');
    } catch (e) {
      log.e('Erreur lors de l\'initialisation des paramètres de la blockchain: $e');
    }
  }

  /// Initialise la valeur du dividende universel
  Future<void> _initUdValue() async {
    if (_api == null) return;

    try {
      // TODO: Remplacer par les vraies méthodes quand l'API sera disponible
      udValue = 1000; // Valeur par défaut, à remplacer
      currentUdIndex = 1; // Valeur par défaut, à remplacer

      log.i('Valeur du UD: $udValue, Index du UD: $currentUdIndex');
    } catch (e) {
      log.e('Erreur lors de l\'initialisation de la valeur du UD: $e');
    }
  }

  /// Récupère le statut d'identité d'une adresse
  Future<IdtyStatus> idtyStatus(String address) async {
    if (_api == null || !isConnected) return IdtyStatus.unknown;

    try {
      // Vérifier si le statut est en cache
      if (_idtyStatusCache.containsKey(address)) {
        return _idtyStatusCache[address]!;
      }

      // TODO: Remplacer par les vraies méthodes quand l'API sera disponible
      // Récupérer l'index de l'identité
      final idtyIndex = 0; // Valeur par défaut, à remplacer

      if (idtyIndex == 0) {
        _idtyStatusCache[address] = IdtyStatus.none;
        return IdtyStatus.none;
      }

      // Récupérer les données de l'identité
      final idtyData = {'status': 'unknown'}; // Valeur par défaut, à remplacer

      // Mapper le statut
      final status = mapStatus[idtyData['status']] ?? IdtyStatus.unknown;

      // Mettre en cache
      _idtyStatusCache[address] = status;

      return status;
    } catch (e) {
      log.e('Erreur lors de la récupération du statut d\'identité: $e');
      return IdtyStatus.unknown;
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
  Future<Map<String, int>> getBalance(String address) async {
    if (_api == null || !isConnected) {
      return {
        'transferableBalance': 0,
        'free': 0,
        'unclaimedUds': 0,
        'reserved': 0,
      };
    }

    try {
      // TODO: Implémenter avec les vraies méthodes quand l'API sera disponible
      return {
        'transferableBalance': 0,
        'free': 0,
        'unclaimedUds': 0,
        'reserved': 0,
      };
    } catch (e) {
      log.e('Erreur lors de la récupération du solde: $e');
      return {
        'transferableBalance': 0,
        'free': 0,
        'unclaimedUds': 0,
        'reserved': 0,
      };
    }
  }

  /// Calcule les UDs non réclamés
  int _computeUnclaimUds({
    required int firstEligibleUd,
    required List pastReevals,
    required IdtyStatus idtyStatus,
  }) {
    int totalAmount = 0;
    int tempCurrentUdIndex = currentUdIndex;

    if (firstEligibleUd == 0 || idtyStatus != IdtyStatus.member) return 0;

    for (final List reval in pastReevals.reversed) {
      final int udIndex = reval[0];
      final int udValue = reval[1];

      // Parcourir chaque réévaluation des UDs et additionner le solde non réclamé
      if (udIndex <= firstEligibleUd) {
        final count = tempCurrentUdIndex - firstEligibleUd;
        totalAmount += count * udValue;
        break;
      } else {
        final count = tempCurrentUdIndex - udIndex;
        totalAmount += count * udValue;
        tempCurrentUdIndex = udIndex;
      }
    }

    return totalAmount;
  }

  /// Récupère les compteurs de certifications
  Future<List<int>> getCertsCounter(String address) async {
    if (_api == null || !isConnected) return [];

    try {
      // TODO: Implémenter avec les vraies méthodes quand l'API sera disponible
      return [];
    } catch (e) {
      log.e('Erreur lors de la récupération des compteurs de certifications: $e');
      return [];
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
  Future<CertState> certState(String to) async {
    if (_api == null || !isConnected) {
      return CertState(status: CertStatus.none);
    }

    try {
      // TODO: Implémenter avec les vraies méthodes quand l'API sera disponible
      return CertState(status: CertStatus.none);
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
      // TODO: Implémenter avec les vraies méthodes quand l'API sera disponible
      return 0;
    } catch (e) {
      log.e('Erreur lors de la récupération de la période de validité de la certification: $e');
      return 0;
    }
  }

  /// Récupère les métadonnées de certification
  Future<Map> getCertMeta(String address) async {
    if (_api == null || !isConnected) return {};

    try {
      // TODO: Implémenter avec les vraies méthodes quand l'API sera disponible
      return {};
    } catch (e) {
      log.e('Erreur lors de la récupération des métadonnées de certification: $e');
      return {};
    }
  }

  /// Récupère le statut d'adhésion
  Future<MembershipStatus> getMembershipStatus(String address) async {
    if (_api == null || !isConnected) {
      return MembershipStatus.empty();
    }

    try {
      // TODO: Implémenter avec les vraies méthodes quand l'API sera disponible
      return MembershipStatus.empty();
    } catch (e) {
      log.e('Erreur lors de la récupération du statut d\'adhésion: $e');
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
