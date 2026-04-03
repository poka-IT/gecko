// ignore_for_file: file_names, use_build_context_synchronously

import 'package:durt2/durt2.dart' show WalletEntity, TransactionState, WalletService;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/widgets/desktop/modals/transaction_progress_modal.dart';
import 'package:gecko/providers/biometric_provider.dart';
import 'package:gecko/providers/wallet_generation_providers.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/services/wallet_name_service.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/commons/build_progress_bar.dart';
import 'package:gecko/widgets/commons/build_text.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/widgets/commons/responsive_center.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/widgets/pin/gecko_pin_entry.dart';
import 'package:gecko/widgets/scan_derivations_info.dart';
import 'package:gif_view/gif_view.dart';

class OnboardingStepTen extends ConsumerStatefulWidget {
  const OnboardingStepTen({
    Key? validationKey,
    required this.pinCode,
    this.scanDerivation = false,
    this.fromRestore = false,
    this.legacySalt,
    this.legacyPassword,
    this.legacyMigrationData,
  }) : super(key: validationKey);

  final bool scanDerivation;
  final String pinCode;
  final bool fromRestore;
  final String? legacySalt;
  final String? legacyPassword;
  final LegacyMigrationData? legacyMigrationData;

  @override
  ConsumerState<OnboardingStepTen> createState() => _OnboardingStepTenState();
}

class _OnboardingStepTenState extends ConsumerState<OnboardingStepTen> {
  final _pinController = GeckoPinEntryController();
  bool hasError = false;

  /// Blocks back navigation while safe creation/scan is in progress.
  bool _isProcessing = false;

  bool get _isLegacy => widget.legacySalt != null && widget.legacyPassword != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(resetScanProvider)();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Core flow: safe creation, wallet import, navigation
  // ---------------------------------------------------------------------------

  Future<void> _handlePinConfirmed() async {
    setState(() => _isProcessing = true);

    try {
      final migrationData = widget.legacyMigrationData ?? ref.read(pendingLegacyMigrationProvider);
      final isMigrationToExistingSafe = migrationData?.isToExistingSafe ?? false;

      if (isMigrationToExistingSafe && migrationData?.targetWalletAddress != null) {
        await _handleDirectMigrationToExistingSafe(migrationData!);
        return;
      }

      await _handleSafeCreationFlow(migrationData);
    } catch (e) {
      log.e('Error during safe setup: $e');
      _clearSensitiveState();

      if (context.mounted) {
        await showConfirmationDialog(
          context: context,
          type: ConfirmationDialogType.error,
          title: 'error'.tr(),
          message: 'errorScanDerivations'.tr(),
          hideCancelButton: true,
        );
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(RouteNames.home, (route) => false);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleDirectMigrationToExistingSafe(LegacyMigrationData migrationData) async {
    try {
      final walletService = ref.read(walletServiceProvider);
      final targetWallet = walletService.getWalletData(migrationData.targetWalletAddress!);
      final targetSafeNumber = targetWallet.safe.target!.number;

      log.i('Direct migration to existing safe $targetSafeNumber, target wallet: ${migrationData.targetWalletAddress}');

      final finalSafeNumber = await _performLegacyMigrationWithProgress(context, ref, targetWallet, migrationData);

      ref.read(pendingLegacyMigrationProvider.notifier).clear();
      _clearSensitiveState();

      ref.read(defaultSafeBoxNumberProvider.notifier).setDefaultSafeBoxNumber(finalSafeNumber);
      await ref.read(walletsListProvider.notifier).loadWallets(safeBoxNumber: finalSafeNumber);
      ref.read(walletActionsProvider.notifier).invalidateProviders();

      final walletCount = ref.read(walletsListProvider).wallets.length;
      log.i('Direct migration complete. Safe $finalSafeNumber loaded with $walletCount wallets');

      if (context.mounted) {
        await AppNavigator.pushWithFader(
          context,
          RouteNames.onboardingStepEleven,
          arguments: OnboardingStepElevenArguments(
            fromRestore: widget.fromRestore,
            pinCode: widget.pinCode,
            isLegacyMode: true,
          ),
        );
      }
    } catch (e) {
      log.e('Error during direct migration to existing safe: $e');
      _clearSensitiveState();

      if (context.mounted) {
        await showConfirmationDialog(
          context: context,
          type: ConfirmationDialogType.error,
          title: 'error'.tr(),
          message: 'migrationError'.tr(args: [e.toString()]),
          hideCancelButton: true,
        );
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  Future<void> _handleSafeCreationFlow(LegacyMigrationData? migrationData) async {
    bool safeJustCreated = false;

    try {
      safeJustCreated = await _createSafe();

      ref.read(defaultSafeBoxNumberProvider.notifier).refresh();

      await ref.read(biometricProvider.notifier).refresh();
      final currentSafe = ref.read(walletServiceProvider).defaultSafeBoxNumber;
      PinCodeService.setAuthenticatedSafe(currentSafe);

      if (!_isLegacy) {
        final exitedEarly = await _scanAndImportWallets();
        if (exitedEarly) {
          _clearSensitiveState();
          return;
        }
      }

      final walletService = ref.read(walletServiceProvider);
      await ref.read(walletsListProvider.notifier).loadWallets(safeBoxNumber: currentSafe);

      ref.read(walletActionsProvider.notifier).invalidateProviders();
      ref.invalidate(idtyWalletAsyncProvider);
      ref.invalidate(identityWalletsAsyncProvider);

      _clearSensitiveState();

      final defaultWallet = await _selectDefaultWallet();
      if (defaultWallet != null) {
        await ref.read(walletServiceProvider).setDefaultAddress(defaultWallet.address);
      }

      if (migrationData != null) {
        WalletEntity? migrationTarget = defaultWallet;
        if (migrationTarget == null) {
          try {
            final safe = walletService.getSafeBox(currentSafe);
            if (safe.rootAddress != null) {
              migrationTarget = walletService.getWalletData(safe.rootAddress!);
            }
          } catch (e) {
            log.w('Could not recover migration target from safe: $e');
          }
        }

        if (migrationTarget != null) {
          final shouldReturn = await _handleLegacyMigration(migrationData, migrationTarget);
          if (shouldReturn) return;
        } else {
          log.e('Migration skipped: no target wallet available for safe $currentSafe');
        }
      }

      final currentSafeNumber = ref.read(walletServiceProvider).defaultSafeBoxNumber;
      ref.read(defaultSafeBoxNumberProvider.notifier).refresh();
      await ref.read(walletsListProvider.notifier).loadWallets(safeBoxNumber: currentSafeNumber);

      if (context.mounted) {
        await AppNavigator.pushWithFader(
          context,
          RouteNames.onboardingStepEleven,
          arguments: OnboardingStepElevenArguments(
            fromRestore: widget.fromRestore,
            pinCode: widget.pinCode,
            isLegacyMode: _isLegacy,
          ),
        );
      }
    } catch (e) {
      log.e('Error during safe creation flow: $e');

      if (safeJustCreated) {
        await _cleanupFailedCreation();
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Helper methods
  // ---------------------------------------------------------------------------

  Future<bool> _createSafe() async {
    if (_isLegacy) {
      try {
        await ref
            .read(walletServiceProvider)
            .importLegacyWallet(
              salt: widget.legacySalt!,
              password: widget.legacyPassword!,
              pinCode: widget.pinCode,
              name: WalletNameService.defaultLegacy(),
            );
        return true;
      } catch (e) {
        if (!e.toString().contains('already been imported')) rethrow;
        log.i('Legacy wallet already imported - continuing with existing wallet');
        return false;
      }
    }

    final originalMnemonic = ref.read(mnemonicStateProvider).mnemonicResult?.displayMnemonic ?? '';
    if (originalMnemonic.isEmpty) return false;

    try {
      await ref
          .read(walletServiceProvider)
          .createSafe(mnemonic: originalMnemonic, pinCode: widget.pinCode, safeName: 'safeBoxName'.tr());
      return true;
    } catch (e) {
      if (!e.toString().contains('already exists') && !e.toString().contains('detect source language')) {
        rethrow;
      }
      log.i('Safe already exists or language detection failed - continuing with existing safe');
      return false;
    }
  }

  Future<bool> _scanAndImportWallets() async {
    final mnemonicState = ref.read(mnemonicStateProvider);
    ScanDerivationsResult scanStatus = ScanDerivationsResult.none;

    if (widget.scanDerivation && mnemonicState.mnemonicResult != null) {
      scanStatus = await ref.read(startScanProvider)(context, mnemonicState.mnemonicResult!);
    }

    switch (scanStatus) {
      case ScanDerivationsResult.timeout:
      case ScanDerivationsResult.error:
        return true;
      case ScanDerivationsResult.none:
      case ScanDerivationsResult.walletNotFound:
        await ref.read(walletServiceProvider).importRootWallet(pinCode: widget.pinCode);
        return false;
      default:
        return false;
    }
  }

  Future<WalletEntity?> _selectDefaultWallet() async {
    WalletEntity? defaultWallet;
    try {
      defaultWallet = await ref.read(idtyWalletAsyncProvider.future);
    } catch (e) {
      log.w('Error getting identity wallet during onboarding: $e');
    }

    final walletsList = ref.read(walletsListProvider).wallets;
    defaultWallet ??= walletsList.firstWhereOrNull((w) => w.number == 0);
    if (defaultWallet == null && walletsList.isNotEmpty) {
      defaultWallet = walletsList.first;
    }
    return defaultWallet;
  }

  Future<bool> _handleLegacyMigration(LegacyMigrationData migrationData, WalletEntity defaultWallet) async {
    if (migrationData.isToExistingSafe && migrationData.targetWalletAddress == null) {
      if (context.mounted) {
        Navigator.pushReplacementNamed(
          context,
          RouteNames.walletSelection,
          arguments: WalletSelectionArguments(migrationData: migrationData, pinCode: widget.pinCode),
        );
        return true;
      }
    } else {
      WalletEntity targetWallet = defaultWallet;
      if (migrationData.targetWalletAddress != null) {
        targetWallet = ref.read(walletServiceProvider).getWalletData(migrationData.targetWalletAddress!);
      }

      await _performLegacyMigrationWithProgress(context, ref, targetWallet, migrationData);
      ref.read(pendingLegacyMigrationProvider.notifier).clear();
    }
    return false;
  }

  void _clearSensitiveState() {
    ref.read(resetMnemonicStateProvider)();
    PinCodeService.debounceResetPinCode();
  }

  Future<void> _cleanupFailedCreation() async {
    try {
      final walletService = ref.read(walletServiceProvider);
      final safeNumber = walletService.defaultSafeBoxNumber;
      await walletService.deleteSafe(safeNumber);

      final safeBox = walletService.safeBox;
      if (!safeBox.isEmpty()) {
        final allSafes = safeBox.getAll();
        if (allSafes.isNotEmpty) {
          final maxSafeNumber = allSafes.map((s) => s.number).reduce((a, b) => a > b ? a : b);
          ref.read(defaultSafeBoxNumberProvider.notifier).setDefaultSafeBoxNumber(maxSafeNumber);
        }
      } else {
        ref.read(defaultSafeBoxNumberProvider.notifier).setDefaultSafeBoxNumber(-1);
      }
    } catch (e) {
      log.e('Error during safe cleanup: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Legacy migration helpers
  // ---------------------------------------------------------------------------

  Future<int> _performLegacyMigrationWithProgress(
    BuildContext context,
    WidgetRef ref,
    WalletEntity targetWallet,
    LegacyMigrationData migrationData,
  ) async {
    final walletService = ref.read(walletServiceProvider);
    var targetSafeNumber = targetWallet.safe.target!.number;

    try {
      final toKeypair = await walletService.getKeyPairFromAddress(
        address: targetWallet.address,
        pinCode: widget.pinCode,
      );

      ref.read(defaultSafeBoxNumberProvider.notifier).setDefaultSafeBoxNumber(targetSafeNumber);
      log.i('Switched to target safe $targetSafeNumber before migration');

      final transactionStream = ref
          .read(duniterServiceProvider)
          .migrateLegacyFromSeed(rawSeed: migrationData.rawSeed, toKeypair: toKeypair, withBalance: true);

      final broadcastStream = transactionStream.asBroadcastStream();

      TransactionState lastTxState = TransactionState.none;
      final stateSubscription = broadcastStream.listen((status) {
        lastTxState = status.state;
      });

      try {
        await navigateToTransactionProgress(
          context,
          transactionStatus: broadcastStream,
          transType: migrationData.hasIdentity ? 'identityMigration' : 'accountMigration',
          fromAddress: migrationData.fromAddress,
          toAddress: targetWallet.address,
        );
      } finally {
        await stateSubscription.cancel();
      }

      if (lastTxState == TransactionState.inBlock || lastTxState == TransactionState.finalized) {
        targetSafeNumber = await _deleteLegacySafeAndSyncState(
          walletService,
          migrationData.fromAddress,
          targetSafeNumber,
        );
      } else {
        log.w('Legacy safe NOT deleted: tx state was $lastTxState (expected inBlock or finalized)');
      }
    } catch (e) {
      log.e('Error during legacy migration with progress: $e');
    }
    return targetSafeNumber;
  }

  Future<int> _deleteLegacySafeAndSyncState(
    WalletService walletService,
    String legacyAddress,
    int targetSafeNumber,
  ) async {
    try {
      final legacyWallet = walletService.getWalletData(legacyAddress);
      final legacySafe = legacyWallet.safe.target;
      if (legacySafe == null) {
        log.w('Cannot delete legacy safe: safe relation is null for $legacyAddress');
        return targetSafeNumber;
      }

      await walletService.deleteSafe(legacySafe.number);
      log.i('Legacy safe ${legacySafe.number} deleted successfully after migration');

      if (targetSafeNumber != 0) {
        try {
          walletService.reassignSafeNumber(targetSafeNumber, 0);
          await walletService.renameSafe(0, 'safeBoxName'.tr());
          targetSafeNumber = 0;
          log.i('Target safe reassigned to number 0 after legacy migration');
        } catch (e) {
          log.w('Could not reassign safe number: $e');
        }
      }

      ref.read(defaultSafeBoxNumberProvider.notifier).setDefaultSafeBoxNumber(targetSafeNumber);

      await ref.read(walletsListProvider.notifier).loadWallets(safeBoxNumber: targetSafeNumber);
      log.i('Wallet list reloaded from target safe $targetSafeNumber after legacy cleanup');
    } catch (e) {
      log.e('Failed to delete legacy safe after migration: $e');
    }
    return targetSafeNumber;
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final pinLenght = widget.pinCode.isEmpty ? pinLength : widget.pinCode.length;
    GifView.preFetchImage(AssetImage('assets/onBoarding/gecko-clin.gif'));

    return PopScope(
      canPop: !_isProcessing,
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        appBar: GeckoAppBar('myPassword'.tr()),
        body: Stack(
          children: [
            SafeArea(
              child: ResponsiveCenter(
                maxWidth: 500,
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    ScaledSizedBox(height: isTall ? 25 : 5),
                    const BuildProgressBar(pagePosition: 9),
                    ScaledSizedBox(height: isTall ? 25 : 5),
                    BuildText(text: "geckoWillCheckPassword".tr()),
                    ScaledSizedBox(height: isTall ? 25 : 0),
                    const ScanDerivationsInfo(),
                    if (hasError)
                      Text(
                        "thisIsNotAGoodCode".tr(),
                        style: scaledTextStyle(
                          fontSize: 15,
                          color: context.geckoColors.danger,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    Consumer(
                      builder: (context, ref, _) {
                        return ref.read(durtProvider).isConnected
                            ? StatefulBuilder(
                                builder: (context, setState) {
                                  final pinCacheState = PinCodeService.isEnabled;
                                  return InkWell(
                                    key: keyCachePassword,
                                    onTap: () {
                                      setState(() {
                                        PinCodeService.toggle();
                                      });
                                    },
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          pinCacheState ? Icons.check_box : Icons.check_box_outline_blank,
                                          color: context.colorScheme.primary,
                                          size: scaleSize(22),
                                        ),
                                        ScaledSizedBox(width: 8),
                                        Text(
                                          'rememberPassword'.tr(),
                                          style: scaledTextStyle(
                                            fontSize: 14,
                                            color: context.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            : const SizedBox.shrink();
                      },
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: scaleSize(16)),
                        child: GeckoPinEntry(
                          key: keyPinForm,
                          controller: _pinController,
                          length: pinLenght,
                          enabled: !_isProcessing,
                          onCompleted: _onPinCompleted,
                          onChanged: (_) {
                            if (hasError) setState(() => hasError = false);
                          },
                          onErrorAnimationComplete: () {
                            setState(() => hasError = true);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isProcessing)
              AbsorbPointer(
                child: Container(
                  color: context.colorScheme.surface.withValues(alpha: 0.85),
                  child: SafeArea(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: context.colorScheme.primary, strokeWidth: scaleSize(3)),
                          ScaledSizedBox(height: 24),
                          Text('creatingSafe'.tr(), style: scaledTextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          ScaledSizedBox(height: 8),
                          Text(
                            'creatingSafePleaseWait'.tr(),
                            style: scaledTextStyle(fontSize: 14, color: context.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _onPinCompleted(String pin) async {
    if (_isProcessing) return;
    PinCodeService.pinCode = pin.toUpperCase();

    if (pin.toUpperCase() == widget.pinCode) {
      _pinController.triggerSuccess();
      await _handlePinConfirmed();
    } else {
      _pinController.triggerError();
    }
  }
}
