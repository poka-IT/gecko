import 'package:durt2/durt2.dart' as d;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/certification_queue_provider.dart';
import 'package:gecko/providers/identity_providers.dart';
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

  String _getDisplayName(String? hybridName) {
    // Priority: hybrid identity name > receiverName > receiverUid > short address
    if (hybridName != null && hybridName.isNotEmpty) return hybridName;
    if (pendingCert.receiverName != null && pendingCert.receiverName!.isNotEmpty) return pendingCert.receiverName!;
    if (pendingCert.receiverUid != null && pendingCert.receiverUid!.isNotEmpty) return pendingCert.receiverUid!;
    return getShortPubkey(pendingCert.receiverAddress);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hybridNameAsync = ref.watch(hybridIdentityNameProvider(pendingCert.receiverAddress));
    final displayName = hybridNameAsync.maybeWhen(
      data: (name) => _getDisplayName(name),
      orElse: () => _getDisplayName(null),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
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

              // Actions - Main buttons (stacked vertically to avoid overflow)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: scaleSize(12)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onCertify();
                  },
                  child: Text('certify'.tr(), style: scaledTextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              ScaledSizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: scaleSize(12))),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onViewQueue();
                  },
                  child: Text('viewQueue'.tr(), style: scaledTextStyle(fontSize: 15)),
                ),
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
