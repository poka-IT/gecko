import 'package:durt2/durt2.dart' show IdtyStatus, WalletEntity;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/g1v1_migration.provider.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/screens/myWallets/migrate_identity.dart' show mapValidationErrors;

class StepDestination extends ConsumerStatefulWidget {
  const StepDestination({super.key});

  @override
  ConsumerState<StepDestination> createState() => _StepDestinationState();
}

class _StepDestinationState extends ConsumerState<StepDestination> {
  List<WalletEntity> _availableWallets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableWallets();
  }

  Future<void> _loadAvailableWallets() async {
    try {
      final flowState = ref.read(g1v1MigrationFlowProvider);
      final allWallets = ref.read(walletsListProvider).wallets;
      final filteredWallets = <WalletEntity>[];

      for (final wallet in allWallets) {
        if (flowState.hasIdentity) {
          // If source has identity, exclude wallets that already have an identity
          final targetIdtyStatus = await ref.read(storageServiceProvider).getIdtyStatus(wallet.address);
          final targetHasIdentity = targetIdtyStatus != IdtyStatus.none && targetIdtyStatus != IdtyStatus.unknown;
          if (!targetHasIdentity) {
            filteredWallets.add(wallet);
          }
        } else {
          filteredWallets.add(wallet);
        }
      }

      if (mounted) {
        setState(() {
          _availableWallets = filteredWallets;
          _isLoading = false;
        });
      }
    } catch (e) {
      log.e('Error loading available wallets: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(g1v1MigrationFlowProvider);
    final isSmallScreen = MediaQuery.of(context).size.height < 700;

    return Column(
      children: [
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: EdgeInsets.all(scaleSize(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'migration_destination_title'.tr(),
                        style: scaledTextStyle(fontSize: isSmallScreen ? 18 : 20, fontWeight: FontWeight.bold),
                      ),
                      ScaledSizedBox(height: 4),
                      Text(
                        flowState.hasIdentity
                            ? 'migration_destination_and_identity'.tr()
                            : 'migration_destination_subtitle'.tr(),
                        style: scaledTextStyle(
                          fontSize: isSmallScreen ? 13 : 14,
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      ScaledSizedBox(height: isSmallScreen ? 12 : 20),

                      Expanded(
                        child: ListView(
                          children: [
                            // Existing wallets
                            ..._availableWallets.map((wallet) => _buildWalletTile(context, ref, wallet, flowState)),

                            // Create new wallet option
                            _buildCreateNewWalletTile(context, ref, flowState),
                          ],
                        ),
                      ),

                      // Validation errors
                      if (flowState.migrationChecks != null &&
                          mapValidationErrors(flowState.migrationChecks!.errors).isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: scaleSize(8)),
                          child: Text(
                            mapValidationErrors(flowState.migrationChecks!.errors),
                            textAlign: TextAlign.center,
                            style: scaledTextStyle(fontSize: 12, color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
        ),

        // Navigation buttons
        _buildNavigationButtons(context, ref, flowState, isSmallScreen),
      ],
    );
  }

  Widget _buildWalletTile(BuildContext context, WidgetRef ref, WalletEntity wallet, G1v1MigrationFlowState flowState) {
    final isSelected = flowState.selectedTargetWallet?.address == wallet.address;

    return Container(
      margin: EdgeInsets.only(bottom: scaleSize(8)),
      child: InkWell(
        key: keySelectThisWallet(wallet.address),
        onTap: () {
          ref.read(g1v1MigrationFlowProvider.notifier).selectTargetWallet(wallet);
        },
        child: Container(
          padding: EdgeInsets.all(scaleSize(16)),
          decoration: BoxDecoration(
            color: isSelected
                ? context.colorScheme.primary.withValues(alpha: 0.1)
                : context.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? context.colorScheme.primary : Colors.transparent, width: 2),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? context.colorScheme.primary : Colors.grey,
                size: scaleSize(20),
              ),
              ScaledSizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallet.name ?? 'Wallet ${wallet.number}',
                      style: scaledTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                    ScaledSizedBox(height: 4),
                    Text(
                      '${wallet.address.substring(0, 8)}...${wallet.address.substring(wallet.address.length - 8)}',
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
        ),
      ),
    );
  }

  Widget _buildCreateNewWalletTile(BuildContext context, WidgetRef ref, G1v1MigrationFlowState flowState) {
    final isSelected = flowState.createNewWallet;

    return Container(
      margin: EdgeInsets.only(bottom: scaleSize(8)),
      child: InkWell(
        key: keyMigrationCreateNewWallet,
        onTap: () {
          ref.read(g1v1MigrationFlowProvider.notifier).selectCreateNewWallet();
        },
        child: Container(
          padding: EdgeInsets.all(scaleSize(16)),
          decoration: BoxDecoration(
            color: isSelected
                ? context.colorScheme.primary.withValues(alpha: 0.1)
                : context.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? context.colorScheme.primary : Colors.transparent, width: 2),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? context.colorScheme.primary : Colors.grey,
                size: scaleSize(20),
              ),
              ScaledSizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'migration_create_new_wallet'.tr(),
                      style: scaledTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                    ScaledSizedBox(height: 4),
                    Text(
                      'migration_create_new_wallet_hint'.tr(),
                      style: scaledTextStyle(fontSize: 12, color: context.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.add_circle_outline, color: context.colorScheme.primary, size: scaleSize(24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(
    BuildContext context,
    WidgetRef ref,
    G1v1MigrationFlowState flowState,
    bool isSmallScreen,
  ) {
    final canContinue =
        flowState.hasTarget &&
        (flowState.createNewWallet || (flowState.migrationChecks != null && flowState.migrationChecks!.canMigrate));

    return Padding(
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
              key: keyMigrationDestinationContinue,
              onPressed: canContinue ? () => ref.read(g1v1MigrationFlowProvider.notifier).nextStep() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colorScheme.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'continue'.tr(),
                style: scaledTextStyle(fontSize: isSmallScreen ? 14 : 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
