import 'package:durt2/durt2.dart' show IdtyStatus;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/main.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/membership_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/screens/myWallets/migrate_identity.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/widgets/desktop/modals/transaction_progress_modal.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/widgets/desktop/desktop_modal.dart';
import 'package:gecko/models/membership_renewal.dart';

/// Shows the manage membership screen inside a desktop modal.
Future<void> showDesktopManageMembershipModal(BuildContext context, {required String address}) {
  return showDesktopModal(
    context: context,
    title: 'manageMembership'.tr(),
    size: DesktopModalSize.small,
    contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
    builder: (context) => _ManageMembershipContent(address: address),
  );
}

class _ManageMembershipContent extends ConsumerWidget {
  const _ManageMembershipContent({required this.address});
  final String address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRenewMembershipSection(context, ref),
          _buildMigrateIdentity(context),
          _buildRevokeMyIdentity(context, ref),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRenewMembershipSection(BuildContext context, WidgetRef ref) {
    final membershipAsync = ref.watch(membershipStatusProvider(address));

    return membershipAsync.when(
      data: (status) {
        final info = MembershipRenewal.calculateRenewalInfo(status);
        if (info.expireDate == null && status.idtyStatus != IdtyStatus.expired) return const SizedBox.shrink();

        return _buildActionTile(
          context,
          icon: Icons.workspace_premium_outlined,
          iconColor: info.canRenew ? context.geckoColors.warning : Colors.grey[400]!,
          label: 'renewMembership'.tr(),
          subtitle: MembershipRenewal.buildExpirationText(info),
          onTap: info.canRenew
              ? () => MembershipRenewal.executeRenewal(context, ref, address, isExpired: info.isExpired)
              : info.disableReason != null
              ? () => _showDisableReasonPopup(context, info)
              : null,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildMigrateIdentity(BuildContext context) {
    return _buildActionTile(
      context,
      key: keyMigrateIdentity,
      icon: Icons.change_circle_outlined,
      label: 'Migrer mon identit\u00e9',
      onTap: () {
        Navigator.of(context).pop();
        Navigator.push(
          Gecko.navigatorContext!,
          MaterialPageRoute(builder: (context) => MigrateIdentityScreen(address: address)),
        );
      },
    );
  }

  Widget _buildRevokeMyIdentity(BuildContext context, WidgetRef ref) {
    return _buildActionTile(
      context,
      key: keyRevokeIdty,
      icon: Icons.dangerous_outlined,
      iconColor: context.geckoColors.danger,
      label: 'revokeMyIdentity'.tr(),
      labelColor: context.geckoColors.danger,
      onTap: () async {
        final answer = await showConfirmationDialog(
          context: context,
          message: 'areYouSureYouWantToRevokeIdentity'.tr(),
          type: ConfirmationDialogType.warning,
        );

        if (!answer) return;

        if (!context.mounted) return;
        if (!await PinCodeService.askPinCode(context, wallet: ref.read(walletServiceProvider).getWalletData(address)))
          return;

        final keypair = await ref
            .read(walletServiceProvider)
            .getKeyPairFromAddress(address: address, pinCode: PinCodeService.pinCode);
        final transactionStatus = ref.read(duniterServiceProvider).revokeIdentity(keypair);

        if (!context.mounted) return;
        Navigator.of(context).pop();

        navigateToTransactionProgress(
          Gecko.navigatorContext!,
          transactionStatus: transactionStatus,
          transType: 'revokeIdty',
          fromAddress: address,
          toAddress: address,
        );
      },
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    Key? key,
    required IconData icon,
    Color? iconColor,
    required String label,
    Color? labelColor,
    Widget? subtitle,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: scaleSize(22), color: iconColor ?? context.colorScheme.onSurface),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: scaledTextStyle(fontSize: 15, color: labelColor ?? context.colorScheme.onSurface),
                    ),
                    ?subtitle,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDisableReasonPopup(BuildContext context, RenewalInfo info) {
    final String message;
    switch (info.disableReason!) {
      case RenewalDisableReason.pendingEvaluation:
        message = info.pendingEvalEstimate != null
            ? 'membershipEvalEstimate'.tr(args: [DateFormat('dd/MM/yyyy').format(info.pendingEvalEstimate!)])
            : 'membershipEvalPendingNoEstimate'.tr();
      case RenewalDisableReason.renewalPeriodNotReached:
        message = info.renewalStartDate != null
            ? 'membershipRenewalNotYetAvailable'.tr(args: [DateFormat('dd/MM/yyyy').format(info.renewalStartDate!)])
            : 'membershipRenewalPeriodNotRespected'.tr();
      case RenewalDisableReason.identityRevoked:
        message = 'membershipCannotRenewRevoked'.tr();
      case RenewalDisableReason.identityNotMember:
      case RenewalDisableReason.identityExpired:
        message = 'membershipExpiredRenewNow'.tr();
    }

    showConfirmationDialog(
      context: context,
      title: 'membershipRenewalUnavailable'.tr(),
      message: message,
      type: ConfirmationDialogType.info,
      hideCancelButton: true,
    );
  }
}
