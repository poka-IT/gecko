import 'package:durt2/durt2.dart' as d;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/screens/certification_queue_screen.dart';
import 'package:gecko/screens/profile_view.dart' show buttonFontSize;
import 'package:gecko/widgets/commons/profile_action_button.dart';

class InQueueButton extends ConsumerWidget {
  const InQueueButton({super.key, required this.pendingCert, required this.issuerAddress});

  final d.PendingCertification pendingCert;
  final String issuerAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formattedDate = pendingCert.expectedAvailableDate != null
        ? _formatEstimatedDate(pendingCert.expectedAvailableDate!)
        : null;

    return ProfileActionButton(
      buttonKey: keyInQueue,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CertificationQueueScreen(issuerAddress: issuerAddress)),
      ),
      backgroundColor: Colors.blue.shade100,
      label: 'inQueuePosition'.tr(args: [pendingCert.position.toString()]),
      labelStyle: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, color: Colors.blue.shade700),
      sublabel: formattedDate,
      sublabelStyle: scaledTextStyle(fontSize: buttonFontSize - 4, color: Colors.grey[600]),
      child: Stack(
        children: [
          Center(
            child: Icon(Icons.schedule, size: scaleSize(40), color: Colors.blue.shade700),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                '#${pendingCert.position}',
                style: scaledTextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _formatEstimatedDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.isNegative) {
      return 'readyToCertify'.tr();
    } else if (difference.inDays > 30) {
      return DateFormat.MMMd().format(date);
    } else if (difference.inDays > 0) {
      return 'days'.tr(args: [difference.inDays.toString()]);
    } else if (difference.inHours > 0) {
      return 'hours'.tr(args: [difference.inHours.toString(), '']);
    } else if (difference.inMinutes > 0) {
      return 'minutes'.tr(args: [difference.inMinutes.toString()]);
    } else {
      return null;
    }
  }
}
