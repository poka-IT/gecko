import 'package:durt2/durt2.dart' show IdtyStatus;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/membership_renewal.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/currency_provider.dart';
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
        final certAsync = ref.watch(smartCertificationStreamProvider(address));
        final currencyAsync = ref.watch(currencyDataProvider);

        return membershipAsync.when(
          data: (status) {
            // The cert-count gate must be applied here too: this card hosts a
            // "Renew" CTA that calls executeRenewal directly, so without the
            // gate the user could trigger a transaction that fails on chain
            // with cert.NotEnoughCertReceived.
            final info = MembershipRenewal.calculateRenewalInfo(
              status,
              receivedCertCount: certAsync.value?.receivedCount,
              minCertCount: currencyAsync.value?.wotParams.sigQtyRule,
            );

            // Pending evaluation (blue)
            if (info.hasPendingRenewal) {
              return _buildEvalPendingCard(context, ref, info);
            }

            // Expired membership (red)
            if (info.isExpired) {
              return _buildExpiredCard(context, ref, info);
            }

            // Expiring soon / renewal available
            if (info.shouldAlertExpiringSoon) {
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

  Widget _buildEvalPendingCard(BuildContext context, WidgetRef ref, RenewalInfo info) {
    final message = info.pendingEvalEstimate != null
        ? 'membershipEvalEstimate'.tr(args: [DateFormat('dd/MM/yyyy').format(info.pendingEvalEstimate!)])
        : 'membershipEvalPendingNoEstimate'.tr();

    return _AlertCardContainer(
      color: context.geckoColors.info,
      icon: Icons.hourglass_top,
      title: 'membershipEvalPending'.tr(),
      message: message,
    );
  }

  Widget _buildExpiredCard(BuildContext context, WidgetRef ref, RenewalInfo info) {
    final autoRevocText = info.autoRevocationDate != null
        ? '\n${'membershipAutoRevocationWarning'.tr(args: [DateFormat('dd/MM/yyyy').format(info.autoRevocationDate!)])}'
        : '';

    // When the identity is expired but cannot be renewed because of the
    // cert-count gate, we explain WHY in the message and hide the CTA.
    // (At this point hasPendingRenewal is necessarily false because the
    // pending case is handled by _buildEvalPendingCard above.)
    final isCertGated = info.disableReason == RenewalDisableReason.notEnoughCertsReceived;
    final baseMessage = isCertGated
        ? 'membershipNotEnoughCertifications'.tr(
            args: ['${info.receivedCertCount ?? 0}', '${info.minCertCount ?? 0}'],
          )
        : 'membershipExpiredRenewNow'.tr();

    return _AlertCardContainer(
      color: context.geckoColors.danger,
      icon: Icons.warning_rounded,
      title: 'membershipExpiredAlert'.tr(),
      message: '$baseMessage$autoRevocText',
      actionLabel: info.canRenew ? 'renewMembership'.tr() : null,
      onAction: info.canRenew
          ? () => MembershipRenewal.executeRenewal(context, ref, address, isExpired: true)
          : null,
    );
  }

  Widget _buildExpiringSoonCard(BuildContext context, WidgetRef ref, RenewalInfo info) {
    final String title;
    final String message;
    final Color color;
    final IconData icon;

    final isExpiringSoon =
        info.expireDate != null && !info.isExpired && info.expireDate!.difference(DateTime.now()).inDays <= 30;
    final isCertGated = info.disableReason == RenewalDisableReason.notEnoughCertsReceived;

    if (info.canRenew && !isExpiringSoon) {
      // Renewal available but not yet expiring soon
      title = 'membershipRenewalAvailable'.tr();
      message = 'membershipRenewalAvailableMessage'.tr();
      color = context.geckoColors.warning;
      icon = Icons.autorenew;
    } else {
      // Expiring soon — or cert-gated
      title = 'membershipExpiringSoon'.tr();
      if (isCertGated) {
        // Tell the user why we won't let them renew, instead of an opaque
        // greyed-out tile.
        message = 'membershipNotEnoughCertifications'.tr(
          args: ['${info.receivedCertCount ?? 0}', '${info.minCertCount ?? 0}'],
        );
      } else {
        message = info.expireDate != null
            ? 'membershipExpiringSoonMessage'.tr(args: [DateFormat('dd/MM/yyyy').format(info.expireDate!)])
            : 'membershipRenewalAvailableMessage'.tr();
      }
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
    // Use a darker shade for text readability on light container backgrounds.
    // HSLColor darkening produces a visually consistent result across hues.
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * 0.55).clamp(0.0, 1.0)).toColor();
  }
}
