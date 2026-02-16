// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' as d;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/exceptions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/certification_queue_provider.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/certify/certification_transaction_helper.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/widgets/commons/profile_action_button.dart';

class ExecuteQueuedButton extends ConsumerStatefulWidget {
  const ExecuteQueuedButton({super.key, required this.address, required this.pendingCert, required this.issuerAddress});

  final String address;
  final d.PendingCertification pendingCert;
  final String issuerAddress;

  @override
  ConsumerState<ExecuteQueuedButton> createState() => _ExecuteQueuedButtonState();
}

class _ExecuteQueuedButtonState extends ConsumerState<ExecuteQueuedButton> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return ProfileActionButton(
      buttonKey: keyExecuteQueued,
      onTap: () => _executeCertification(context),
      backgroundColor: Colors.green.shade300,
      label: 'executeNow'.tr(),
      labelStyle: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: Colors.green.shade700),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(padding: EdgeInsets.all(scaleSize(4)), child: Image.asset('assets/gecko_certify.png')),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              width: scaleSize(20),
              height: scaleSize(20),
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Icon(Icons.check, size: scaleSize(14), color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeCertification(BuildContext context) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      // Capture provider references BEFORE async operations
      final walletService = ref.read(walletServiceProvider);
      final queueNotifier = ref.read(certificationQueueProvider(widget.issuerAddress).notifier);

      final walletName = widget.pendingCert.receiverName ?? widget.pendingCert.receiverUid;
      final displayName = walletName ?? getShortPubkey(widget.address);

      final message = '${'confirmCertification'.tr()}\n\n**$displayName**\n\n${getShortPubkey(widget.address)}';

      final result = await showConfirmationDialog(
        context: context,
        title: 'certification'.tr(),
        message: message,
        type: ConfirmationDialogType.question,
        checkboxLabel: 'certifyUniqueIdentity'.tr(),
      );

      if (!result) return;

      if (!await PinCodeService.askPinCode()) return;
      if (!context.mounted) return;

      try {
        // Use issuerAddress directly - it's the identity wallet address passed to this widget
        await CertificationTransactionHelper.executeCertification(
          context: context,
          ref: ref,
          issuerAddress: widget.issuerAddress,
          targetAddress: widget.address,
          onBeforeNavigate: () async {
            // Remove from queue with optimistic cooldown update
            await queueNotifier.removeExecutedCertification(widget.pendingCert.id);
            // Sync to CesiumPlus (we already have the PIN)
            await _syncToRemote(walletService, queueNotifier);
          },
        );
      } catch (e) {
        if (!context.mounted) {
          log.w('Context not mounted when error occurred: $e');
          return;
        }

        if (e is NotMemberException || e is CantBeCertException) {
          showConfirmationDialog(context: context, type: ConfirmationDialogType.error, message: e.toString());
        } else {
          log.e(e);
          showConfirmationDialog(context: context, type: ConfirmationDialogType.error, message: e.toString());
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Sync the queue to CesiumPlus
  Future<bool> _syncToRemote(dynamic walletService, CertificationQueueNotifier queueNotifier) async {
    try {
      final keyPair = await walletService.getKeyPairFromAddress(
        address: widget.issuerAddress,
        pinCode: PinCodeService.pinCode,
      );

      log.d('🔄 [ExecuteQueuedButton] Syncing queue to CesiumPlus...');
      return await queueNotifier.pushToRemote(keyPair.sign);
    } catch (e) {
      log.e('🔄 [ExecuteQueuedButton] Sync failed: $e');
      return false;
    }
  }
}
