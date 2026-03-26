import 'package:durt2/durt2.dart' show IdtyStatus;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/cert_alert_provider.dart';
import 'package:gecko/providers/stream_providers.dart';
import 'package:gecko/screens/certifications.dart';
import 'package:gecko/widgets/certs_list.dart';
import 'package:gecko/widgets/desktop/desktop_utils.dart';
import 'package:gecko/widgets/desktop/modals/certifications_modal.dart';

/// A discrete, tappable banner showing the most urgent certification alert.
///
/// Displays the specific person name and days left:
/// - Red: "Certification received from {name} has expired"
/// - Orange: "Certification received from {name} expires in {days} days"
/// - Nothing when all certs are healthy
///
/// Tapping opens the certifications list.
class CertAlertBanner extends ConsumerWidget {
  const CertAlertBanner({super.key, required this.address, this.username});

  final String address;
  final String? username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only show cert alerts for wallets that have an identity
    final idtyAsync = ref.watch(smartIdtyStatusStreamProvider(address));
    final idtyStatus = idtyAsync.asData?.value;
    if (idtyStatus == null || idtyStatus == IdtyStatus.none || idtyStatus == IdtyStatus.unknown) {
      return const SizedBox.shrink();
    }

    final detail = ref.watch(certAlertDetailProvider((address: address, direction: CertDirection.received)));

    if (detail.status == CertAlertStatus.none) {
      return const SizedBox.shrink();
    }

    final color = switch (detail.status) {
      CertAlertStatus.expired => context.geckoColors.danger,
      CertAlertStatus.expiringSoon => context.geckoColors.warning,
      CertAlertStatus.none => Colors.transparent,
    };

    final icon = switch (detail.status) {
      CertAlertStatus.expired => Icons.error_outline,
      CertAlertStatus.expiringSoon => Icons.schedule,
      CertAlertStatus.none => Icons.check,
    };

    final message = switch (detail.status) {
      CertAlertStatus.expired => 'homeAlertReceivedCertExpired'.tr(args: [detail.contactName ?? '?']),
      CertAlertStatus.expiringSoon => 'homeAlertReceivedCertExpiringSoon'.tr(
        args: [detail.contactName ?? '?', '${detail.daysLeft ?? '?'}'],
      ),
      CertAlertStatus.none => '',
    };

    return GestureDetector(
      onTap: () {
        if (isDesktopLayout(context)) {
          showDesktopCertificationsModal(context, address: address, username: username ?? '');
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CertificationsScreen(address: address, username: username ?? ''),
            ),
          );
        }
      },
      child: Container(
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
            Icon(Icons.chevron_right, size: scaleSize(16), color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
