import 'package:durt2/durt2.dart' show WalletEntity, IdtyStatus, SafeType;
import 'package:durt2/objectbox.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/services/wallet_name_service.dart';
import 'package:gecko/widgets/commons/build_text.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';

class WalletSelectionScreen extends ConsumerStatefulWidget {
  const WalletSelectionScreen({super.key, required this.migrationData, required this.pinCode});

  final LegacyMigrationData migrationData;
  final String pinCode;

  @override
  ConsumerState<WalletSelectionScreen> createState() => _WalletSelectionScreenState();
}

class _WalletSelectionScreenState extends ConsumerState<WalletSelectionScreen> {
  WalletEntity? selectedWallet;
  bool createNewWallet = false;
  List<WalletEntity> availableWallets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableWallets();
  }

  Future<void> _loadAvailableWallets() async {
    try {
      List<WalletEntity> allWallets;

      if (widget.migrationData.targetSafeNumber != null) {
        // Load wallets from the specified safe
        final walletService = ref.read(walletServiceProvider);
        final targetSafeNumber = widget.migrationData.targetSafeNumber!;
        final query = walletService.walletBox.query()
          ..link(WalletEntity_.safe, SafeEntity_.number.equals(targetSafeNumber));
        allWallets = query.build().find();
      } else {
        // Load wallets from the current safe using Riverpod provider
        allWallets = ref.read(walletsListProvider).wallets;
      }

      final filteredWallets = <WalletEntity>[];

      // Filter out the legacy wallet (source of migration) and only show wallets from the target safe
      for (final wallet in allWallets) {
        // Skip the legacy wallet we're migrating FROM
        if (wallet.address == widget.migrationData.fromAddress) {
          continue;
        }

        // Only include wallets from non-legacy safes
        if (wallet.safe.target?.safeType != SafeType.legacy) {
          if (widget.migrationData.hasIdentity) {
            // If legacy wallet has identity, only allow migration to wallets without identity
            final targetIdtyStatus = await ref.read(storageServiceProvider).getIdtyStatus(wallet.address);
            final targetHasIdentity = targetIdtyStatus != IdtyStatus.none && targetIdtyStatus != IdtyStatus.unknown;
            if (!targetHasIdentity) {
              filteredWallets.add(wallet);
            }
          } else {
            // If legacy wallet has no identity, can migrate to any wallet
            filteredWallets.add(wallet);
          }
        }
      }

      setState(() {
        availableWallets = filteredWallets;
        isLoading = false;
      });
    } catch (e) {
      log.e('Error loading available wallets: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: GeckoAppBar('selectTargetWallet'.tr()),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: EdgeInsets.all(scaleSize(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BuildText(
                      text: widget.migrationData.hasIdentity
                          ? 'selectWalletForIdentityMigration'.tr()
                          : 'selectWalletForMigration'.tr(),
                    ),
                    ScaledSizedBox(height: 20),

                    Expanded(
                      child: availableWallets.isEmpty
                          ? Center(
                              child: Text(
                                widget.migrationData.hasIdentity
                                    ? 'noWalletAvailableForIdentityMigration'.tr()
                                    : 'noWalletAvailableForMigration'.tr(),
                                textAlign: TextAlign.center,
                                style: scaledTextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                            )
                          : ListView(
                              children: [
                                // Existing wallets
                                ...availableWallets.map((wallet) => _buildWalletTile(wallet)),

                                // Create new wallet option
                                _buildCreateNewWalletTile(),
                              ],
                            ),
                    ),

                    // Continue button
                    if (selectedWallet != null || createNewWallet)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.only(top: scaleSize(20)),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: scaleSize(16)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _performMigration,
                          child: Text(
                            'continueMigration'.tr(),
                            style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildWalletTile(WalletEntity wallet) {
    final isSelected = selectedWallet?.address == wallet.address;

    return Container(
      margin: EdgeInsets.only(bottom: scaleSize(8)),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedWallet = wallet;
            createNewWallet = false;
          });
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
                      WalletNameService.displayName(wallet.name),
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

  Widget _buildCreateNewWalletTile() {
    final isSelected = createNewWallet;

    return Container(
      margin: EdgeInsets.only(bottom: scaleSize(8)),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedWallet = null;
            createNewWallet = true;
          });
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
                      'createNewWallet'.tr(),
                      style: scaledTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                    ScaledSizedBox(height: 4),
                    Text(
                      'createNewWalletDescription'.tr(),
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

  Future<void> _performMigration() async {
    try {
      WalletEntity targetWallet;

      if (createNewWallet) {
        // Create new derivation in the target safe
        final walletService = ref.read(walletServiceProvider);
        final targetSafeNumber = widget.migrationData.targetSafeNumber ?? walletService.defaultSafeBoxNumber;
        targetWallet = await walletService.generateNextDerivation(
          pinCode: widget.pinCode,
          safeBoxNumber: targetSafeNumber,
        );

        // Check if a wallet with this address already exists (can happen during legacy migration)
        final allWallets = walletService.walletBox.getAll();
        final existingWallet = allWallets
            .where((w) => w.address == targetWallet.address && w.id != targetWallet.id)
            .firstOrNull;

        if (existingWallet != null) {
          // Delete the duplicate we just created and use the existing one
          walletService.walletBox.remove(targetWallet.id);
          targetWallet = existingWallet;
        }
      } else {
        targetWallet = selectedWallet!;
      }

      // Navigate to step 10 with migration data
      if (mounted) {
        Navigator.pushNamed(
          context,
          RouteNames.onboardingStepTen,
          arguments: OnboardingStepTenArguments(
            pinCode: widget.pinCode,
            legacyMigrationData: LegacyMigrationData(
              fromAddress: widget.migrationData.fromAddress,
              rawSeed: widget.migrationData.rawSeed,
              hasIdentity: widget.migrationData.hasIdentity,
              isToExistingSafe: true,
              targetWalletAddress: targetWallet.address, // Add target wallet
            ),
          ),
        );
      }
    } catch (e) {
      log.e('Error performing migration: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('migrationError'.tr(args: [e.toString()])),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
