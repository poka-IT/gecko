import 'package:durt2/durt2.dart' as d;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/certification_queue_provider.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/stream_providers.dart';
import 'package:gecko/screens/profile_view.dart' show buttonFontSize;
import 'package:gecko/utils.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/services/snackbar_service.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/widgets/commons/profile_action_button.dart';

class AddToQueueButton extends ConsumerStatefulWidget {
  const AddToQueueButton({super.key, required this.address, required this.certState, required this.issuerAddress});

  final String address;
  final d.CertState certState;
  final String issuerAddress;

  @override
  ConsumerState<AddToQueueButton> createState() => _AddToQueueButtonState();
}

class _AddToQueueButtonState extends ConsumerState<AddToQueueButton> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    // Watch target identity status to determine certification type and trigger rebuilds
    // CRITICAL: Use 'unknown' as fallback, NOT 'none'!
    // 'none' means "no identity exists" which would show wrong label
    // 'unknown' means "loading/error" and should show generic certification label
    final targetIdtyStatusAsync = ref.watch(smartIdtyStatusStreamProvider(widget.address));
    final targetIdtyStatus = targetIdtyStatusAsync.value ?? d.IdtyStatus.unknown;

    // Watch certification exists to check if it's a renewal
    final certExistsAsync = ref.watch(certificationExistsProvider(widget.address));
    final certificationExists = certExistsAsync.value ?? false;

    // Determine the certification type and label
    final (label, certType) = _getLabelAndType(targetIdtyStatus, certificationExists);

    // Get current queue to calculate real estimated date based on position
    final queueAsync = ref.watch(certificationQueueProvider(widget.issuerAddress));
    final currentQueueLength = queueAsync.value?.queueLength ?? 0;
    final futurePosition = currentQueueLength + 1;

    // Calculate estimated date based on future position in queue
    final estimatedDate = _calculateEstimatedDate(futurePosition);
    final formattedDate = estimatedDate != null ? _formatEstimatedDate(estimatedDate) : null;

    return ProfileActionButton(
      buttonKey: keyAddToQueue,
      onTap: () => _showAddToQueueDialog(context, estimatedDate, certType),
      backgroundColor: const Color(0xffFFD58D),
      label: label,
      sublabel: formattedDate,
      sublabelStyle: scaledTextStyle(fontSize: buttonFontSize - 4, color: Colors.grey[600]),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(padding: EdgeInsets.all(scaleSize(4)), child: Image.asset('assets/gecko_certify.png')),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: scaleSize(20),
              height: scaleSize(20),
              decoration: BoxDecoration(
                color: context.geckoColors.warningText,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Icon(Icons.add, size: scaleSize(14), color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get the appropriate label and certification type based on target's identity status
  (String, d.CertificationType) _getLabelAndType(d.IdtyStatus targetIdtyStatus, bool certificationExists) {
    if (targetIdtyStatus == d.IdtyStatus.none) {
      // Target has no identity - this will be an invitation
      return ('scheduleInvitation'.tr(), d.CertificationType.invitation);
    } else if (certificationExists || widget.certState.status == d.CertStatus.canRenewIn) {
      // Certification already exists - this is a renewal
      return ('scheduleRenewal'.tr(), d.CertificationType.renewal);
    } else {
      // Standard certification
      return ('scheduleCertification'.tr(), d.CertificationType.certification);
    }
  }

  /// Calculate the estimated date when this certification will be processed
  /// based on the future position in the queue
  ///
  /// Handles two different scenarios:
  /// 1. mustWaitBeforeCert: Issuer's cooldown is active → use nextIssuableDate
  /// 2. canRenewIn: Renewal not yet possible → use duration
  ///
  /// The final date is the MAX of:
  /// - The constraint date (when this specific certification becomes possible)
  /// - The queue position date (based on certPeriod * position)
  DateTime? _calculateEstimatedDate(int futurePosition) {
    try {
      final storageService = ref.read(storageServiceProvider);
      final certPeriod = storageService.getCertPeriodDuration();
      final now = DateTime.now();

      // Determine the constraint date based on cert status
      DateTime constraintDate;

      if (widget.certState.status == d.CertStatus.canRenewIn && widget.certState.duration != null) {
        // Case: canRenewIn - renewal not yet possible for this specific pair
        // Prioritize the specific renewal duration over the issuer's global cooldown
        constraintDate = now.add(widget.certState.duration!);
      } else if (widget.certState.nextIssuableDate != null) {
        // Case: mustWaitBeforeCert - issuer's global cooldown
        constraintDate = widget.certState.nextIssuableDate!;
      } else if (widget.certState.duration != null) {
        // Fallback: use duration
        constraintDate = now.add(widget.certState.duration!);
      } else {
        // Can certify now
        constraintDate = now;
      }

      // Calculate the date based on queue position
      // Position 1 would be processed at nextIssuableDate (or now if no cooldown)
      // Position N would be processed at baseDate + (N-1) * certPeriod
      //
      // We need to get the issuer's next issuable date for queue calculation
      // If we don't have it (canRenewIn case), assume the issuer can certify now
      final issuerBaseDate = widget.certState.nextIssuableDate ?? now;
      final queuePositionDate = issuerBaseDate.add(certPeriod * (futurePosition - 1));

      // Return the later of the two dates
      // This ensures we account for both:
      // - The specific constraint (renewal delay, etc.)
      // - The queue position delay
      return constraintDate.isAfter(queuePositionDate) ? constraintDate : queuePositionDate;
    } catch (e) {
      log.e('Error calculating estimated date: $e');
      // Fallback: prioritize duration for canRenewIn, then nextIssuableDate
      if (widget.certState.status == d.CertStatus.canRenewIn && widget.certState.duration != null) {
        return DateTime.now().add(widget.certState.duration!);
      }
      if (widget.certState.nextIssuableDate != null) return widget.certState.nextIssuableDate;
      if (widget.certState.duration != null) return DateTime.now().add(widget.certState.duration!);
      return null;
    }
  }

  String? _formatEstimatedDate(DateTime date) => formatRemainingTime(date);

  Future<void> _showAddToQueueDialog(
    BuildContext context,
    DateTime? estimatedDate,
    d.CertificationType certType,
  ) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      // Check if target has migrated — adding a migrated address to queue is pointless
      final migrationData = await ref.read(migrationFromDataProvider(widget.address).future);
      if (migrationData != null) {
        if (!context.mounted) return;
        showConfirmationDialog(
          context: context,
          type: ConfirmationDialogType.error,
          message: 'migratedAccountCannotBeCertified'.tr(),
        );
        return;
      }

      // IMPORTANT: Capture all provider references BEFORE any async operation
      // to avoid "ref used after widget unmounted" errors
      final walletService = ref.read(walletServiceProvider);
      final queueNotifier = ref.read(certificationQueueProvider(widget.issuerAddress).notifier);
      final walletName = ref.read(squidServiceProvider).walletNameIndexer[widget.address];

      final displayName = walletName ?? widget.address.substring(0, 8);

      // Use appropriate confirmation message based on certification type
      final confirmKey = switch (certType) {
        d.CertificationType.invitation => 'confirmAddInvitationToQueue',
        d.CertificationType.renewal => 'confirmAddRenewalToQueue',
        d.CertificationType.certification => 'confirmAddToQueue',
      };

      String message = confirmKey.tr(args: [displayName]);
      if (estimatedDate != null) {
        final formattedDate = DateFormat.yMMMd().add_Hm().format(estimatedDate);
        message += '\n\n${'estimatedProcessingDate'.tr(args: [formattedDate])}';
      }

      final result = await showConfirmationDialog(
        context: context,
        title: 'addToQueue'.tr(),
        message: message,
        type: ConfirmationDialogType.question,
      );

      if (!result) return;
      if (!context.mounted) return;

      // Ask for PIN to sign the sync request
      if (!await PinCodeService.askPinCode(
        context,
        wallet: ref.read(walletServiceProvider).getWalletData(widget.issuerAddress),
      )) {
        return;
      }

      // Add to local queue
      final success = await queueNotifier.addToQueue(
        receiverAddress: widget.address,
        certType: certType,
        receiverUid: walletName,
        receiverName: walletName,
      );

      if (!context.mounted) return;

      if (!success) {
        SnackbarService.showWarning(context, message: 'alreadyInQueue'.tr());
        return;
      }

      // Sync with CesiumPlus
      try {
        final keyPair = await walletService.getKeyPairFromAddress(
          address: widget.issuerAddress,
          pinCode: PinCodeService.pinCode,
        );

        log.d('🔄 [AddToQueue] Syncing queue to CesiumPlus...');
        final syncSuccess = await queueNotifier.pushToRemote(keyPair.sign);

        if (!context.mounted) return;

        if (syncSuccess) {
          SnackbarService.showSuccess(context, message: 'addedToQueue'.tr(args: [displayName]));
        } else {
          // Added locally but sync failed - show warning
          SnackbarService.showWarning(context, message: 'addedToQueueSyncFailed'.tr(args: [displayName]));
        }
      } catch (e) {
        log.e('🔄 [AddToQueue] Sync failed: $e');
        if (!context.mounted) return;
        // Added locally but sync failed
        SnackbarService.showWarning(context, message: 'addedToQueueSyncFailed'.tr(args: [displayName]));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
