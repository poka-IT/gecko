import 'dart:async';
import 'package:durt2/durt2.dart'
    show IdtyStatus, TransactionStatus, TransactionState, WalletEntity, WalletService, DuniterService;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/main.dart';
import 'package:gecko/providers/g1v1_migration.provider.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/stream_providers.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/screens/myWallets/migrate_identity.dart' show mapValidationErrors;
import 'package:gecko/services/legacy_migration_cleanup_service.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/services/snackbar_service.dart';
import 'package:gecko/services/wallet_name_service.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/balance_display.dart';
import 'package:gecko/widgets/bottom_sheets/mnemonic_challenge_sheet.dart';
import 'package:gecko/widgets/certifications.dart';
import 'package:gecko/widgets/desktop/desktop_modal.dart';
import 'package:gecko/widgets/desktop/modals/transaction_progress_modal.dart';
import 'package:gecko/widgets/idty_status.dart';

/// Opens the desktop legacy migration modal (Cesium v1 → v2 migration).
///
/// 3 steps: Credentials → Destination → Confirmation + Execute
Future<void> showDesktopLegacyMigrationModal(BuildContext context, {VoidCallback? onBack}) {
  return showDesktopModal(
    context: context,
    size: DesktopModalSize.medium,
    barrierDismissible: false,
    showCloseButton: false,
    contentPadding: EdgeInsets.zero,
    onBack: onBack,
    builder: (context) => const _LegacyMigrationContent(),
  );
}

class _LegacyMigrationContent extends ConsumerStatefulWidget {
  const _LegacyMigrationContent();

  @override
  ConsumerState<_LegacyMigrationContent> createState() => _LegacyMigrationContentState();
}

class _LegacyMigrationContentState extends ConsumerState<_LegacyMigrationContent> {
  Timer? _debounce;
  List<WalletEntity> _availableWallets = [];
  bool _isLoadingWallets = true;

  @override
  void initState() {
    super.initState();
    // Reset migration state after the widget tree is done building
    Future(() {
      ref.read(g1v1MigrationFlowProvider.notifier).reset();
      ref.read(g1v1MigrationUiProvider.notifier).reset();
      ref.read(csSaltControllerProvider).clear();
      ref.read(csPasswordControllerProvider).clear();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onCredentialChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 2000), () {
      final salt = ref.read(csSaltControllerProvider).text;
      final password = ref.read(csPasswordControllerProvider).text;
      if (salt.isNotEmpty && password.isNotEmpty) {
        ref.read(g1v1MigrationFlowProvider.notifier).convertAndFetchAccountInfo();
      }
    });
  }

  void _onFieldSubmitted() {
    final salt = ref.read(csSaltControllerProvider).text;
    final password = ref.read(csPasswordControllerProvider).text;
    if (salt.isNotEmpty && password.isNotEmpty) {
      _debounce?.cancel();
      ref.read(g1v1MigrationFlowProvider.notifier).convertAndFetchAccountInfo();
    }
  }

  Future<void> _loadAvailableWallets() async {
    setState(() => _isLoadingWallets = true);
    try {
      final flowState = ref.read(g1v1MigrationFlowProvider);

      // Desktop: load wallets from ALL safes, not just the active one
      final walletService = ref.read(walletServiceProvider);
      final allSafes = walletService.safeBox.getAll();
      final allWallets = allSafes.expand((safe) => safe.wallets).toList();

      final filtered = <WalletEntity>[];

      for (final wallet in allWallets) {
        if (flowState.hasIdentity) {
          final targetIdtyStatus = await ref.read(storageServiceProvider).getIdtyStatus(wallet.address);
          final targetHasIdentity = targetIdtyStatus != IdtyStatus.none && targetIdtyStatus != IdtyStatus.unknown;
          if (!targetHasIdentity) {
            filtered.add(wallet);
          }
        } else {
          filtered.add(wallet);
        }
      }

      if (mounted) {
        setState(() {
          _availableWallets = filtered;
          _isLoadingWallets = false;
        });
      }
    } catch (e) {
      log.e('Error loading available wallets: $e');
      if (mounted) setState(() => _isLoadingWallets = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(g1v1MigrationFlowProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context, flowState),
        _buildProgressBar(context, flowState),
        Flexible(child: _buildCurrentStep(context, flowState)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, G1v1MigrationFlowState flowState) {
    final titles = ['importIdPasswordAccount'.tr(), 'migration_destination_title'.tr(), 'migration_confirm_title'.tr()];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titles[flowState.currentStep],
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: context.colorScheme.onSurface),
            ),
          ),
          IconButton(
            onPressed: () {
              ref.read(g1v1MigrationFlowProvider.notifier).reset();
              ref.read(g1v1MigrationUiProvider.notifier).reset();
              ref.read(csSaltControllerProvider).clear();
              ref.read(csPasswordControllerProvider).clear();
              Navigator.of(context).pop();
            },
            icon: Icon(Icons.close_rounded, color: context.colorScheme.onSurface.withValues(alpha: 0.6)),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, G1v1MigrationFlowState flowState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= flowState.currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isActive ? context.colorScheme.primary : context.colorScheme.onSurface.withValues(alpha: 0.12),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context, G1v1MigrationFlowState flowState) {
    switch (flowState.currentStep) {
      case 0:
        return _buildCredentialsStep(context, flowState);
      case 1:
        return _buildDestinationStep(context, flowState);
      case 2:
        return _buildConfirmationStep(context, flowState);
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Step 0: Credentials ───

  Widget _buildCredentialsStep(BuildContext context, G1v1MigrationFlowState flowState) {
    final uiState = ref.watch(g1v1MigrationUiProvider);
    final saltController = ref.watch(csSaltControllerProvider);
    final passwordController = ref.watch(csPasswordControllerProvider);
    final canContinue = flowState.hasBalance && !flowState.isConverting;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Warning banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.geckoColors.warningContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.geckoColors.warning.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: context.geckoColors.warning, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'migration_credentials_subtitle'.tr(),
                    style: TextStyle(fontSize: 13, color: context.colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Salt field
          TextField(
            controller: saltController,
            obscureText: !uiState.isCesiumIDVisible,
            onChanged: (_) => _onCredentialChanged(),
            onSubmitted: (_) => _onFieldSubmitted(),
            decoration: InputDecoration(
              labelText: 'cesiumIdentifier'.tr(),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.person_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(uiState.isCesiumIDVisible ? Icons.visibility_off : Icons.visibility),
                onPressed: () => ref.read(g1v1MigrationUiProvider.notifier).toggleCesiumIDVisibility(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Password field
          TextField(
            controller: passwordController,
            obscureText: !uiState.isCesiumPasswordVisible,
            onChanged: (_) => _onCredentialChanged(),
            onSubmitted: (_) => _onFieldSubmitted(),
            decoration: InputDecoration(
              labelText: 'cesiumPassword'.tr(),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(uiState.isCesiumPasswordVisible ? Icons.visibility_off : Icons.visibility),
                onPressed: () => ref.read(g1v1MigrationUiProvider.notifier).toggleCesiumPasswordVisibility(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Account preview
          Expanded(child: _buildAccountPreview(context, flowState)),
          const SizedBox(height: 16),
          // Navigation
          Row(
            children: [
              TextButton(
                onPressed: () {
                  ref.read(g1v1MigrationFlowProvider.notifier).reset();
                  ref.read(g1v1MigrationUiProvider.notifier).reset();
                  ref.read(csSaltControllerProvider).clear();
                  ref.read(csPasswordControllerProvider).clear();
                  Navigator.of(context).pop();
                },
                child: Text('cancel'.tr()),
              ),
              const Spacer(),
              FilledButton(
                onPressed: canContinue
                    ? () {
                        _loadAvailableWallets();
                        ref.read(g1v1MigrationFlowProvider.notifier).nextStep();
                      }
                    : null,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                child: Text('continue'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountPreview(BuildContext context, G1v1MigrationFlowState flowState) {
    if (flowState.isConverting) {
      return Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 12),
            Text(
              'migration_converting'.tr(),
              style: TextStyle(fontSize: 13, color: context.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (!flowState.hasValidCredentials) {
      return Center(
        child: Text(
          'importLegacyDescription'.tr(),
          style: TextStyle(color: context.colorScheme.onSurface.withValues(alpha: 0.4)),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (flowState.errorMessage != null) {
      return Center(
        child: Text(flowState.errorMessage!, style: TextStyle(color: context.geckoColors.danger)),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // V1 / V2 addresses card
          _buildAddressesCard(context, flowState),
          const SizedBox(height: 12),
          // Account info card (empty, migrated, balance, identity)
          _buildAccountInfoCard(context, flowState),
        ],
      ),
    );
  }

  Widget _buildAddressesCard(BuildContext context, G1v1MigrationFlowState flowState) {
    final colorScheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // V1 pubkey
          _buildCopyableAddress(
            context,
            label: 'v1PublicKey'.tr(),
            value: flowState.v1Pubkey,
            shortValue: getShortPubkey(flowState.v1Pubkey),
          ),
          const SizedBox(height: 10),
          // V2 address
          _buildCopyableAddress(
            context,
            label: 'v2Address'.tr(),
            value: flowState.v2Address,
            shortValue: getShortPubkey(flowState.v2Address),
            highlighted: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableAddress(
    BuildContext context, {
    required String label,
    required String value,
    required String shortValue,
    bool highlighted = false,
  }) {
    final colorScheme = context.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Clipboard.setData(ClipboardData(text: value));
          SnackbarService.showAddressCopied(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: highlighted
                ? colorScheme.primary.withValues(alpha: 0.06)
                : colorScheme.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      shortValue,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.copy_rounded, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.35)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountInfoCard(BuildContext context, G1v1MigrationFlowState flowState) {
    switch (flowState.accountType) {
      case MigrationAccountType.empty:
        return _infoCard(
          color: context.geckoColors.danger,
          icon: Icons.error_outline,
          children: [
            Text('migration_account_empty'.tr(), style: TextStyle(fontSize: 13, color: context.geckoColors.dangerText)),
          ],
        );

      case MigrationAccountType.alreadyMigrated:
        final migration = flowState.migrationFromData!;
        final dateStr = DateFormat.yMMMd(safeLocale(context.locale.languageCode)).format(migration.migrationDate);
        return _infoCard(
          color: context.geckoColors.warning,
          icon: Icons.info_outline,
          children: [
            Text(
              'migration_account_already_migrated'.tr(),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.geckoColors.warningText),
            ),
            const SizedBox(height: 4),
            Text(
              'migration_account_already_migrated_details'.tr(args: [dateStr, getShortPubkey(migration.toAddress)]),
              style: TextStyle(fontSize: 12, color: context.geckoColors.warningText),
            ),
          ],
        );

      case MigrationAccountType.balanceOnly:
        return _infoCard(
          color: context.geckoColors.success,
          icon: Icons.check_circle_outline,
          children: [
            Text(
              'migration_account_has_balance'.tr(),
              style: TextStyle(fontSize: 13, color: context.geckoColors.successText),
            ),
            const SizedBox(height: 4),
            BalanceDisplay(
              value: flowState.sourceBalance?.transferableBalance ?? BigInt.zero,
              size: 14,
              fontWeight: FontWeight.w600,
              color: context.geckoColors.successText,
            ),
          ],
        );

      case MigrationAccountType.withIdentity:
        return _infoCard(
          color: context.geckoColors.success,
          icon: Icons.check_circle_outline,
          children: [
            Text(
              'migration_account_has_identity'.tr(),
              style: TextStyle(fontSize: 13, color: context.geckoColors.successText),
            ),
            const SizedBox(height: 4),
            BalanceDisplay(
              value: flowState.sourceBalance?.transferableBalance ?? BigInt.zero,
              size: 14,
              fontWeight: FontWeight.w600,
              color: context.geckoColors.successText,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                IdentityStatus(address: flowState.v2Address, color: context.geckoColors.successText),
                const SizedBox(width: 4),
                if (flowState.sourceIdentityName != null)
                  Text(
                    flowState.sourceIdentityName!,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.geckoColors.successText),
                  ),
                const SizedBox(width: 8),
                Certifications(address: flowState.v2Address, size: 12, color: context.geckoColors.successText),
              ],
            ),
          ],
        );

      case MigrationAccountType.unknown:
        return const SizedBox.shrink();
    }
  }

  Widget _infoCard({required Color color, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ),
        ],
      ),
    );
  }

  // ─── Step 1: Destination ───

  Widget _buildDestinationStep(BuildContext context, G1v1MigrationFlowState flowState) {
    final canContinue =
        flowState.hasTarget &&
        (flowState.createNewWallet || (flowState.migrationChecks != null && flowState.migrationChecks!.canMigrate));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            flowState.hasIdentity ? 'migration_destination_and_identity'.tr() : 'migration_destination_subtitle'.tr(),
            style: TextStyle(fontSize: 14, color: context.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoadingWallets
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: [
                      ..._availableWallets.map((wallet) => _buildWalletTile(context, wallet, flowState)),
                      _buildCreateNewWalletTile(context, flowState),
                    ],
                  ),
          ),
          // Validation errors
          if (flowState.migrationChecks != null && mapValidationErrors(flowState.migrationChecks!.errors).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                mapValidationErrors(flowState.migrationChecks!.errors),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: context.geckoColors.danger),
              ),
            ),
          const SizedBox(height: 16),
          // Navigation
          Row(
            children: [
              TextButton(
                onPressed: () => ref.read(g1v1MigrationFlowProvider.notifier).previousStep(),
                child: Text('cancel'.tr()),
              ),
              const Spacer(),
              FilledButton(
                onPressed: canContinue ? () => ref.read(g1v1MigrationFlowProvider.notifier).nextStep() : null,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                child: Text('continue'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletTile(BuildContext context, WalletEntity wallet, G1v1MigrationFlowState flowState) {
    final isSelected = flowState.selectedTargetWallet?.address == wallet.address;
    final safeName = wallet.safe.target != null ? WalletNameService.displayName(wallet.safe.target!.name) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => ref.read(g1v1MigrationFlowProvider.notifier).selectTargetWallet(wallet),
        child: Container(
          padding: const EdgeInsets.all(16),
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
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      WalletNameService.displayName(wallet.name),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${wallet.address.substring(0, 8)}...${wallet.address.substring(wallet.address.length - 8)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (safeName != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.colorScheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              safeName,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: context.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
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

  Widget _buildCreateNewWalletTile(BuildContext context, G1v1MigrationFlowState flowState) {
    final isSelected = flowState.createNewWallet;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => ref.read(g1v1MigrationFlowProvider.notifier).selectCreateNewWallet(),
        child: Container(
          padding: const EdgeInsets.all(16),
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
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'migration_create_new_wallet'.tr(),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'migration_create_new_wallet_hint'.tr(),
                      style: TextStyle(fontSize: 12, color: context.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.add_circle_outline, color: context.colorScheme.primary, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Step 2: Confirmation ───

  Widget _buildConfirmationStep(BuildContext context, G1v1MigrationFlowState flowState) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary card (FROM → TO)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // FROM
                        Text(
                          'migration_confirm_from'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.account_circle_outlined, size: 20, color: context.colorScheme.onSurface),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    getShortPubkey(flowState.v1Pubkey),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (flowState.sourceIdentityName != null)
                                    Text(
                                      flowState.sourceIdentityName!,
                                      style: TextStyle(fontSize: 12, color: context.colorScheme.onSurfaceVariant),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Arrow
                        Center(child: Icon(Icons.arrow_downward_rounded, size: 24, color: context.colorScheme.primary)),
                        const SizedBox(height: 12),
                        // TO
                        Text(
                          'migration_confirm_to'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.account_balance_wallet_outlined, size: 20, color: context.colorScheme.onSurface),
                            const SizedBox(width: 8),
                            Expanded(
                              child: flowState.createNewWallet
                                  ? Text(
                                      'migration_create_new_wallet'.tr(),
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                    )
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          WalletNameService.displayName(flowState.selectedTargetWallet?.name ?? ''),
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          getShortPubkey(flowState.selectedTargetWallet?.address ?? ''),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'monospace',
                                            color: context.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(color: context.colorScheme.outline.withValues(alpha: 0.2)),
                        const SizedBox(height: 8),
                        // Balance
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'migration_confirm_balance_label'.tr(),
                              style: TextStyle(fontSize: 13, color: context.colorScheme.onSurfaceVariant),
                            ),
                            BalanceDisplay(
                              value: flowState.sourceBalance?.transferableBalance ?? BigInt.zero,
                              size: 14,
                              fontWeight: FontWeight.w600,
                              color: context.colorScheme.onSurface,
                            ),
                          ],
                        ),
                        // Identity
                        if (flowState.hasIdentity) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'migration_confirm_identity_label'.tr(),
                                style: TextStyle(fontSize: 13, color: context.colorScheme.onSurfaceVariant),
                              ),
                              Text(
                                flowState.sourceIdentityName ?? '',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Warning card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.geckoColors.dangerContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.geckoColors.danger.withValues(alpha: 0.5), width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: context.geckoColors.danger, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'migration_confirm_warning'.tr(),
                            style: TextStyle(fontSize: 13, color: context.geckoColors.dangerText),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Navigation
          Row(
            children: [
              TextButton(
                onPressed: () => ref.read(g1v1MigrationFlowProvider.notifier).previousStep(),
                child: Text('cancel'.tr()),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => _onConfirm(context),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                child: Text(
                  'migration_confirm_button'.tr(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Migration execution ───

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

  Future<void> _onConfirm(BuildContext context) async {
    final flowState = ref.read(g1v1MigrationFlowProvider);
    final navigator = Navigator.of(context);

    // 1. Force-ask PIN (target wallet's safe) and capture it locally —
    //    the migration flow below involves a mnemonic challenge and
    //    multi-step transaction, way beyond the 1s debounce window.
    final pinCode = await PinCodeService.askPinCodeAndCapture(
      context,
      force: true,
      wallet: flowState.selectedTargetWallet,
    );
    if (pinCode == null) return;

    // 2. Determine target wallet address
    String targetAddress;
    if (flowState.createNewWallet) {
      final walletService = ref.read(walletServiceProvider);
      // generateNextDerivation throws on legacy safes; pick a non-legacy
      // (mnemonic) safe so migrating from a legacy default safe no longer
      // crashes with "Cannot generate derivations for legacy wallets".
      final targetSafeNumber = walletService.firstDerivableSafeNumber();
      if (targetSafeNumber == null) {
        if (context.mounted) {
          SnackbarService.showError(context, message: 'migrationNeedsTargetWallet'.tr());
        }
        return;
      }
      final targetWallet = await walletService.generateNextDerivation(
        pinCode: pinCode,
        safeBoxNumber: targetSafeNumber,
      );
      targetWallet.imagePath = 'assets/avatars/${targetWallet.number % 4}.png';
      await walletService.walletBox.putAsync(targetWallet);
      await ref.read(walletsListProvider.notifier).loadWallets();
      ref.read(walletActionsProvider.notifier).invalidateProviders();
      targetAddress = targetWallet.address;
    } else {
      targetAddress = flowState.selectedTargetWallet!.address;
    }

    // 3. Mnemonic challenge
    if (!context.mounted) return;
    if (!await showMnemonicChallenge(context: context, ref: ref, address: targetAddress, pinCode: pinCode)) {
      return;
    }

    // 4. Capture services and values
    final walletService = ref.read(walletServiceProvider);
    final duniterService = ref.read(duniterServiceProvider);
    final salt = ref.read(csSaltControllerProvider).text;
    final password = ref.read(csPasswordControllerProvider).text;
    final hasIdentity = flowState.hasIdentity;
    final fromAddress = flowState.v2Address;

    // 5. Guard: abort if credentials are missing
    if (salt.isEmpty || password.isEmpty || pinCode.isEmpty) {
      log.e('Migration aborted: missing credentials');
      return;
    }

    // 6. Clean up migration state
    ref.read(csSaltControllerProvider).clear();
    ref.read(csPasswordControllerProvider).clear();
    ref.read(g1v1MigrationUiProvider.notifier).reset();
    ref.read(g1v1MigrationFlowProvider.notifier).reset();

    // 7. Create transaction stream
    final broadcastStream = _performG1v1Migration(
      salt: salt,
      password: password,
      toAddress: targetAddress,
      pinCode: pinCode,
      walletService: walletService,
      duniterService: duniterService,
    ).asBroadcastStream();

    // 8. Listen to invalidate providers on success
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

        // Remove the orphan legacy safe imported for this account (if any) so
        // the user no longer lands on an empty 0 Ğ1 coffer after migrating
        // from an id/password (Cesium v1) account.
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

    // 9. Navigate to transaction progress
    try {
      navigator.pop();
      await showDesktopTransactionProgressModal(
        Gecko.navigatorContext!,
        transactionStatus: broadcastStream,
        transType: hasIdentity ? 'identityMigration' : 'accountMigration',
        fromAddress: fromAddress,
        toAddress: targetAddress,
      );
    } finally {
      await invalidateSubscription.cancel();
    }
  }
}
