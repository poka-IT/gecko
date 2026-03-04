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
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:gecko/providers/biometric_provider.dart';
import 'package:gecko/providers/wallet_generation_providers.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/services/wallet_name_service.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/commons/build_progress_bar.dart';
import 'package:gecko/widgets/commons/build_text.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
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

  // Variables for cleanup after legacy migration
  WalletService? _walletServiceForCleanup;
  String? _legacyAddressForCleanup;
  bool _cleanupCompleted = false;

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
    bool safeJustCreated = false;

    try {
      final migrationData = widget.legacyMigrationData ?? ref.read(pendingLegacyMigrationProvider);
      final isMigrationToExistingSafe = migrationData?.isToExistingSafe ?? false;

      // --- Step 1: Create safe ---
      safeJustCreated = await _createSafe();

      // Sync Riverpod provider with durt2's internal defaultSafeBoxNumber.
      // createSafe()/importLegacyWallet() in durt2 update the configBox directly,
      // but the Riverpod state is not automatically updated. Without this sync,
      // idtyWalletAsyncProvider reads the old safe number and may return a wallet
      // from the wrong safe (e.g. the legacy wallet instead of the new mnemonic wallet),
      // causing migration to target the source wallet (OwnerKeyAlreadyUsed).
      ref.read(defaultSafeBoxNumberProvider.notifier).refresh();

      await ref.read(biometricProvider.notifier).refresh();
      final currentSafe = ref.read(walletServiceProvider).defaultSafeBoxNumber;

      // --- Step 2: Import wallets (scan derivations or root import) ---
      if (!_isLegacy) {
        final exitedEarly = await _scanAndImportWallets(isMigrationToExistingSafe);
        if (exitedEarly) {
          // Scan handler already cleaned up the safe and navigated to home.
          // Only clear sensitive data before returning.
          _clearSensitiveState();
          return;
        }
      }

      // --- Step 3: Load wallets and refresh providers ---
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

      // --- Step 5: Handle legacy migration ---
      if (migrationData != null && defaultWallet != null) {
        final shouldReturn = await _handleLegacyMigration(migrationData, defaultWallet);
        if (shouldReturn) return;
      }

      // --- Step 6: Final reload and navigate to congratulations ---
      final currentSafeNumber = ref.read(walletServiceProvider).defaultSafeBoxNumber;
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
      log.e('Error during safe setup: $e');

      if (safeJustCreated) {
        await _cleanupFailedCreation();
      }
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
  Future<bool> _scanAndImportWallets(bool isMigrationToExistingSafe) async {
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
        if (!isMigrationToExistingSafe) {
          await ref.read(walletServiceProvider).importRootWallet(pinCode: widget.pinCode);
        }
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

  /// Perform legacy migration with progress screen (used during onboarding)
  Future<void> _performLegacyMigrationWithProgress(
    BuildContext context,
    WidgetRef ref,
    WalletEntity targetWallet,
    LegacyMigrationData migrationData,
  ) async {
    try {
      final toKeypair = await ref
          .read(walletServiceProvider)
          .getKeyPairFromAddress(address: targetWallet.address, pinCode: widget.pinCode);

      final walletService = ref.read(walletServiceProvider);
      final targetSafeNumber = targetWallet.safe.target!.number;
      ref.read(defaultSafeBoxNumberProvider.notifier).setDefaultSafeBoxNumber(targetSafeNumber);
      log.i('Switched to target safe $targetSafeNumber before migration');

      _walletServiceForCleanup = walletService;
      _legacyAddressForCleanup = migrationData.fromAddress;

      final transactionStream = ref
          .read(duniterServiceProvider)
          .migrateLegacyFromSeed(rawSeed: migrationData.rawSeed, toKeypair: toKeypair, withBalance: true);

      final broadcastStream = transactionStream.asBroadcastStream();

      final cleanupSubscription = broadcastStream.listen((status) async {
        // Only cleanup at finalized (not inBlock) because execution errors
        // are only checked definitively at finalized. Cleaning up at inBlock
        // would delete the legacy safe before we know if the tx succeeded.
        if (status.state == TransactionState.finalized && !_cleanupCompleted) {
          await _deleteLegacySafeAfterMigration();
        }
      });

      try {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionInProgressScreen(
              transactionStatus: broadcastStream,
              transType: migrationData.hasIdentity ? 'identityMigration' : 'accountMigration',
              fromAddress: migrationData.fromAddress,
              toAddress: targetWallet.address,
            ),
          ),
        );
      } finally {
        await cleanupSubscription.cancel();
      }
    } catch (e) {
      log.e('Error during legacy migration with progress: $e');
    }
  }

  /// Delete the legacy safe after successful migration
  Future<void> _deleteLegacySafeAfterMigration() async {
    try {
      if (_cleanupCompleted) return;
      if (_walletServiceForCleanup == null || _legacyAddressForCleanup == null) {
        log.w('Cannot delete legacy safe: missing wallet service or address');
        return;
      }

      final walletService = _walletServiceForCleanup!;
      final legacyWallet = walletService.getWalletData(_legacyAddressForCleanup!);
      final legacySafe = legacyWallet.safe.target!;

      await walletService.deleteSafe(legacySafe.number);
      log.i('Legacy safe deleted successfully after migration');

      _cleanupCompleted = true;
      _walletServiceForCleanup = null;
      _legacyAddressForCleanup = null;
    } catch (e) {
      log.e('Failed to delete legacy safe after migration: $e');
    }
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
                            style: scaledTextStyle(fontSize: 15, color: Colors.red, fontWeight: FontWeight.w500),
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
                                            color: homeContext.colorScheme.onSurfaceVariant,
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
          pinColor = Colors.green[500];
          ref.read(pinStateProvider.notifier).setLoading(false);
          ref.read(pinStateProvider.notifier).setValid(true);
          await _handlePinConfirmed();
        } else {
          hasError = true;
          ref.read(pinStateProvider.notifier).setLoading(false);
          ref.read(pinStateProvider.notifier).setValid(false);
          pinColor = Colors.red[600];
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
