import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durt2/durt2.dart'
    show CsToV2AddressResult, IdtyStatus, MigrateWalletChecks, WalletBalance, WalletEntity;
import 'package:durt2/durt2.dart' as d;
import 'package:gecko/globals.dart';
import 'package:gecko/models/migration_data.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/services/g1v1_migration_service.dart';

// ============================================================================
// UI VISIBILITY STATE (kept from before)
// ============================================================================

/// State for G1v1 migration UI visibility flags
class G1v1MigrationUiState {
  final bool isCesiumIDVisible;
  final bool isCesiumPasswordVisible;

  const G1v1MigrationUiState({this.isCesiumIDVisible = false, this.isCesiumPasswordVisible = false});

  G1v1MigrationUiState copyWith({bool? isCesiumIDVisible, bool? isCesiumPasswordVisible}) {
    return G1v1MigrationUiState(
      isCesiumIDVisible: isCesiumIDVisible ?? this.isCesiumIDVisible,
      isCesiumPasswordVisible: isCesiumPasswordVisible ?? this.isCesiumPasswordVisible,
    );
  }
}

/// Notifier for G1v1 migration UI visibility
class G1v1MigrationUiNotifier extends Notifier<G1v1MigrationUiState> {
  @override
  G1v1MigrationUiState build() {
    return const G1v1MigrationUiState();
  }

  /// Toggle visibility of Cesium ID field
  void toggleCesiumIDVisibility() {
    state = state.copyWith(isCesiumIDVisible: !state.isCesiumIDVisible);
  }

  /// Toggle visibility of Cesium password field
  void toggleCesiumPasswordVisibility() {
    state = state.copyWith(isCesiumPasswordVisible: !state.isCesiumPasswordVisible);
  }

  /// Reset UI state
  void reset() {
    state = const G1v1MigrationUiState();
  }
}

/// Provider for G1v1 migration UI state
final g1v1MigrationUiProvider = NotifierProvider<G1v1MigrationUiNotifier, G1v1MigrationUiState>(
  G1v1MigrationUiNotifier.new,
);

/// Provider for Cesium salt TextEditingController
/// Not autoDispose: must survive PageView page changes (StepCredentials -> StepConfirmation)
final csSaltControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

/// Provider for Cesium password TextEditingController
/// Not autoDispose: must survive PageView page changes (StepCredentials -> StepConfirmation)
final csPasswordControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

// ============================================================================
// MIGRATION FLOW STATE
// ============================================================================

/// Type of account detected from Cesium credentials
enum MigrationAccountType { unknown, empty, alreadyMigrated, balanceOnly, withIdentity }

/// Immutable state for the multi-step migration flow
class G1v1MigrationFlowState {
  final int currentStep;
  final bool isConverting;
  final CsToV2AddressResult? conversionResult;
  final MigrateWalletChecks? migrationChecks;
  final WalletEntity? selectedTargetWallet;
  final bool createNewWallet;
  final String? errorMessage;
  final WalletBalance? sourceBalance;
  final IdtyStatus? sourceIdtyStatus;
  final String? sourceIdentityName;
  final MigrationData? migrationFromData;

  const G1v1MigrationFlowState({
    this.currentStep = 0,
    this.isConverting = false,
    this.conversionResult,
    this.migrationChecks,
    this.selectedTargetWallet,
    this.createNewWallet = false,
    this.errorMessage,
    this.sourceBalance,
    this.sourceIdtyStatus,
    this.sourceIdentityName,
    this.migrationFromData,
  });

  G1v1MigrationFlowState copyWith({
    int? currentStep,
    bool? isConverting,
    CsToV2AddressResult? conversionResult,
    bool clearConversionResult = false,
    MigrateWalletChecks? migrationChecks,
    bool clearMigrationChecks = false,
    WalletEntity? selectedTargetWallet,
    bool clearSelectedTargetWallet = false,
    bool? createNewWallet,
    String? errorMessage,
    bool clearErrorMessage = false,
    WalletBalance? sourceBalance,
    bool clearSourceBalance = false,
    IdtyStatus? sourceIdtyStatus,
    bool clearSourceIdtyStatus = false,
    String? sourceIdentityName,
    bool clearSourceIdentityName = false,
    MigrationData? migrationFromData,
    bool clearMigrationFromData = false,
  }) {
    return G1v1MigrationFlowState(
      currentStep: currentStep ?? this.currentStep,
      isConverting: isConverting ?? this.isConverting,
      conversionResult: clearConversionResult ? null : (conversionResult ?? this.conversionResult),
      migrationChecks: clearMigrationChecks ? null : (migrationChecks ?? this.migrationChecks),
      selectedTargetWallet: clearSelectedTargetWallet ? null : (selectedTargetWallet ?? this.selectedTargetWallet),
      createNewWallet: createNewWallet ?? this.createNewWallet,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      sourceBalance: clearSourceBalance ? null : (sourceBalance ?? this.sourceBalance),
      sourceIdtyStatus: clearSourceIdtyStatus ? null : (sourceIdtyStatus ?? this.sourceIdtyStatus),
      sourceIdentityName: clearSourceIdentityName ? null : (sourceIdentityName ?? this.sourceIdentityName),
      migrationFromData: clearMigrationFromData ? null : (migrationFromData ?? this.migrationFromData),
    );
  }

  /// Whether valid credentials have been entered and converted
  bool get hasValidCredentials => conversionResult != null && conversionResult!.pubkey.isNotEmpty;

  /// Whether the source account has a transferable balance
  bool get hasBalance => sourceBalance != null && sourceBalance!.transferableBalance > BigInt.zero;

  /// Whether the source account has an identity
  bool get hasIdentity =>
      sourceIdtyStatus != null && sourceIdtyStatus != IdtyStatus.none && sourceIdtyStatus != IdtyStatus.unknown;

  /// Whether a target has been selected (wallet or create new)
  bool get hasTarget => selectedTargetWallet != null || createNewWallet;

  /// Whether migration can proceed
  bool get canMigrate {
    if (!hasValidCredentials || !hasBalance) return false;
    if (!hasTarget) return false;
    if (migrationChecks != null && !migrationChecks!.canMigrate && !createNewWallet) return false;
    return true;
  }

  /// Determine account type based on balance and identity
  MigrationAccountType get accountType {
    if (!hasValidCredentials) return MigrationAccountType.unknown;
    if (migrationFromData != null) return MigrationAccountType.alreadyMigrated;
    if (!hasBalance) return MigrationAccountType.empty;
    if (hasIdentity) return MigrationAccountType.withIdentity;
    return MigrationAccountType.balanceOnly;
  }

  /// V2 address from conversion result
  String get v2Address => conversionResult?.address ?? '';

  /// V1 pubkey from conversion result
  String get v1Pubkey => conversionResult?.pubkey ?? '';
}

/// Notifier for the multi-step G1v1 migration flow
class G1v1MigrationFlowNotifier extends Notifier<G1v1MigrationFlowState> {
  @override
  G1v1MigrationFlowState build() {
    return const G1v1MigrationFlowState();
  }

  /// Navigate to a specific step
  void goToStep(int step) {
    if (step >= 0 && step <= 3) {
      state = state.copyWith(currentStep: step);
    }
  }

  /// Navigate to the next step
  void nextStep() {
    if (state.currentStep < 3) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  /// Navigate to the previous step
  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// Convert Cesium credentials to V2 address and fetch account info
  Future<void> convertAndFetchAccountInfo() async {
    final saltController = ref.read(csSaltControllerProvider);
    final passwordController = ref.read(csPasswordControllerProvider);

    final salt = saltController.text.trim();
    final password = passwordController.text.trim();

    if (!G1v1MigrationService.isValidCredentials(salt, password)) {
      state = state.copyWith(
        clearConversionResult: true,
        clearSourceBalance: true,
        clearSourceIdtyStatus: true,
        clearSourceIdentityName: true,
        clearMigrationFromData: true,
        clearErrorMessage: true,
      );
      return;
    }

    state = state.copyWith(isConverting: true, clearErrorMessage: true);

    try {
      final utils = ref.read(utilsProvider);
      final result = await G1v1MigrationService.convertCsToV2Address(utils: utils, salt: salt, password: password);

      final storageService = ref.read(storageServiceProvider);
      final squidService = ref.read(squidServiceProvider);

      // Fetch balance
      final balance = await storageService.getBalance(result.address);

      // Fetch identity status
      final idtyStatus = await storageService.getIdtyStatus(result.address);

      // Fetch identity name from squid indexer
      String? identityName;
      if (idtyStatus != IdtyStatus.none && idtyStatus != IdtyStatus.unknown) {
        identityName = squidService.walletNameIndexer[result.address];
      }

      // If account is empty and has no identity, check if it was already migrated
      MigrationData? migrationFromData;
      if (balance.transferableBalance == BigInt.zero && idtyStatus == IdtyStatus.none) {
        try {
          final squidClient = d.SquidService.client;
          final migrations = await squidClient.getIdentityMigrations(result.address);
          if (migrations?.migrationFrom != null) {
            final genesisTime = await ref.read(genesisTimeProvider.future);
            if (genesisTime != null) {
              migrationFromData = await MigrationData.fromSquidMigrationFromNode(
                migrations!.migrationFrom!,
                genesisTime,
              );
            }
          }
        } catch (e) {
          log.d('Could not check migration history: $e');
        }
      }

      state = state.copyWith(
        isConverting: false,
        conversionResult: result,
        sourceBalance: balance,
        sourceIdtyStatus: idtyStatus,
        sourceIdentityName: identityName,
        migrationFromData: migrationFromData,
      );
    } catch (e) {
      log.e('G1v1 conversion error: $e');
      state = state.copyWith(
        isConverting: false,
        errorMessage: e.toString(),
        clearConversionResult: true,
        clearSourceBalance: true,
        clearSourceIdtyStatus: true,
        clearSourceIdentityName: true,
        clearMigrationFromData: true,
      );
    }
  }

  /// Select an existing wallet as migration target
  Future<void> selectTargetWallet(WalletEntity wallet) async {
    state = state.copyWith(
      selectedTargetWallet: wallet,
      createNewWallet: false,
      clearMigrationChecks: true,
      clearErrorMessage: true,
    );

    if (state.v2Address.isNotEmpty) {
      try {
        final checks = await ref
            .read(storageServiceProvider)
            .getMigrateWalletChecks(fromAddress: state.v2Address, toAddress: wallet.address);
        state = state.copyWith(migrationChecks: checks);
      } catch (e) {
        log.e('Error fetching migration checks: $e');
        state = state.copyWith(errorMessage: e.toString());
      }
    }
  }

  /// Select "Create new wallet" as migration target
  void selectCreateNewWallet() {
    state = state.copyWith(
      createNewWallet: true,
      clearSelectedTargetWallet: true,
      clearMigrationChecks: true,
      clearErrorMessage: true,
    );
  }

  /// Reset the entire flow state
  void reset() {
    state = const G1v1MigrationFlowState();
  }
}

/// Provider for the G1v1 migration flow state
final g1v1MigrationFlowProvider = NotifierProvider<G1v1MigrationFlowNotifier, G1v1MigrationFlowState>(
  G1v1MigrationFlowNotifier.new,
);
