import 'package:durt2/durt2.dart' hide Provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/providers.dart';
import 'package:durt2/durt2.dart' as durt2;

/// Enum for currency display modes
enum CurrencyDisplayMode {
  /// Display amounts in G1 units (default)
  g1,

  /// Display amounts in Universal Dividend units (DU)
  du,

  /// Display amounts in M/N ratio format (Money supply / Number of members)
  moneyOverMembers,
}

extension CurrencyDisplayModeExtension on CurrencyDisplayMode {
  String get name {
    return switch (this) {
      CurrencyDisplayMode.g1 => 'G1',
      CurrencyDisplayMode.du => 'DU',
      CurrencyDisplayMode.moneyOverMembers => 'M/N',
    };
  }

  String get translationKey {
    return switch (this) {
      CurrencyDisplayMode.g1 => 'displayG1',
      CurrencyDisplayMode.du => 'displayDU',
      CurrencyDisplayMode.moneyOverMembers => 'displayMN',
    };
  }

  String get description {
    return switch (this) {
      CurrencyDisplayMode.g1 => 'displayG1Description',
      CurrencyDisplayMode.du => 'displayDUDescription',
      CurrencyDisplayMode.moneyOverMembers => 'displayMNDescription',
    };
  }

  /// Get the currency symbol based on display mode
  String get symbol {
    return switch (this) {
      CurrencyDisplayMode.g1 => Durt.i.network.symbol,
      CurrencyDisplayMode.du => 'DU',
      CurrencyDisplayMode.moneyOverMembers => 'mM/N',
    };
  }
}

/// TRM Data containing Money supply and Members count
class TrmData {
  final BigInt moneySupply; // M - Total money supply
  final int membersCount; // N - Number of members in the web of trust
  final DateTime lastUpdated;

  TrmData({required this.moneySupply, required this.membersCount, required this.lastUpdated});

  /// Calculate M/N ratio as a double
  double get moneyOverMembersRatio {
    if (membersCount == 0) return 0.0;
    // Convert moneySupply from centimes to G1 before calculating ratio
    // In Duniter, blockchain amounts are in centimes (1 G1 = 100 centimes)
    final moneySupplyInG1 = moneySupply.toDouble() / 100.0;
    return moneySupplyInG1 / membersCount.toDouble();
  }

  @override
  String toString() {
    return 'TrmData(moneySupply: $moneySupply, membersCount: $membersCount, ratio: ${moneyOverMembersRatio.toStringAsFixed(2)})';
  }
}

/// Provider for TRM data (Money supply and Members count)
final trmDataProvider = StateNotifierProvider<TrmDataNotifier, AsyncValue<TrmData>>((ref) {
  return TrmDataNotifier();
});

/// Provider for current currency display mode
final currencyDisplayModeProvider = StateNotifierProvider<CurrencyDisplayModeNotifier, CurrencyDisplayMode>((ref) {
  return CurrencyDisplayModeNotifier();
});

/// Provider for balance ratio calculation
final balanceRatioProvider = Provider<BigInt>((ref) {
  final displayMode = ref.watch(currencyDisplayModeProvider);
  final trmDataAsync = ref.watch(trmDataProvider);
  final trmData = trmDataAsync.maybeWhen(data: (data) => data, orElse: () => null);

  return _getBalanceRatio(displayMode, trmData, ref);
});

/// Provider for currency symbol
final currencySymbolProvider = Provider<String>((ref) {
  final displayMode = ref.watch(currencyDisplayModeProvider);
  return displayMode.symbol;
});

/// Get balance ratio for currency conversion based on display mode (for display purposes)
BigInt _getBalanceRatio(CurrencyDisplayMode displayMode, TrmData? trmData, Ref ref) {
  switch (displayMode) {
    case CurrencyDisplayMode.g1:
      // Convert centimes to G1 (1 G1 = 100 centimes)
      return BigInt.from(100);
    case CurrencyDisplayMode.du:
      final udValue = ref.read(storageServiceProvider).udInfoNotifier.value;
      return udValue.currentUd;
    case CurrencyDisplayMode.moneyOverMembers:
      // For mM/N display mode: centimes → G1 → M/N → mM/N
      // ratio = moneyOverMembersRatio * 100 / 1000 = moneyOverMembersRatio / 10
      if (trmData == null || trmData.membersCount == 0) {
        return BigInt.from(100); // fallback to G1 conversion
      }
      final preciseRatio = trmData.moneyOverMembersRatio * 100.0 / 1000.0;
      return BigInt.from(preciseRatio.round());
  }
}

class TrmDataNotifier extends StateNotifier<AsyncValue<TrmData>> {
  TrmDataNotifier() : super(const AsyncValue.loading()) {
    _loadTrmData();
  }

  /// Load TRM data from Duniter blockchain
  Future<void> _loadTrmData() async {
    try {
      state = const AsyncValue.loading();

      // Use the existing Durt instance directly instead of creating a new container
      final durt = durt2.Durt.i;

      // Get money supply (M) from Duniter
      final moneySupply = await durt.blockchain.query.balances.totalIssuance();

      // Get members count (N) from Duniter
      final membersCount = await durt.blockchain.query.membership.counterForMembership();

      final trmData = TrmData(moneySupply: moneySupply, membersCount: membersCount, lastUpdated: DateTime.now());

      state = AsyncValue.data(trmData);

      // ignore: avoid_print
      print(
        'TRM data loaded: M=${(moneySupply.toDouble() / 100).toStringAsFixed(0)} G1 ($moneySupply centimes), N=$membersCount, M/N=${trmData.moneyOverMembersRatio.toStringAsFixed(2)} G1/member',
      );
    } catch (error, stackTrace) {
      log.e('Error loading TRM data: $error');
      // Check if still mounted before updating state with error
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  /// Refresh TRM data
  Future<void> refresh() async {
    await _loadTrmData();
  }
}

class CurrencyDisplayModeNotifier extends StateNotifier<CurrencyDisplayMode> {
  CurrencyDisplayModeNotifier() : super(_getInitialMode());

  static CurrencyDisplayMode _getInitialMode() {
    // Check if user has legacy DU mode enabled
    final isUdUnit = configBox.get('isUdUnit') ?? false;
    if (isUdUnit) {
      return CurrencyDisplayMode.du;
    }

    // Check for new display mode setting
    final displayModeString = configBox.get('currencyDisplayMode') ?? 'g1';
    return CurrencyDisplayMode.values.firstWhere(
      (mode) => mode.name.toLowerCase() == displayModeString.toLowerCase(),
      orElse: () => CurrencyDisplayMode.g1,
    );
  }

  void setDisplayMode(CurrencyDisplayMode mode) {
    state = mode;

    // Save to config
    configBox.put('currencyDisplayMode', mode.name.toLowerCase());

    // Update legacy DU setting for backward compatibility
    configBox.put('isUdUnit', mode == CurrencyDisplayMode.du);

    log.i('Currency display mode changed to: ${mode.name}');
  }
}
