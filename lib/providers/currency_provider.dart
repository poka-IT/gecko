import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/globals.dart';

/// Currency parameters
class CurrencyParameters {
  final String currencyName;
  final String currencyNetwork;
  final String currencySymbol;
  final int members;
  final double monetaryMass;
  final double currentUd;
  final double ud0;
  final int udCreationPeriodMs;
  final int udReevalPeriodMs;
  final double growthRate;
  final int pastReevals;

  const CurrencyParameters({
    required this.currencyName,
    required this.currencyNetwork,
    required this.currencySymbol,
    required this.members,
    required this.monetaryMass,
    required this.currentUd,
    required this.ud0,
    required this.udCreationPeriodMs,
    required this.udReevalPeriodMs,
    required this.growthRate,
    required this.pastReevals,
  });
}

/// WoT parameters
class WotParameters {
  final int sigQtyRule;
  final int sigWindow;
  final int sigValidity;
  final int sigStock;
  final int sigPeriod;
  final int msWindow;
  final int msValidity;
  final int stepMax;
  final int sentries;
  final double xPercent;

  const WotParameters({
    required this.sigQtyRule,
    required this.sigWindow,
    required this.sigValidity,
    required this.sigStock,
    required this.sigPeriod,
    required this.msWindow,
    required this.msValidity,
    required this.stepMax,
    required this.sentries,
    required this.xPercent,
  });
}

/// Combined currency data containing both currency and WoT parameters
class CurrencyData {
  final CurrencyParameters currencyParams;
  final WotParameters wotParams;

  const CurrencyData({required this.currencyParams, required this.wotParams});
}

/// Provider for currency data
final currencyDataProvider = AsyncNotifierProvider<CurrencyDataNotifier, CurrencyData>(() {
  return CurrencyDataNotifier();
});

/// Notifier for currency data
class CurrencyDataNotifier extends AsyncNotifier<CurrencyData> {
  @override
  Future<CurrencyData> build() async {
    return _loadCurrencyData();
  }

  /// Load currency data from Duniter blockchain
  Future<CurrencyData> _loadCurrencyData() async {
    try {
      final durt = ref.watch(durtProvider);
      final blockchain = durt.blockchain;
      final network = durt.network;

      // Get block time constant for time calculations
      final msPerBlock = blockchain.constant.babe.expectedBlockTime.toInt();

      // Get currency decimals for calculations
      final powBase = 100.0; // Duniter uses 2 decimal places (centimes)

      // Fetch data in parallel for better performance
      final results = await Future.wait([
        // Currency data
        blockchain.query.universalDividend.monetaryMass(),
        blockchain.query.universalDividend.currentUd(),
        blockchain.query.membership.counterForMembership(),
        blockchain.query.universalDividend.pastReevals(),
      ]);

      final monetaryMass = results[0] as BigInt;
      final currentUd = results[1] as BigInt;
      final members = results[2] as int;
      final pastReevals = results[3] as List;

      // Get constants
      final udCreationPeriod = blockchain.constant.universalDividend.udCreationPeriod.toInt();
      final udReevalPeriod = blockchain.constant.universalDividend.udReevalPeriod.toInt();
      final growthRate = math.sqrt(2381440.0 / 1000000000.0); // Convert from Perbill (constant value from blockchain)

      // Get UD0 (first UD value)
      final ud0 = 1000.0 / powBase; // Default initial UD value

      // Get WoT parameters
      final sigQtyRule = blockchain.constant.wot.minCertForMembership;
      final msWindow = blockchain.constant.distance.evaluationPeriod * msPerBlock * 3;
      final msValidity = blockchain.constant.membership.membershipPeriod * msPerBlock;
      final sigWindow = blockchain.constant.membership.membershipRenewalPeriod * msPerBlock;
      final sigValidity = blockchain.constant.certification.validityPeriod * msPerBlock;
      final sigStock = blockchain.constant.certification.maxByIssuer;
      final sigPeriod = blockchain.constant.certification.certPeriod * msPerBlock;
      final stepMax = blockchain.constant.distance.maxRefereeDistance;
      final sentries = blockchain.constant.smithMembers.minCertForMembership;
      final xPercent = blockchain.constant.distance.minAccessibleReferees / 1000000000.0;

      // Create currency parameters
      final currencyParams = CurrencyParameters(
        currencyName: network.displayName,
        currencyNetwork: network.name,
        currencySymbol: network.symbol,
        members: members,
        monetaryMass: monetaryMass.toDouble() / powBase,
        currentUd: currentUd.toDouble() / powBase,
        ud0: ud0,
        udCreationPeriodMs: udCreationPeriod,
        udReevalPeriodMs: udReevalPeriod,
        growthRate: growthRate,
        pastReevals: pastReevals.isNotEmpty ? pastReevals.length : 0,
      );

      // Create WoT parameters
      final wotParams = WotParameters(
        sigQtyRule: sigQtyRule,
        sigWindow: sigWindow,
        sigValidity: sigValidity,
        sigStock: sigStock,
        sigPeriod: sigPeriod,
        msWindow: msWindow,
        msValidity: msValidity,
        stepMax: stepMax,
        sentries: sentries,
        xPercent: xPercent,
      );

      return CurrencyData(currencyParams: currencyParams, wotParams: wotParams);
    } catch (error) {
      log.e('Error loading currency data: $error');
      rethrow;
    }
  }

  /// Refresh currency data
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadCurrencyData());
  }
}
