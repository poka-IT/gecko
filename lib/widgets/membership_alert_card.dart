import 'package:durt2/durt2.dart' show IdtyStatus;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/membership_renewal.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/membership_providers.dart';
import 'package:gecko/providers/stream_providers.dart';
import 'package:gecko/providers/wallets_provider.dart';

/// Displays a contextual alert card on the wallet page when membership
/// needs attention: pending evaluation, expiring soon, or expired.
class MembershipAlertCard extends ConsumerWidget {
  const MembershipAlertCard({super.key, required this.address});

  final String address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = ref.watch(isOwnerProvider(address));
    if (!isOwner) return const SizedBox.shrink();

    final idtyStatusAsync = ref.watch(smartIdtyStatusStreamProvider(address));

    return idtyStatusAsync.when(
      data: (idtyStatus) {
        if (idtyStatus == IdtyStatus.none || idtyStatus == IdtyStatus.unknown) return const SizedBox.shrink();

        final membershipAsync = ref.watch(membershipStatusProvider(address));

        return membershipAsync.when(
          data: (status) {
            final info = MembershipRenewal.calculateRenewalInfo(status);

            // Pending evaluation (blue)
            if (info.hasPendingRenewal) {
              return _buildEvalPendingCard(context, ref, info);
            }

            // Expired membership (red)
            if (info.isExpired && idtyStatus == IdtyStatus.expired) {
              return _buildExpiredCard(context, ref, info);
            }

            // Show renewal banner only in the last third of membership period
            if (_shouldShowRenewalBanner(info)) {
              return _buildExpiringSoonCard(context, ref, info);
            }

            return const SizedBox.shrink();
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  bool _isExpiringSoon(RenewalInfo info) {
    if (info.expireDate == null || info.isExpired) return false;
    final daysUntilExpire = info.expireDate!.difference(DateTime.now()).inDays;
    return daysUntilExpire <= 30;
  }

  /// Show renewal banner only when in the last third of the membership period.
  /// renewalStartDate marks 2/3 of the period, so the last third is
  /// the second half of the [renewalStartDate, expireDate] window.
  bool _shouldShowRenewalBanner(RenewalInfo info) {
    if (info.isExpired && info.canRenew) return true;
    if (info.expireDate == null) return false;

    if (info.canRenew && info.renewalStartDate != null) {
      final renewalWindow = info.expireDate!.difference(info.renewalStartDate!);
      final bannerThreshold = renewalWindow ~/ 2;
      final timeUntilExpire = info.expireDate!.difference(DateTime.now());
      return timeUntilExpire <= bannerThreshold;
    }

    return _isExpiringSoon(info);
  }

  Widget _buildEvalPendingCard(BuildContext context, WidgetRef ref, RenewalInfo info) {
    final message = info.pendingEvalEstimate != null
        ? 'membershipEvalEstimate'.tr(args: [DateFormat('dd/MM/yyyy').format(info.pendingEvalEstimate!)])
        : 'membershipEvalPendingNoEstimate'.tr();

    return _AlertCardContainer(
      color: Colors.blue,
      icon: Icons.hourglass_top,
      title: 'membershipEvalPending'.tr(),
      message: message,
    );
  }

  Widget _buildExpiredCard(BuildContext context, WidgetRef ref, RenewalInfo info) {
    final autoRevocText = info.autoRevocationDate != null
        ? '\n${'membershipAutoRevocationWarning'.tr(args: [DateFormat('dd/MM/yyyy').format(info.autoRevocationDate!)])}'
        : '';

    return _AlertCardContainer(
      color: Colors.red,
      icon: Icons.warning_rounded,
      title: 'membershipExpiredAlert'.tr(),
      message: '${'membershipExpiredRenewNow'.tr()}$autoRevocText',
      actionLabel: 'renewMembership'.tr(),
      onAction: () => MembershipRenewal.executeRenewal(context, ref, address, isExpired: true),
    );
  }

  Widget _buildExpiringSoonCard(BuildContext context, WidgetRef ref, RenewalInfo info) {
    final String title;
    final String message;
    final Color color;
    final IconData icon;

    if (info.canRenew && !_isExpiringSoon(info)) {
      // Renewal available but not yet expiring soon
      title = 'membershipRenewalAvailable'.tr();
      message = 'membershipRenewalAvailableMessage'.tr();
      color = Colors.orange;
      icon = Icons.autorenew;
    } else {
      // Expiring soon
      title = 'membershipExpiringSoon'.tr();
      message = info.expireDate != null
          ? 'membershipExpiringSoonMessage'.tr(args: [DateFormat('dd/MM/yyyy').format(info.expireDate!)])
          : 'membershipRenewalAvailableMessage'.tr();
      color = Colors.deepOrange;
      icon = Icons.schedule;
    }

    return _AlertCardContainer(
      color: color,
      icon: icon,
      title: title,
      message: message,
      actionLabel: info.canRenew ? 'renewMembership'.tr() : null,
      onAction: info.canRenew ? () => MembershipRenewal.executeRenewal(context, ref, address) : null,
    );
  }
}

class _AlertCardContainer extends StatelessWidget {
  const _AlertCardContainer({
    required this.color,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: scaleSize(8), horizontal: scaleSize(20)),
      padding: EdgeInsets.all(scaleSize(16)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _darkColor, size: scaleSize(22)),
              ScaledSizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _darkColor),
                ),
              ),
            ],
          ),
          ScaledSizedBox(height: 10),
          Text(message, style: scaledTextStyle(fontSize: 14, color: _darkColor)),
          if (actionLabel != null && onAction != null) ...[
            ScaledSizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.autorenew, size: scaleSize(18)),
                label: Text(actionLabel!, style: scaledTextStyle(fontSize: 14, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.withValues(alpha: 0.85),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: scaleSize(10), horizontal: scaleSize(16)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: onAction,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color get _darkColor {
    // Use shade800 equivalent for text readability
    if (color == Colors.blue) return Colors.blue.shade800;
    if (color == Colors.red) return Colors.red.shade800;
    if (color == Colors.deepOrange) return Colors.deepOrange.shade800;
    return Colors.orange.shade800;
  }
}
