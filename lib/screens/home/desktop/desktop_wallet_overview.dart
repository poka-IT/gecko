import 'package:durt2/durt2.dart' as d;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/safe_data_provider.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/screens/home/desktop/desktop_shared.dart';
import 'package:gecko/screens/onBoarding/import_choice_screen.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/services/wallet_name_service.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/cert_alert_dot.dart';
import 'package:gecko/widgets/certs_list.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/cached_avatar_image.dart';
import 'package:gecko/widgets/desktop/modals/legacy_migration_modal.dart';
import 'package:gecko/widgets/desktop/modals/onboarding_modal.dart';
import 'package:gecko/widgets/desktop/modals/restore_modal.dart';
import 'package:gecko/widgets/desktop/modals/safe_options_modal.dart';
import 'package:gecko/widgets/desktop/modals/wallet_options_modal.dart';
import 'package:gecko/widgets/drag_tule_action.dart';
import 'package:gecko/widgets/name_by_address.dart';

class DesktopWalletOverview extends ConsumerWidget {
  const DesktopWalletOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerGroups = ref.watch(safeWalletGroupsProvider);
    final safeGroups = providerGroups
        .map((g) => DesktopSafeWalletGroup(safe: g.safe, wallets: g.wallets, isCurrent: g.isCurrent))
        .toList(growable: false);
    final totalWallets = safeGroups.fold<int>(0, (sum, group) => sum + group.wallets.length);
    final hasSingleSafe = safeGroups.length <= 1;
    final hasSingleWallet = totalWallets == 1;

    return buildDesktopGlassCard(
      context,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: scaleSize(14),
                color: context.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                'myWalletsTitle'.tr(),
                style: scaledTextStyle(
                  fontSize: 13,
                  color: context.colorScheme.onSurface.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$totalWallets',
                  style: scaledTextStyle(fontSize: 11, color: context.colorScheme.primary, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
          const SizedBox(height: 10),
          if (safeGroups.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'noWalletFound'.tr(),
                  style: scaledTextStyle(fontSize: 12, color: context.colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ),
            )
          else if (hasSingleWallet)
            _buildSingleWalletOverview(context, ref, safeGroups.single, safeGroups.single.wallets.single)
          else if (hasSingleSafe)
            _buildSingleSafeWalletList(context, ref, safeGroups.single)
          else
            _buildMultiSafeWalletList(context, ref, safeGroups),
          if (safeGroups.isNotEmpty) ...[const SizedBox(height: 14), _buildSecondarySafeActions(context, safeGroups)],
        ],
      ),
    );
  }

  Widget _buildSingleWalletOverview(
    BuildContext context,
    WidgetRef ref,
    DesktopSafeWalletGroup group,
    d.WalletEntity wallet,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSafeHeader(context, ref, group, compact: true),
          const SizedBox(height: 12),
          _buildWalletRow(context, ref, wallet, isPrimary: true, isOnlyWallet: true),
        ],
      ),
    );
  }

  Widget _buildSingleSafeWalletList(BuildContext context, WidgetRef ref, DesktopSafeWalletGroup group) {
    return Column(
      children: [
        _buildSafeHeader(context, ref, group, compact: true),
        const SizedBox(height: 10),
        for (final wallet in group.wallets)
          _buildWalletRow(context, ref, wallet, isPrimary: _isPrimaryWallet(group.wallets, wallet)),
      ],
    );
  }

  Widget _buildMultiSafeWalletList(BuildContext context, WidgetRef ref, List<DesktopSafeWalletGroup> groups) {
    return Column(
      children: [
        for (var i = 0; i < groups.length; i++) ...[
          _buildSafeSection(context, ref, groups[i]),
          if (i != groups.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildSafeSection(BuildContext context, WidgetRef ref, DesktopSafeWalletGroup group) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colorScheme.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: group.isCurrent
              ? context.colorScheme.primary.withValues(alpha: 0.16)
              : context.colorScheme.outline.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          _buildSafeHeader(context, ref, group),
          const SizedBox(height: 10),
          for (final wallet in group.wallets)
            _buildWalletRow(context, ref, wallet, isPrimary: _isPrimaryWallet(group.wallets, wallet)),
        ],
      ),
    );
  }

  Widget _buildSafeHeader(BuildContext context, WidgetRef ref, DesktopSafeWalletGroup group, {bool compact = false}) {
    final safeLabel = WalletNameService.displayName(group.safe.name);

    final iconAndName = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 38 : 34,
          height: compact ? 38 : 34,
          decoration: BoxDecoration(
            color: group.isCurrent
                ? context.colorScheme.primary.withValues(alpha: 0.14)
                : context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.inventory_2_outlined,
            color: group.isCurrent ? context.colorScheme.primary : context.colorScheme.onSurface.withValues(alpha: 0.7),
            size: compact ? 20 : 18,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                safeLabel,
                overflow: TextOverflow.ellipsis,
                style: scaledTextStyle(
                  fontSize: compact ? 14 : 13,
                  color: context.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                group.wallets.length > 1
                    ? 'desktopWalletsCountLabel'.tr(args: ['${group.wallets.length}'])
                    : 'desktopWalletCountLabel'.tr(args: ['${group.wallets.length}']),
                style: scaledTextStyle(fontSize: 10.5, color: context.colorScheme.onSurface.withValues(alpha: 0.46)),
              ),
            ],
          ),
        ),
      ],
    );

    return Row(
      children: [
        Expanded(
          child: group.isCurrent
              ? iconAndName
              : MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => ref.read(walletActionsProvider.notifier).switchSafe(group.safe.number),
                    child: iconAndName,
                  ),
                ),
        ),
        if (group.isCurrent)
          Tooltip(
            message: 'activeSafeTooltip'.tr(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: context.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'identityActive'.tr(),
                style: scaledTextStyle(fontSize: 10, color: context.colorScheme.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        if (!group.isCurrent)
          Tooltip(
            message: 'setActiveSafe'.tr(),
            child: SizedBox(
              width: 28,
              height: 28,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => ref.read(walletActionsProvider.notifier).switchSafe(group.safe.number),
                  child: Icon(
                    Icons.radio_button_unchecked,
                    size: 16,
                    color: context.colorScheme.onSurface.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(width: 4),
        _buildAddDerivationButton(context, ref, safeNumber: group.safe.number),
        const SizedBox(width: 2),
        SizedBox(
          width: 28,
          height: 28,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => showDesktopSafeOptionsModal(context, ref, safeNumber: group.safe.number),
              child: Icon(
                Icons.settings_rounded,
                size: 16,
                color: context.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCreateOrRestoreMenu(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (renderBox == null || overlay == null) return;

    final position = renderBox.localToGlobal(Offset.zero, ancestor: overlay);
    final size = renderBox.size;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + size.height,
        overlay.size.width - position.dx - size.width,
        0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          value: 'create',
          child: Row(
            children: [
              Icon(Icons.add_circle_outline_rounded, size: 18, color: context.colorScheme.primary),
              const SizedBox(width: 10),
              Text('createSafe'.tr()),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'restore',
          child: Row(
            children: [
              Icon(Icons.key_rounded, size: 18, color: context.colorScheme.primary),
              const SizedBox(width: 10),
              Text('restoreWallet'.tr()),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'create') {
        if (!context.mounted) return;
        showDesktopOnboardingModal(context);
      } else if (value == 'restore') {
        if (!context.mounted) return;
        showDesktopRestoreModal(context);
      }
    });
  }

  Widget _buildAddDerivationButton(BuildContext context, WidgetRef ref, {required int safeNumber}) {
    final derivationState = ref.watch(derivationStateProvider);

    return SizedBox(
      width: 28,
      height: 28,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: derivationState.isLoading
              ? null
              : () async {
                  final walletService = ref.read(walletServiceProvider);
                  final wallets = walletService.getWalletDataList(safeNumber);
                  if (wallets.isEmpty) return;
                  final capturedPin = await PinCodeService.askPinCodeAndCapture(context, wallet: wallets.first);
                  if (capturedPin == null) return;
                  final lastNum = wallets.last.number;
                  final name = WalletNameService.defaultN(lastNum + 2);
                  await ref
                      .read(walletActionsProvider.notifier)
                      .generateNewDerivation(name, pinCode: capturedPin, safeNumber: safeNumber);
                },
          child: derivationState.isLoading
              ? Padding(
                  padding: const EdgeInsets.all(4),
                  child: CircularProgressIndicator(strokeWidth: 2, color: context.colorScheme.primary),
                )
              : Icon(Icons.add_rounded, size: 18, color: context.colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildSecondarySafeActions(BuildContext context, List<DesktopSafeWalletGroup> groups) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildSecondaryActionButton(
          context,
          icon: Icons.add_circle_outline_rounded,
          label: 'addNewSafe'.tr(),
          onTap: () => _showCreateOrRestoreMenu(context),
        ),
        if (ImportChoiceScreen.enableLegacyLogin)
          _buildSecondaryActionButton(
            context,
            iconWidget: SvgPicture.asset(
              'assets/cesium_bw2.svg',
              height: 16,
              colorFilter: ColorFilter.mode(context.colorScheme.onSurface.withValues(alpha: 0.72), BlendMode.srcIn),
            ),
            label: 'importIdPasswordAccount'.tr(),
            onTap: () => showDesktopLegacyMigrationModal(context),
          ),
      ],
    );
  }

  Widget _buildSecondaryActionButton(
    BuildContext context, {
    IconData? icon,
    Widget? iconWidget,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget ?? Icon(icon, size: 16, color: context.colorScheme.onSurface.withValues(alpha: 0.72)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: scaledTextStyle(
                    fontSize: 11,
                    color: context.colorScheme.onSurface.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isPrimaryWallet(List<d.WalletEntity> wallets, d.WalletEntity wallet) {
    if (wallets.isEmpty) return false;
    final primary = wallets.firstWhere((candidate) => candidate.derivation == null, orElse: () => wallets.first);
    return primary.address == wallet.address;
  }

  Widget _buildWalletRow(
    BuildContext context,
    WidgetRef ref,
    d.WalletEntity wallet, {
    bool isPrimary = false,
    bool isOnlyWallet = false,
  }) {
    final idtyStatus = ref.watch(safeWalletIdtyStatusProvider(wallet.address));
    final dragState = ref.watch(dragDropProvider);
    final isDraggingAnotherWallet = dragState.dragAddress != null && dragState.dragAddress!.address != wallet.address;
    final isHoveredTarget = dragState.lastFlyBy?.address == wallet.address && isDraggingAnotherWallet;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DragTuleAction(
        wallet: wallet,
        desktopMode: true,
        desktopChildBuilder: (dragHandle) => Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => showDesktopWalletOptionsModal(context, wallet: wallet),
            child: Ink(
              padding: EdgeInsets.symmetric(horizontal: isOnlyWallet ? 12 : 10, vertical: isOnlyWallet ? 12 : 10),
              decoration: BoxDecoration(
                color: isHoveredTarget
                    ? context.colorScheme.primary.withValues(alpha: 0.08)
                    : isPrimary
                    ? context.colorScheme.primary.withValues(alpha: 0.06)
                    : context.colorScheme.surface.withValues(alpha: 0.74),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  if (isPrimary || isHoveredTarget)
                    Container(
                      width: 3,
                      height: 32,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: context.colorScheme.primary.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: scaleSize(34),
                        height: scaleSize(34),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.08)),
                        ),
                        child: ClipOval(
                          child:
                              wallet.imagePath != null &&
                                  wallet.imagePath!.isNotEmpty &&
                                  !wallet.imagePath!.startsWith('assets/')
                              ? CachedAvatarImage(
                                  imagePath: wallet.imagePath!,
                                  fit: BoxFit.cover,
                                  isCircular: false,
                                  fallback: Image.asset('assets/avatars/${wallet.number % 4}.png', fit: BoxFit.cover),
                                )
                              : Image.asset('assets/avatars/${wallet.number % 4}.png', fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        right: -scaleSize(2),
                        top: -scaleSize(2),
                        child: CertAlertDot(address: wallet.address, direction: CertDirection.received, size: 9),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: NameByAddress(
                                wallet: wallet,
                                size: isOnlyWallet ? 13 : 12.5,
                                color: context.colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                                showCesiumPlusName: true,
                              ),
                            ),
                            if (isPrimary) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: context.colorScheme.primary.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'walletNameMain'.tr(),
                                  style: scaledTextStyle(
                                    fontSize: 9.5,
                                    color: context.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (idtyStatus != null && idtyStatus != d.IdtyStatus.none)
                              Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: _buildIdtyStatusDot(idtyStatus, context),
                              ),
                            Expanded(
                              child: Text(
                                getShortPubkey(wallet.address),
                                style: scaledTextStyle(
                                  fontSize: 9.5,
                                  color: context.colorScheme.onSurface.withValues(alpha: 0.42),
                                  fontFamily: 'Monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isDraggingAnotherWallet && !isHoveredTarget)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.arrow_downward_rounded,
                        size: 16,
                        color: context.colorScheme.onSurface.withValues(alpha: 0.22),
                      ),
                    ),
                  if (isHoveredTarget)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: context.colorScheme.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'pay'.tr(),
                          style: scaledTextStyle(
                            fontSize: 9.5,
                            color: context.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  Balance(address: wallet.address, size: 12, color: context.colorScheme.onSurface),
                  const SizedBox(width: 8),
                  dragHandle,
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 14, color: context.colorScheme.onSurface.withValues(alpha: 0.22)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdtyStatusDot(d.IdtyStatus status, BuildContext context) {
    final colors = context.geckoColors;
    final color = switch (status) {
      d.IdtyStatus.validated => colors.statusMember,
      d.IdtyStatus.confirmed => colors.statusConfirmed,
      d.IdtyStatus.created => colors.statusCreated,
      d.IdtyStatus.expired => colors.statusExpired,
      d.IdtyStatus.revoked => colors.statusRevoked,
      _ => colors.statusNone,
    };

    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 3, spreadRadius: 1)],
      ),
    );
  }
}
