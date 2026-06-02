import 'dart:async';
import 'package:durt2/durt2.dart' show TransactionStatus, TransactionState, WalletService, DuniterService, WalletEntity;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/main.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/g1v1_migration.provider.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/stream_providers.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:gecko/services/legacy_migration_cleanup_service.dart';
import 'package:gecko/services/snackbar_service.dart';
import 'package:gecko/widgets/desktop/desktop_utils.dart';
import 'package:gecko/widgets/desktop/modals/transaction_progress_modal.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/balance_display.dart';
import 'package:gecko/widgets/bottom_sheets/mnemonic_challenge_sheet.dart';

class StepConfirmation extends ConsumerWidget {
  const StepConfirmation({super.key});

  /// Perform the G1v1 migration with transaction stream.
  /// Services are passed as parameters because the stream may be consumed after widget disposal.
  static Stream<TransactionStatus> _performG1v1Migration({
    required String salt,
    required String password,
    required String toAddress,
    required String pinCode,
    required WalletService walletService,
    required DuniterService duniterService,
  }) async* {
    try {
      yield TransactionStatus(hash: '', state: TransactionState.pending);

      final toKeypair = await walletService.getKeyPairFromAddress(address: toAddress, pinCode: pinCode);

      yield* duniterService.migrateCsToV2(salt: salt, password: password, toKeypair: toKeypair, withBalance: true);
    } catch (e) {
      log.e('G1v1 migration error: $e');
      yield TransactionStatus(
        hash: '',
        state: TransactionState.error,
        errorMessage: 'migrationError'.tr(args: [e.toString()]),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowState = ref.watch(g1v1MigrationFlowProvider);
    final isSmallScreen = MediaQuery.of(context).size.height < 700;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(scaleSize(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'migration_confirm_title'.tr(),
                  style: scaledTextStyle(fontSize: isSmallScreen ? 18 : 20, fontWeight: FontWeight.bold),
                ),
                ScaledSizedBox(height: isSmallScreen ? 12 : 20),

                // Summary card
                Card(
                  color: context.colorScheme.surfaceContainer,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: EdgeInsets.all(scaleSize(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // FROM section
                        Text(
                          'migration_confirm_from'.tr(),
                          style: scaledTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        ScaledSizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.account_circle_outlined,
                              size: scaleSize(20),
                              color: context.colorScheme.onSurface,
                            ),
                            ScaledSizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    getShortPubkey(flowState.v1Pubkey),
                                    style: scaledTextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Monospace',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (flowState.sourceIdentityName != null)
                                    Text(
                                      flowState.sourceIdentityName!,
                                      style: scaledTextStyle(fontSize: 12, color: context.colorScheme.onSurfaceVariant),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        ScaledSizedBox(height: 12),

                        // Arrow separator
                        Center(
                          child: Icon(
                            Icons.arrow_downward_rounded,
                            size: scaleSize(24),
                            color: context.colorScheme.primary,
                          ),
                        ),
                        ScaledSizedBox(height: 12),

                        // TO section
                        Text(
                          'migration_confirm_to'.tr(),
                          style: scaledTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        ScaledSizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: scaleSize(20),
                              color: context.colorScheme.onSurface,
                            ),
                            ScaledSizedBox(width: 8),
                            Expanded(
                              child: flowState.createNewWallet
                                  ? Text(
                                      'migration_create_new_wallet'.tr(),
                                      style: scaledTextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                    )
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          flowState.selectedTargetWallet?.name ?? '',
                                          style: scaledTextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          getShortPubkey(flowState.selectedTargetWallet?.address ?? ''),
                                          style: scaledTextStyle(
                                            fontSize: 12,
                                            fontFamily: 'Monospace',
                                            color: context.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                        ScaledSizedBox(height: 12),

                        Divider(color: context.colorScheme.outline.withValues(alpha: 0.2)),
                        ScaledSizedBox(height: 8),

                        // Balance line
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'migration_confirm_balance_label'.tr(),
                              style: scaledTextStyle(fontSize: 13, color: context.colorScheme.onSurfaceVariant),
                            ),
                            BalanceDisplay(
                              value: flowState.sourceBalance?.transferableBalance ?? BigInt.zero,
                              size: 14,
                              fontWeight: FontWeight.w600,
                              color: context.colorScheme.onSurface,
                            ),
                          ],
                        ),

                        // Identity line
                        if (flowState.hasIdentity) ...[
                          ScaledSizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'migration_confirm_identity_label'.tr(),
                                style: scaledTextStyle(fontSize: 13, color: context.colorScheme.onSurfaceVariant),
                              ),
                              Text(
                                flowState.sourceIdentityName ?? '',
                                style: scaledTextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                ScaledSizedBox(height: isSmallScreen ? 12 : 16),

                // Warning card
                Card(
                  color: context.geckoColors.dangerContainer,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: context.geckoColors.danger.withValues(alpha: 0.5), width: 1),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(scaleSize(12)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: context.geckoColors.danger, size: scaleSize(20)),
                        ScaledSizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'migration_confirm_warning'.tr(),
                            style: scaledTextStyle(fontSize: 13, color: context.geckoColors.dangerText),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Navigation buttons
        Padding(
          padding: EdgeInsets.all(scaleSize(12)),
          child: Row(
            children: [
              TextButton(
                onPressed: () {
                  ref.read(g1v1MigrationFlowProvider.notifier).previousStep();
                },
                child: Text('cancel'.tr()),
              ),
              const Spacer(),
              SizedBox(
                height: scaleSize(isSmallScreen ? 40 : 44),
                child: ElevatedButton(
                  key: keyMigrationConfirmButton,
                  onPressed: () => _onConfirm(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'migration_confirm_button'.tr(),
                    style: scaledTextStyle(fontSize: isSmallScreen ? 14 : 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onConfirm(BuildContext context, WidgetRef ref) async {
    final flowState = ref.read(g1v1MigrationFlowProvider);

    // Capture NavigatorState early, before any async gap
    final navigator = Navigator.of(context);

    // 1. Always force-ask PIN for this irreversible operation and capture it
    //    locally — the migration spans many async steps well beyond the 1s
    //    `debounceResetPinCode` window.
    final pinCode = await PinCodeService.askPinCodeAndCapture(context, force: true);
    if (pinCode == null) return;

    // 2. Determine target wallet address
    String targetAddress;
    WalletEntity? targetWallet;

    if (flowState.createNewWallet) {
      // Create a new derivation. generateNextDerivation throws on legacy safes,
      // so target a non-legacy (mnemonic) safe — when the user's default safe
      // is the imported legacy account, derive into an existing mnemonic safe
      // instead of crashing with "Cannot generate derivations for legacy wallets".
      final walletService = ref.read(walletServiceProvider);
      final targetSafeNumber = walletService.firstDerivableSafeNumber();
      if (targetSafeNumber == null) {
        if (context.mounted) {
          SnackbarService.showError(context, message: 'migrationNeedsTargetWallet'.tr());
        }
        return;
      }
      targetWallet = await walletService.generateNextDerivation(pinCode: pinCode, safeBoxNumber: targetSafeNumber);
      targetWallet.imagePath = 'assets/avatars/${targetWallet.number % 4}.png';
      await walletService.walletBox.putAsync(targetWallet);

      // Reload wallets and invalidate safe data to include the new wallet
      await ref.read(walletsListProvider.notifier).loadWallets();
      ref.read(walletActionsProvider.notifier).invalidateProviders();

      targetAddress = targetWallet.address;
    } else {
      targetAddress = flowState.selectedTargetWallet!.address;
    }

    // 3. Mnemonic challenge on target wallet (pass pinCode explicitly to avoid race condition)
    if (!context.mounted) return;
    if (!await showMnemonicChallenge(context: context, ref: ref, address: targetAddress, pinCode: pinCode)) {
      return;
    }

    // 4. Capture services and values before navigation
    final walletService = ref.read(walletServiceProvider);
    final duniterService = ref.read(duniterServiceProvider);
    final salt = ref.read(csSaltControllerProvider).text;
    final password = ref.read(csPasswordControllerProvider).text;
    final hasIdentity = flowState.hasIdentity;
    final fromAddress = flowState.v2Address;

    // 5. Guard: abort if credentials are missing (should never happen, but prevents silent failure)
    if (salt.isEmpty || password.isEmpty || pinCode.isEmpty) {
      log.e(
        'Migration aborted: missing credentials (salt=${salt.isNotEmpty}, password=${password.isNotEmpty}, pin=${pinCode.isNotEmpty})',
      );
      return;
    }

    // 6. Clean up migration state before leaving
    ref.read(csSaltControllerProvider).clear();
    ref.read(csPasswordControllerProvider).clear();
    ref.read(g1v1MigrationUiProvider.notifier).reset();
    ref.read(g1v1MigrationFlowProvider.notifier).reset();

    // 7. Create transaction stream with captured values
    final transactionStream = _performG1v1Migration(
      salt: salt,
      password: password,
      toAddress: targetAddress,
      pinCode: pinCode,
      walletService: walletService,
      duniterService: duniterService,
    );

    // Convert to broadcast stream to allow multiple listeners
    final broadcastStream = transactionStream.asBroadcastStream();

    // 8. Listen to invalidate identity/certification providers on success
    // Capture container before navigation since ConsumerWidget has no mounted check
    // ignore: use_build_context_synchronously
    final container = ProviderScope.containerOf(context);
    var cleanupDone = false;
    final invalidateSubscription = broadcastStream.listen((status) {
      if (status.state == TransactionState.finalized || status.state == TransactionState.inBlock) {
        container.invalidate(persistentIdtyStatusStreamProvider(targetAddress));
        container.invalidate(persistentCertificationStreamProvider(targetAddress));
        container.invalidate(hybridIdtyStatusProvider(targetAddress));
        container.invalidate(hybridCertificationProvider(targetAddress));
        container.invalidate(hybridIdentityNameProvider(targetAddress));
        container.invalidate(idtyWalletAsyncProvider);
        container.invalidate(identityWalletsAsyncProvider);

        // Remove the now-empty legacy safe that was imported for this same
        // account (if any), so the user no longer lands on an orphan 0 Ğ1
        // coffer after migrating from an id/password (Cesium v1) account.
        // The migration source (fromAddress) is the v2-derived address of the
        // legacy account; if it was imported, its legacy safe is now empty.
        if (!cleanupDone && fromAddress.isNotEmpty && fromAddress != targetAddress) {
          cleanupDone = true;
          LegacyMigrationCleanupService.cleanupOrphanLegacySafe(
            container: container,
            walletService: walletService,
            migratedFromAddress: fromAddress,
            targetAddress: targetAddress,
          );
        }
      }
    });

    // 9. Replace migration flow with transaction screen
    try {
      // ignore: use_build_context_synchronously
      if (isDesktopLayout(navigator.context)) {
        navigator.pop();
        await showDesktopTransactionProgressModal(
          Gecko.navigatorContext!,
          transactionStatus: broadcastStream,
          transType: hasIdentity ? 'identityMigration' : 'accountMigration',
          fromAddress: fromAddress,
          toAddress: targetAddress,
        );
      } else {
        await navigator.pushReplacement(
          MaterialPageRoute(
            builder: (context) {
              return TransactionInProgressScreen(
                transactionStatus: broadcastStream,
                transType: hasIdentity ? 'identityMigration' : 'accountMigration',
                fromAddress: fromAddress,
                toAddress: targetAddress,
              );
            },
          ),
        );
      }
    } finally {
      await invalidateSubscription.cancel();
    }
  }
}
