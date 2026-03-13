import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/widgets/certs_counter.dart';
import 'package:gecko/widgets/certs_list.dart';
import 'package:gecko/widgets/desktop/desktop_modal.dart';
import 'package:gecko/widgets/distance_quality_section.dart';

/// Shows certifications (received/sent) inside a desktop modal with two-column layout.
Future<void> showDesktopCertificationsModal(BuildContext context, {required String address, required String username}) {
  return showDesktopModal(
    context: context,
    title: 'certificationsOf'.tr(args: [username]),
    size: DesktopModalSize.extraLarge,
    contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    builder: (context) => _DesktopCertificationsContent(address: address, username: username),
  );
}

class _DesktopCertificationsContent extends StatelessWidget {
  final String address;
  final String username;

  const _DesktopCertificationsContent({required this.address, required this.username});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DistanceQualitySection(address: address),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Received certifications column
              Expanded(
                child: _buildColumn(
                  context,
                  title: 'received'.tr(),
                  icon: Icons.call_received,
                  isReceived: true,
                  child: CertsList(address: address, direction: CertDirection.received),
                ),
              ),
              const SizedBox(width: 16),
              // Sent certifications column
              Expanded(
                child: _buildColumn(
                  context,
                  title: 'sent'.tr(),
                  icon: Icons.call_made,
                  isReceived: false,
                  child: CertsList(address: address, direction: CertDirection.sent),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColumn(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isReceived,
    required Widget child,
  }) {
    final iconColor = isReceived ? Colors.green.shade600 : Colors.blue.shade600;
    final iconBgColor = isReceived ? Colors.green.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1);
    final iconBorderColor = isReceived ? Colors.green.withValues(alpha: 0.3) : Colors.blue.withValues(alpha: 0.3);
    final sectionColor = isReceived ? Colors.green.withValues(alpha: 0.05) : Colors.blue.withValues(alpha: 0.05);

    return Container(
      decoration: BoxDecoration(
        color: sectionColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: scaleSize(28),
                  height: scaleSize(28),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconBgColor,
                    border: Border.all(color: iconBorderColor),
                  ),
                  child: Icon(icon, size: scaleSize(14), color: iconColor),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: scaledTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 6),
                CertsCounter(address: address, isSent: !isReceived),
              ],
            ),
          ),
          Divider(height: 1, color: context.colorScheme.outline.withValues(alpha: 0.1)),
          // List
          Expanded(child: child),
        ],
      ),
    );
  }
}
