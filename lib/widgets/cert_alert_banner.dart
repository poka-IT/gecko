import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/cert_alert_provider.dart';
import 'package:gecko/widgets/certs_list.dart';

/// A discrete banner showing certification alert status for a wallet.
///
/// Displays a single-line colored banner when certifications need attention:
/// - Orange for expiring soon (≤30 days)
/// - Red for expired
/// - Nothing when all certs are healthy
///
/// Less prominent than [MembershipAlertCard] — just an icon + text line.
class CertAlertBanner extends ConsumerWidget {
  const CertAlertBanner({super.key, required this.address});

  /// The wallet address to check received certifications for.
  final String address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(certAlertStatusProvider((address: address, direction: CertDirection.received)));

    if (status == CertAlertStatus.none) {
      return const SizedBox.shrink();
    }

    final color = switch (status) {
      CertAlertStatus.expired => context.geckoColors.danger,
      CertAlertStatus.expiringSoon => context.geckoColors.warning,
      CertAlertStatus.none => Colors.transparent,
    };

    final icon = switch (status) {
      CertAlertStatus.expired => Icons.error_outline,
      CertAlertStatus.expiringSoon => Icons.schedule,
      CertAlertStatus.none => Icons.check,
    };

    final message = switch (status) {
      CertAlertStatus.expired => 'certBannerExpired'.tr(),
      CertAlertStatus.expiringSoon => 'certBannerExpiringSoon'.tr(),
      CertAlertStatus.none => '',
    };

    return Container(
      margin: EdgeInsets.symmetric(horizontal: scaleSize(20), vertical: scaleSize(4)),
      padding: EdgeInsets.symmetric(horizontal: scaleSize(12), vertical: scaleSize(8)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: scaleSize(16), color: color),
          ScaledSizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: scaledTextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
