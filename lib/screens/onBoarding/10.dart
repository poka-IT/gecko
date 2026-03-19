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
import 'package:gecko/widgets/gecko_pin_field.dart';
import 'package:gecko/widgets/scan_derivations_info.dart';
import 'package:gif_view/gif_view.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

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
  final formKey = GlobalKey<FormState>();
  Color? pinColor = const Color(0xFFA4B600);
  bool hasError = false;
  late final FocusNode pinFocus;
  late final TextEditingController enterPin;
  late final PinInputController _pinController;

  /// Blocks back navigation while safe creation/scan is in progress.
  bool _isProcessing = false;

  bool get _isLegacy => widget.legacySalt != null && widget.legacyPassword != null;

  @override
  void initState() {
    super.initState();
    pinFocus = FocusNode(debugLabel: 'pinFocusNode10');
    enterPin = TextEditingController();
    _pinController = PinInputController(textController: enterPin, focusNode: pinFocus);
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

  /// Main flow after PIN confirmation succeeds.
  /// Creates the safe, imports wallets, and navigates to the next screen.
  /// Wrapped in a global try-catch to guarantee cleanup on any failure.
  Future<void> _handlePinConfirmed() async {
    setState(() => _isProcessing = true);

    try {
      final migrationData = widget.legacyMigrationData ?? ref.read(pendingLegacyMigrationProvider);
      final isMigrationToExistingSafe = migrationData?.isToExistingSafe ?? false;

      // === FAST PATH: Migration to existing safe with known target ===
      // When WalletSelectionScreen navigates here with targetWalletAddress already set,
      // we skip safe creation, wallet scanning, and wallet selection entirely.
      // The target safe and wallet are already known — just do the migration.
      if (isMigrationToExistingSafe && migrationData?.targetWalletAddress != null) {
        await _handleDirectMigrationToExistingSafe(migrationData!);
        return;
      }

      // === NORMAL PATH: Safe creation + optional migration ===
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

  /// Direct migration to an existing safe: no safe creation, no wallet scanning.
  /// Called when WalletSelectionScreen already identified the target wallet.
  Future<void> _handleDirectMigrationToExistingSafe(LegacyMigrationData migrationData) async {
    try {
      final walletService = ref.read(walletServiceProvider);
      final targetWallet = walletService.getWalletData(migrationData.targetWalletAddress!);
      final targetSafeNumber = targetWallet.safe.target!.number;

      log.i('Direct migration to existing safe $targetSafeNumber, target wallet: ${migrationData.targetWalletAddress}');

      // Perform the on-chain migration (shows TransactionInProgressScreen)
      // Returns the possibly reassigned safe number (e.g. 0 after legacy deletion)
      final finalSafeNumber = await _performLegacyMigrationWithProgress(context, ref, targetWallet, migrationData);

      // Clear migration state
      ref.read(pendingLegacyMigrationProvider.notifier).clear();
      _clearSensitiveState();

      // Ensure Riverpod state is synced with the (possibly reassigned) safe
      ref.read(defaultSafeBoxNumberProvider.notifier).setDefaultSafeBoxNumber(finalSafeNumber);
      await ref.read(walletsListProvider.notifier).loadWallets(safeBoxNumber: finalSafeNumber);
      ref.read(walletActionsProvider.notifier).invalidateProviders();

      final walletCount = ref.read(walletsListProvider).wallets.length;
      log.i('Direct migration complete. Safe $finalSafeNumber loaded with $walletCount wallets');

      // Navigate to congratulations
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

  /// Normal safe creation flow: creates safe, imports wallets, handles optional migration.
  Future<void> _handleSafeCreationFlow(LegacyMigrationData? migrationData) async {
    bool safeJustCreated = false;

    try {
      // --- Step 1: Create safe ---
      safeJustCreated = await _createSafe();

      // Sync Riverpod provider with durt2's internal defaultSafeBoxNumber.
      ref.read(defaultSafeBoxNumberProvider.notifier).refresh();

      await ref.read(biometricProvider.notifier).refresh();
      final currentSafe = ref.read(walletServiceProvider).defaultSafeBoxNumber;
      PinCodeService.setAuthenticatedSafe(currentSafe);

      // --- Step 2: Import wallets (scan derivations or root import) ---
      if (!_isLegacy) {
        final exitedEarly = await _scanAndImportWallets();
        if (exitedEarly) {
          _clearSensitiveState();
          return;
        }
      }

      // --- Step 3: Load wallets and refresh providers ---
      final walletService = ref.read(walletServiceProvider);
      await ref.read(walletsListProvider.notifier).loadWallets(safeBoxNumber: currentSafe);

      ref.read(walletActionsProvider.notifier).invalidateProviders();
      ref.invalidate(idtyWalletAsyncProvider);
      ref.invalidate(identityWalletsAsyncProvider);

      _clearSensitiveState();

      // --- Step 4: Select default wallet ---
      final defaultWallet = await _selectDefaultWallet();
      if (defaultWallet != null) {
        await ref.read(walletServiceProvider).setDefaultAddress(defaultWallet.address);
      }

      // --- Step 5: Handle legacy migration (new safe flow only) ---
      if (migrationData != null) {
        // Get the best available target wallet for migration.
        // If defaultWallet is null (e.g. loadWallets returned empty despite import),
        // fall back to getting the root wallet directly from the safe.
        WalletEntity? migrationTarget = defaultWallet;
        if (migrationTarget == null) {
          // Fallback: get root wallet directly from ObjectBox if Riverpod list is empty
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

      // --- Step 6: Final reload and navigate to congratulations ---
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

  /// Creates the safe (mnemonic or legacy).
  /// Returns true if a new safe was actually created (false if it already existed).
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

  /// Scans derivations and imports wallets for mnemonic safes.
  /// Returns true if the scan handler already navigated away (timeout/error).
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
        // Always import root wallet in the normal path.
        // The fast path (_handleDirectMigrationToExistingSafe) handles the case
        // where the target safe already exists and has wallets.
        await ref.read(walletServiceProvider).importRootWallet(pinCode: widget.pinCode);
        return false;
      default:
        return false;
    }
  }

  /// Selects the best default wallet.
  /// Priority: identity member > confirmed > any identity > wallet #0 > first.
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

  /// Handles legacy migration if applicable.
  /// Returns true if the caller should return early (navigation happened).
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

  /// Clears mnemonic from memory and schedules PIN cache reset.
  void _clearSensitiveState() {
    ref.read(resetMnemonicStateProvider)();
    PinCodeService.debounceResetPinCode();
  }

  /// Deletes the newly created safe and restores the previous default safe number.
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

  /// Perform legacy migration with progress screen (used during onboarding).
  ///
  /// Returns the (possibly reassigned) target safe number after cleanup.
  /// The legacy safe deletion is done synchronously AFTER the TransactionInProgressScreen
  /// returns, not via an async stream listener. This avoids race conditions where
  /// concurrent loadWallets calls and async deletions could leave Riverpod state
  /// out of sync with the ObjectBox database.
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

      // Track the last transaction state to know if cleanup is safe
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

      // Synchronous cleanup: delete legacy safe only if tx succeeded.
      // Accept both inBlock (validated in a block) and finalized (block finalized by consensus).
      // The close button is enabled at inBlock, so users typically close the screen
      // before finalized arrives.
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

  /// Delete the legacy safe after successful migration, reassign safe number
  /// to 0 if needed, and sync Riverpod state.
  ///
  /// Returns the (possibly reassigned) target safe number.
  /// This must be called synchronously (not from a stream listener) to avoid
  /// race conditions with concurrent loadWallets calls.
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

      // After deleting the legacy safe, if the target safe is not number 0,
      // reassign it so it appears as "Coffre 1" (the first safe).
      if (targetSafeNumber != 0) {
        try {
          walletService.reassignSafeNumber(targetSafeNumber, 0);
          // Also rename to the default first safe name (without number suffix)
          await walletService.renameSafe(0, 'safeBoxName'.tr());
          targetSafeNumber = 0;
          log.i('Target safe reassigned to number 0 after legacy migration');
        } catch (e) {
          log.w('Could not reassign safe number: $e');
        }
      }

      // Sync Riverpod state with the database after deletion/reassignment.
      ref.read(defaultSafeBoxNumberProvider.notifier).setDefaultSafeBoxNumber(targetSafeNumber);

      // Reload wallets from the target safe to ensure the Riverpod state
      // reflects the current database state (legacy wallets removed).
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
    ref.watch(pinStateProvider);
    final pinLenght = widget.pinCode.isEmpty ? pinLength : widget.pinCode.length;
    GifView.preFetchImage(AssetImage('assets/onBoarding/gecko-clin.gif'));

    return PopScope(
      canPop: !_isProcessing,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          ref.read(pinStateProvider.notifier).setValid(false);
          ref.read(pinStateProvider.notifier).setLoading(true);
        }
      },
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        appBar: GeckoAppBar('myPassword'.tr()),
        body: Stack(
          children: [
            SafeArea(
              child: ResponsiveCenter(
                maxWidth: 500,
                padding: EdgeInsets.zero,
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      ScaledSizedBox(height: isTall ? 25 : 5),
                      const BuildProgressBar(pagePosition: 9),
                      ScaledSizedBox(height: isTall ? 25 : 5),
                      BuildText(text: "geckoWillCheckPassword".tr()),
                      ScaledSizedBox(height: isTall ? 25 : 0),
                      const ScanDerivationsInfo(),
                      Consumer(
                        builder: (context, ref, _) {
                          final pinState = ref.watch(pinStateProvider);
                          return Visibility(
                            visible: !pinState.isValid && !pinState.isLoading,
                            child: Text(
                              "thisIsNotAGoodCode".tr(),
                              style: scaledTextStyle(
                                fontSize: 15,
                                color: context.geckoColors.danger,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                      ScaledSizedBox(height: isTall ? 20 : 0),
                      pinForm(context, pinLenght, 1, 2),
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
                                        children: [
                                          ScaledSizedBox(height: isTall ? 30 : 0),
                                          const Spacer(),
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
                                          const Spacer(),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              : const Text('');
                        },
                      ),
                    ],
                  ),
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

  Widget pinForm(BuildContext context, int pinLenght, int walletNbr, int derivation) {
    return GeckoPinField(
      key: keyPinForm,
      pinController: _pinController,
      pinColor: pinColor,
      length: pinLenght,
      onCompleted: (pin) async {
        if (_isProcessing) return;
        PinCodeService.pinCode = pin.toUpperCase();
        ref.read(pinStateProvider.notifier).setPinLength(pinLenght);

        if (pin.toUpperCase() == widget.pinCode) {
          pinColor = context.geckoColors.success;
          ref.read(pinStateProvider.notifier).setLoading(false);
          ref.read(pinStateProvider.notifier).setValid(true);
          await _handlePinConfirmed();
        } else {
          hasError = true;
          ref.read(pinStateProvider.notifier).setLoading(false);
          ref.read(pinStateProvider.notifier).setValid(false);
          pinColor = context.geckoColors.danger;
          enterPin.text = '';
          pinFocus.requestFocus();
        }
      },
      onChanged: (value) {
        if (enterPin.text != '') {
          ref.read(pinStateProvider.notifier).setLoading(true);
        }
        if (pinColor != const Color(0xFFA4B600)) {
          pinColor = const Color(0xFFA4B600);
        }
        setState(() {});
      },
    );
  }
}
