import 'package:durt2/durt2.dart' as d;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/certification_queue_provider.dart';
import 'package:gecko/utils.dart';

class ReadyCertificationModal extends ConsumerWidget {
  const ReadyCertificationModal({
    super.key,
    required this.pendingCert,
    required this.issuerAddress,
    required this.onCertify,
    required this.onViewQueue,
    required this.onDismiss,
  });

  final d.PendingCertification pendingCert;
  final String issuerAddress;
  final VoidCallback onCertify;
  final VoidCallback onViewQueue;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName =
        pendingCert.receiverName ?? pendingCert.receiverUid ?? getShortPubkey(pendingCert.receiverAddress);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              width: scaleSize(80),
              height: scaleSize(80),
              decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle),
              child: Icon(Icons.notifications_active, size: scaleSize(48), color: Colors.green.shade700),
            ),
            ScaledSizedBox(height: 20),

            // Title
            Text(
              'certificationReady'.tr(),
              style: scaledTextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green.shade700),
              textAlign: TextAlign.center,
            ),
            ScaledSizedBox(height: 12),

            // Message
            Text(
              'certificationReadyFor'.tr(args: [displayName]),
              style: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            ScaledSizedBox(height: 24),

            // Actions - Main buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // View queue button
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onViewQueue();
                  },
                  child: Text('viewQueue'.tr()),
                ),

                // Certify button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onCertify();
                  },
                  child: Text('certify'.tr()),
                ),
              ],
            ),
            ScaledSizedBox(height: 12),

            // Remind later - secondary action
            TextButton(
              onPressed: () {
                ref.read(readyCertificationNotifierProvider(issuerAddress).notifier).dismiss();
                onDismiss();
                Navigator.of(context).pop();
              },
              child: Text('remindLater'.tr(), style: scaledTextStyle(color: Colors.grey[600])),
            ),
          ],
        ),
      ),
    );
  }

  /// Show the modal as a dialog
  static Future<void> show({
    required BuildContext context,
    required d.PendingCertification pendingCert,
    required String issuerAddress,
    required VoidCallback onCertify,
    required VoidCallback onViewQueue,
    required VoidCallback onDismiss,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReadyCertificationModal(
        pendingCert: pendingCert,
        issuerAddress: issuerAddress,
        onCertify: onCertify,
        onViewQueue: onViewQueue,
        onDismiss: onDismiss,
      ),
    );
  }
}
