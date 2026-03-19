import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/providers/mnemonic_providers.dart';
import 'package:gecko/services/mnemonic_service.dart';
import 'package:gecko/services/wallet_scan_service.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/widgets/scan_derivations_info.dart';

/// Provider for WalletScanService instance
final walletScanServiceProvider = Provider<WalletScanService>((ref) {
  return WalletScanService(ref);
});

/// State for wallet derivation scanning
class WalletScanState {
  final WalletScanStatus status;
  final int scannedWalletCount;
  final int validWalletCount;
  final bool isScanning;
  final WalletScanResult? result;
  final String? error;

  const WalletScanState({
    this.status = WalletScanStatus.none,
    this.scannedWalletCount = 0,
    this.validWalletCount = 0,
    this.isScanning = false,
    this.result,
    this.error,
  });

  WalletScanState copyWith({
    WalletScanStatus? status,
    int? scannedWalletCount,
    int? validWalletCount,
    bool? isScanning,
    WalletScanResult? result,
    String? error,
  }) {
    return WalletScanState(
      status: status ?? this.status,
      scannedWalletCount: scannedWalletCount ?? this.scannedWalletCount,
      validWalletCount: validWalletCount ?? this.validWalletCount,
      isScanning: isScanning ?? this.isScanning,
      result: result ?? this.result,
      error: error,
    );
  }

  bool get hasError => error != null;
  bool get isCompleted => result != null;
  bool get hasWallets => result?.hasWallets ?? false;
}

/// Notifier for managing wallet scan state
class WalletScanNotifier extends Notifier<WalletScanState> {
  @override
  WalletScanState build() {
    return const WalletScanState();
  }

  WalletScanService get _scanService => ref.read(walletScanServiceProvider);

  /// Start scanning derivations for the given mnemonic
  Future<ScanDerivationsResult> scanDerivations({
    required BuildContext context,
    required MnemonicResult mnemonicResult,
    int maxDerivations = 30,
  }) async {
    // Reset state
    state = const WalletScanState(isScanning: true);

    try {
      final result = await _scanService.scanDerivations(
        mnemonicResult: mnemonicResult,
        onStatusChanged: _updateStatus,
        onWalletCountChanged: _updateWalletCount,
        maxDerivations: maxDerivations,
      );

      if (result.isTimeout) {
        // ignore: use_build_context_synchronously
        await _handleTimeout(context);
        return ScanDerivationsResult.timeout;
      }

      if (result.hasError) {
        if (!context.mounted) return ScanDerivationsResult.error;
        await _handleError(context, result.errorMessage ?? 'Unknown error');
        return ScanDerivationsResult.error;
      }

      // Success
      state = state.copyWith(isScanning: false, result: result, status: WalletScanStatus.completed);

      return result.hasWallets ? ScanDerivationsResult.walletExists : ScanDerivationsResult.walletNotFound;
    } catch (e) {
      log.e('Error in scanDerivations: $e');
      if (!context.mounted) return ScanDerivationsResult.error;
      await _handleError(context, e.toString());
      return ScanDerivationsResult.error;
    }
  }

  void _updateStatus(WalletScanStatus status) {
    state = state.copyWith(status: status);
  }

  void _updateWalletCount(int count) {
    state = state.copyWith(scannedWalletCount: count);
  }

  Future<void> _handleTimeout(BuildContext context) async {
    state = state.copyWith(isScanning: false, error: 'Scan timed out', status: WalletScanStatus.none);
    ref.read(resetMnemonicStateProvider)();

    await showConfirmationDialog(
      context: context,
      message: "timeoutScanDerivations".tr(),
      confirmText: "gotit".tr(),
      hideCancelButton: true,
      type: ConfirmationDialogType.error,
    );

    if (context.mounted) {
      await Navigator.of(context).pushNamedAndRemoveUntil(RouteNames.home, (Route<dynamic> route) => false);
    }
  }

  Future<void> _handleError(BuildContext context, String error) async {
    state = state.copyWith(isScanning: false, error: error, status: WalletScanStatus.none);
    ref.read(resetMnemonicStateProvider)();

    String message = "errorScanDerivations".tr();
    if (error.contains('already exists')) {
      message = 'safeAlreadyExist'.tr();
    }

    await showConfirmationDialog(
      context: context,
      type: ConfirmationDialogType.error,
      title: 'error'.tr(),
      message: message,
      hideCancelButton: true,
    );

    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(RouteNames.home, (route) => false);
    }
  }

  /// Reset the scan state
  void reset() {
    state = const WalletScanState();
  }
}

/// Provider for wallet scan state management
final walletScanProvider = NotifierProvider<WalletScanNotifier, WalletScanState>(WalletScanNotifier.new);

/// Provider for the current scan status message
final scanStatusMessageProvider = Provider<String>((ref) {
  final scanState = ref.watch(walletScanProvider);

  switch (scanState.status) {
    case WalletScanStatus.none:
      return '';
    case WalletScanStatus.scanningRoot:
      return 'Scanning root wallet...';
    case WalletScanStatus.generatingKeypairs:
      return 'Generating keypairs...';
    case WalletScanStatus.scanningBalances:
      return 'Scanning balances...';
    case WalletScanStatus.importingWallets:
      return 'Importing wallets...';
    case WalletScanStatus.completed:
      return 'Scan completed';
  }
});

/// Provider for scan progress information
final scanProgressProvider = Provider<({int current, int total, double progress})>((ref) {
  final scanState = ref.watch(walletScanProvider);

  // Calculate progress based on status and wallet count
  int current = 0;
  int total = 100; // Base progress out of 100

  switch (scanState.status) {
    case WalletScanStatus.none:
      current = 0;
      break;
    case WalletScanStatus.scanningRoot:
      current = 10;
      break;
    case WalletScanStatus.generatingKeypairs:
      current = 25;
      break;
    case WalletScanStatus.scanningBalances:
      current = 50;
      break;
    case WalletScanStatus.importingWallets:
      current = 75 + (scanState.scannedWalletCount * 2); // Progress with wallet count
      break;
    case WalletScanStatus.completed:
      current = 100;
      break;
  }

  final progress = (current / total).clamp(0.0, 1.0);

  return (current: current, total: total, progress: progress);
});

/// Provider for checking if scanning is possible (connected to network)
final canStartScanProvider = Provider<bool>((ref) {
  return ref.watch(durtProvider).isConnected;
});

/// Function provider for starting a scan with mnemonic
final startScanProvider =
    Provider<Future<ScanDerivationsResult> Function(BuildContext, MnemonicResult, {int maxDerivations})>((ref) {
      return (context, mnemonicResult, {int maxDerivations = 30}) {
        return ref
            .read(walletScanProvider.notifier)
            .scanDerivations(context: context, mnemonicResult: mnemonicResult, maxDerivations: maxDerivations);
      };
    });

/// Provider for resetting scan state
final resetScanProvider = Provider<VoidCallback>((ref) {
  return () {
    ref.read(walletScanProvider.notifier).reset();
  };
});

/// Provider that combines scan state with UI-friendly information
final scanDisplayInfoProvider = Provider<ScanDisplayInfo>((ref) {
  final scanState = ref.watch(walletScanProvider);
  final progress = ref.watch(scanProgressProvider);
  final statusMessage = ref.watch(scanStatusMessageProvider);

  return ScanDisplayInfo(
    status: scanState.status,
    isScanning: scanState.isScanning,
    scannedWalletCount: scanState.scannedWalletCount,
    validWalletCount: scanState.validWalletCount,
    progress: progress.progress,
    statusMessage: statusMessage,
    hasError: scanState.hasError,
    errorMessage: scanState.error,
    isCompleted: scanState.isCompleted,
    hasWallets: scanState.hasWallets,
  );
});

/// UI-friendly class for scan display information
class ScanDisplayInfo {
  final WalletScanStatus status;
  final bool isScanning;
  final int scannedWalletCount;
  final int validWalletCount;
  final double progress;
  final String statusMessage;
  final bool hasError;
  final String? errorMessage;
  final bool isCompleted;
  final bool hasWallets;

  const ScanDisplayInfo({
    required this.status,
    required this.isScanning,
    required this.scannedWalletCount,
    required this.validWalletCount,
    required this.progress,
    required this.statusMessage,
    required this.hasError,
    this.errorMessage,
    required this.isCompleted,
    required this.hasWallets,
  });

  bool get showProgress => isScanning && !hasError;
  bool get showWalletCount => scannedWalletCount > 0 || status == WalletScanStatus.importingWallets;
}
