// ignore_for_file: file_names, use_build_context_synchronously

import 'package:durt2/durt2.dart' show WalletEntity, TransactionState, WalletService;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/commons/build_progress_bar.dart';
import 'package:gecko/widgets/commons/build_text.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
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
  /// Perform legacy migration with progress screen (used during onboarding)
  Future<void> _performLegacyMigrationWithProgress(
    BuildContext context,
    WidgetRef ref,
    WalletEntity targetWallet,
    LegacyMigrationData migrationData,
  ) async {
    try {
      // Get target keypair
      final toKeypair = await ref
          .read(walletServiceProvider)
          .getKeyPairFromAddress(address: targetWallet.address, pinCode: widget.pinCode);

      // Switch to target safe BEFORE starting migration
      final walletService = ref.read(walletServiceProvider);
      final targetSafeNumber = targetWallet.safe.target!.number;
      ref.read(defaultSafeBoxNumberProvider.notifier).setDefaultSafeBoxNumber(targetSafeNumber);
      log.i('Switched to target safe $targetSafeNumber before migration');

      // Store wallet service reference for later use
      _walletServiceForCleanup = walletService;
      _legacyAddressForCleanup = migrationData.fromAddress;

      // Perform migration using the new method
      final transactionStream = ref
          .read(duniterServiceProvider)
          .migrateLegacyFromSeed(rawSeed: migrationData.rawSeed, toKeypair: toKeypair, withBalance: true);

      // Convert to broadcast stream so it can be listened to multiple times
      final broadcastStream = transactionStream.asBroadcastStream();

      // Listen to transaction stream to detect success and delete legacy safe
      broadcastStream.listen((status) async {
        if ((status.state == TransactionState.finalized || status.state == TransactionState.inBlock) &&
            !_cleanupCompleted) {
          // Delete legacy safe after successful migration (but don't change safe again)
          await _deleteLegacySafeAfterMigration();
        }
      });

      // Navigate to transaction progress screen
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
    } catch (e) {
      log.e('Error during legacy migration with progress: $e');
      // Continue with onboarding even if migration fails
    }
  }

  /// Delete the legacy safe after successful migration
  Future<void> _deleteLegacySafeAfterMigration() async {
    try {
      if (_cleanupCompleted) {
        log.d('Cleanup already completed, skipping');
        return;
      }

      if (_walletServiceForCleanup == null || _legacyAddressForCleanup == null) {
        log.w('Cannot delete legacy safe: missing wallet service or address');
        return;
      }

      final walletService = _walletServiceForCleanup!;
      final legacyWallet = walletService.getWalletData(_legacyAddressForCleanup!);
      final legacySafe = legacyWallet.safe.target!;

      await walletService.deleteSafe(legacySafe.number);
      log.i('Legacy safe deleted successfully after migration');

      // Mark cleanup as completed
      _cleanupCompleted = true;

      // Clear references
      _walletServiceForCleanup = null;
      _legacyAddressForCleanup = null;
    } catch (e) {
      log.e('Failed to delete legacy safe after migration: $e');
    }
  }

  final formKey = GlobalKey<FormState>();
  Color? pinColor = const Color(0xFFA4B600);
  bool hasError = false;
  late final FocusNode pinFocus;

  // Variables for cleanup after migration
  WalletService? _walletServiceForCleanup;
  String? _legacyAddressForCleanup;
  bool _cleanupCompleted = false;
  late final TextEditingController enterPin;
  @override
  void initState() {
    super.initState();
    pinFocus = FocusNode(debugLabel: 'pinFocusNode10');
    enterPin = TextEditingController();
    // Reset any scan state when entering this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(resetScanProvider)();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch pinState to trigger rebuilds when state changes
    ref.watch(pinStateProvider);
    final pinLenght = widget.pinCode.isEmpty ? pinLength : widget.pinCode.length;
    GifView.preFetchImage(AssetImage('assets/onBoarding/gecko-clin.gif'));

    return PopScope(
      onPopInvokedWithResult: (_, _) {
        ref.read(pinStateProvider.notifier).setValid(false);
        ref.read(pinStateProvider.notifier).setLoading(true);
      },
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        appBar: GeckoAppBar('myPassword'.tr()),
        body: SafeArea(
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
      ),
    );
  }

  Widget pinForm(BuildContext context, int pinLenght, int walletNbr, int derivation) {
    // Scan state is now managed by Riverpod providers

    // Will get the current safe after safe creation - don't capture it too early

    return Form(
      key: formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 40),
        child: PinCodeTextField(
          key: keyPinForm,
          textCapitalization: TextCapitalization.characters,
          // autoDisposeControllers: false,
          focusNode: pinFocus,
          autoFocus: true,
          appContext: context,
          pastedTextStyle: TextStyle(color: Colors.green.shade600, fontWeight: FontWeight.bold),
          length: pinLenght,
          obscureText: true,
          obscuringCharacter: '*',
          useHapticFeedback: true,
          animationType: AnimationType.slide,
          animationDuration: const Duration(milliseconds: 40),
          validator: (v) {
            if (v!.length < pinLenght) {
              return "yourPasswordLengthIsX".tr(args: [pinLenght.toString()]);
            } else {
              return null;
            }
          },
          pinTheme: PinTheme(
            activeColor: pinColor,
            borderWidth: 4,
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(5),
            fieldHeight: scaleSize(47),
            fieldWidth: scaleSize(47),
            activeFillColor: Colors.black,
          ),
          showCursor: !kDebugMode,
          cursorColor: Colors.black,
          textStyle: const TextStyle(fontSize: 24, height: 1.6),
          backgroundColor: homeContext.colorScheme.surface,
          enableActiveFill: false,
          controller: enterPin,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          beforeTextPaste: (text) {
            return text != null && text.contains(RegExp(r'^[0-9]+$'));
          },
          boxShadows: const [BoxShadow(offset: Offset(0, 1), color: Colors.black12, blurRadius: 10)],
          onCompleted: (pin) async {
            PinCodeService.pinCode = pin.toUpperCase();
            ref.read(pinStateProvider.notifier).setPinLength(pinLenght);
            if (pin.toUpperCase() == widget.pinCode) {
              pinColor = Colors.green[500];
              ref.read(pinStateProvider.notifier).setLoading(false);
              ref.read(pinStateProvider.notifier).setValid(true);

              // Check if we're in a migration to existing safe flow (needed early)
              LegacyMigrationData? migrationData = widget.legacyMigrationData;
              migrationData ??= ref.read(pendingLegacyMigrationProvider);
              final isMigrationToExistingSafe = migrationData?.isToExistingSafe ?? false;

              // Create safe: legacy or mnemonic based on parameters
              if (widget.legacySalt != null && widget.legacyPassword != null) {
                // Create legacy safe
                try {
                  await ref
                      .read(walletServiceProvider)
                      .importLegacyWallet(
                        salt: widget.legacySalt!,
                        password: widget.legacyPassword!,
                        pinCode: widget.pinCode,
                        name: 'legacyWallet'.tr(),
                      );
                } catch (e) {
                  if (!e.toString().contains('already been imported')) {
                    rethrow;
                  }
                  log.i('Legacy wallet already imported - continuing with existing wallet');
                }
              } else {
                // Create mnemonic safe - but skip if it already exists (migration case)
                final mnemonicState = ref.read(mnemonicStateProvider);
                final originalMnemonic = mnemonicState.mnemonicResult?.displayMnemonic ?? '';

                if (originalMnemonic.isNotEmpty) {
                  try {
                    await ref
                        .read(walletServiceProvider)
                        .createSafe(mnemonic: originalMnemonic, pinCode: widget.pinCode, safeName: 'safeBoxName'.tr());
                  } catch (e) {
                    // If safe already exists (migration case), that's fine, continue
                    if (!e.toString().contains('already exists') && !e.toString().contains('detect source language')) {
                      rethrow;
                    }
                    log.i('Safe already exists or language detection failed - continuing with existing safe');
                  }
                }
              }

              // Refresh biometric provider after safe creation
              await ref.read(biometricProvider.notifier).refresh();

              // Get the current safe AFTER creation - this ensures we use the newly created safe
              final currentSafe = ref.read(walletServiceProvider).defaultSafeBoxNumber;

              // Handle wallet import differently for legacy vs mnemonic
              if (widget.legacySalt == null || widget.legacyPassword == null) {
                // Only do derivation scan for mnemonic safes
                final mnemonicState = ref.read(mnemonicStateProvider);
                ScanDerivationsResult scanStatus = ScanDerivationsResult.none;
                if (widget.scanDerivation && mnemonicState.mnemonicResult != null) {
                  scanStatus = await ref.read(startScanProvider)(context, mnemonicState.mnemonicResult!);
                }
                switch (scanStatus) {
                  case ScanDerivationsResult.none:
                  case ScanDerivationsResult.walletNotFound:
                    // Let Durt2 handle wallet creation and number assignment
                    // BUT skip if we're migrating to an existing safe (wallets already exist)
                    if (!isMigrationToExistingSafe) {
                      await ref.read(walletServiceProvider).importRootWallet(pinCode: widget.pinCode);
                    }
                    break;
                  case ScanDerivationsResult.timeout:
                  case ScanDerivationsResult.error:
                    return;
                  default:
                    break;
                }
              }
              // For legacy wallets, the wallet is already created by importLegacyWallet

              await ref.read(walletsListProvider.notifier).loadWallets(safeBoxNumber: currentSafe);

              // Invalidate identity providers to ensure fresh data after wallet import
              // This fixes the bug where identity status isn't recognized after import
              ref.read(walletActionsProvider.notifier).invalidateProviders();
              ref.invalidate(idtyWalletAsyncProvider);
              ref.invalidate(identityWalletsAsyncProvider);

              // Clear mnemonic state after safe creation
              ref.read(resetMnemonicStateProvider)();
              PinCodeService.debounceResetPinCode();

              // Set default wallet intelligently based on identity status
              // Priority: member > confirmed identity > any identity > wallet number 0 > first wallet
              WalletEntity? defaultWallet;

              try {
                // First try to get wallet with best identity status
                defaultWallet = await ref.read(idtyWalletAsyncProvider.future);
              } catch (e) {
                log.w('Error getting identity wallet during onboarding: $e');
                defaultWallet = null;
              }

              // Fallback to numeric priority if no identity wallet found
              final walletsList = ref.read(walletsListProvider).wallets;
              defaultWallet ??= walletsList.firstWhereOrNull((w) => w.number == 0);

              // Final fallback to first available wallet
              if (defaultWallet == null && walletsList.isNotEmpty) {
                defaultWallet = walletsList.first;
              }

              if (defaultWallet != null) {
                await ref.read(walletServiceProvider).setDefaultAddress(defaultWallet.address);
              }

              // Perform legacy migration if requested (from arguments or provider)
              // migrationData already defined above

              if (migrationData != null && defaultWallet != null) {
                if (migrationData.isToExistingSafe && migrationData.targetWalletAddress == null) {
                  // Migration to existing safe but no target wallet selected yet
                  // Navigate to wallet selection screen
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(
                      context,
                      RouteNames.walletSelection,
                      arguments: WalletSelectionArguments(migrationData: migrationData, pinCode: widget.pinCode),
                    );
                    return; // Don't continue to step 11
                  }
                } else {
                  // Migration to new safe OR migration to existing safe with target wallet selected
                  WalletEntity targetWallet = defaultWallet;
                  if (migrationData.targetWalletAddress != null) {
                    // Use the selected target wallet
                    targetWallet = ref.read(walletServiceProvider).getWalletData(migrationData.targetWalletAddress!);
                  }

                  await _performLegacyMigrationWithProgress(context, ref, targetWallet, migrationData);
                  // Clear the pending migration data
                  ref.read(pendingLegacyMigrationProvider.notifier).clear();
                }
              }

              // Force reload of wallets BEFORE navigation to ensure correct state
              final currentSafeNumber = ref.read(walletServiceProvider).defaultSafeBoxNumber;
              await ref.read(walletsListProvider.notifier).loadWallets(safeBoxNumber: currentSafeNumber);

              // Also invalidate Riverpod providers to ensure synchronization
              ref.invalidate(defaultWalletProvider);

              // Store context validity before async operation
              if (context.mounted) {
                // Determine if we're in legacy mode
                final isLegacyMode = widget.legacySalt != null && widget.legacyPassword != null;

                await AppNavigator.pushWithFader(
                  context,
                  RouteNames.onboardingStepEleven,
                  arguments: OnboardingStepElevenArguments(
                    fromRestore: widget.fromRestore,
                    pinCode: widget.pinCode,
                    isLegacyMode: isLegacyMode,
                  ),
                );
              }
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
            // Force widget rebuild for PIN color change
            setState(() {});
          },
        ),
      ),
    );
  }
}
