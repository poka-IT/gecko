// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' show IdtyStatus;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/membership_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/screens/myWallets/migrate_identity.dart';
import 'package:gecko/widgets/desktop/modals/transaction_progress_modal.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/widgets/commons/responsive_center.dart';
import 'package:gecko/models/membership_renewal.dart';

class ManageMembership extends ConsumerWidget {
  const ManageMembership({super.key, required this.address});
  final String address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: GeckoAppBar('manageMembership'.tr()),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 600,
          padding: EdgeInsets.zero,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: scaleSize(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScaledSizedBox(height: 20),
                  _buildRenewMembershipSection(context, ref),
                  Column(children: [migrateIdentity(context), revokeMyIdentity(context, ref)]),
                  ScaledSizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRenewMembershipSection(BuildContext context, WidgetRef ref) {
    final membershipAsync = ref.watch(membershipStatusProvider(address));

    return membershipAsync.when(
      data: (status) => renewMembership(context, ref, status),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget migrateIdentity(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: scaleSize(8)),
      child: InkWell(
        key: keyMigrateIdentity,
        onTap: () async {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return MigrateIdentityScreen(address: address);
              },
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
          child: Row(
            children: [
              Icon(Icons.change_circle_outlined, size: scaleSize(24), color: context.colorScheme.onSurface),
              ScaledSizedBox(width: 16),
              Text('Migrer mon identité', style: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSurface)),
            ],
          ),
        ),
      ),
    );
  }

  Widget revokeMyIdentity(BuildContext context, WidgetRef ref) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: scaleSize(8)),
      child: InkWell(
        key: keyRevokeIdty,
        onTap: () async {
          final answer = await showConfirmationDialog(
            context: context,
            message: 'areYouSureYouWantToRevokeIdentity'.tr(),
            type: ConfirmationDialogType.warning,
          );

          if (!answer) return;

          if (!await PinCodeService.askPinCode()) return;

          final keypair = await ref
              .read(walletServiceProvider)
              .getKeyPairFromAddress(address: address, pinCode: PinCodeService.pinCode);
          final transactionStatus = ref.read(duniterServiceProvider).revokeIdentity(keypair);

          Navigator.pop(context);

          navigateToTransactionProgress(
            homeContext,
            transactionStatus: transactionStatus,
            transType: 'revokeIdty',
            fromAddress: address,
            toAddress: address,
          );
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
          child: Row(
            children: [
              Image.asset('assets/skull_Icon.png', height: scaleSize(24)),
              ScaledSizedBox(width: 16),
              Text('revokeMyIdentity'.tr(), style: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSurface)),
            ],
          ),
        ),
      ),
    );
  }

  Widget renewMembership(BuildContext context, WidgetRef ref, status) {
    final info = MembershipRenewal.calculateRenewalInfo(status);
    if (info.expireDate == null && status.idtyStatus != IdtyStatus.expired) return const SizedBox.shrink();

    return Container(
      height: scaleSize(64),
      margin: EdgeInsets.symmetric(vertical: scaleSize(8)),
      child: InkWell(
        key: keyRenewMembership,
        onTap: info.canRenew
            ? () => MembershipRenewal.executeRenewal(context, ref, address, isExpired: info.isExpired)
            : !info.canRenew && info.disableReason != null
            ? () => _showDisableReasonPopup(context, info)
            : null,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: scaleSize(16)),
          child: Row(
            children: [
              Image.asset(
                'assets/medal.png',
                height: scaleSize(24),
                color: info.canRenew ? context.colorScheme.onSurface : Colors.grey[400],
              ),
              ScaledSizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'renewMembership'.tr(),
                      style: scaledTextStyle(
                        fontSize: 16,
                        color: info.canRenew ? context.colorScheme.onSurface : Colors.grey[500],
                      ),
                    ),
                    MembershipRenewal.buildExpirationText(info),
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
