// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' as d;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/certification_queue_provider.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/services/navigation_service.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/widgets/certify/certification_transaction_helper.dart';
import 'package:gecko/services/snackbar_service.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/widgets/commons/responsive_center.dart';

class CertificationQueueScreen extends ConsumerStatefulWidget {
  const CertificationQueueScreen({super.key, required this.issuerAddress, this.embeddedMode = false});

  final String issuerAddress;
  final bool embeddedMode;

  @override
  ConsumerState<CertificationQueueScreen> createState() => _CertificationQueueScreenState();
}

class _CertificationQueueScreenState extends ConsumerState<CertificationQueueScreen> {
  bool _isSyncing = false;

  d.WalletEntity get _issuerWallet => ref.read(walletServiceProvider).getWalletData(widget.issuerAddress);

  @override
  void initState() {
    super.initState();
    // Pull remote queue on screen open (non-blocking, updates UI if remote is newer)
    Future.microtask(() {
      ref.read(certificationQueueProvider(widget.issuerAddress).notifier).pullFromRemote();
    });
  }

  @override
  Widget build(BuildContext context) {
    final queueAsync = ref.watch(certificationQueueProvider(widget.issuerAddress));

    final content = ResponsiveCenter(
      maxWidth: 600,
      padding: EdgeInsets.zero,
      child: queueAsync.when(
        data: (queue) => _buildQueueContent(context, queue),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('error'.tr())),
      ),
    );

    if (widget.embeddedMode) {
      return Column(
        children: [
          // Sync indicator for embedded mode
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (queueAsync.value?.isSynced == false)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 4),
                child: IconButton(
                  icon: const Icon(Icons.sync_problem, color: Colors.orange),
                  tooltip: 'syncNow'.tr(),
                  onPressed: () => _showSyncDialog(context),
                ),
              ),
            ),
          Expanded(child: content),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('certificationQueue'.tr()),
        backgroundColor: context.colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            )
          else if (queueAsync.value?.isSynced == false)
            IconButton(
              icon: const Icon(Icons.sync_problem, color: Colors.orange),
              tooltip: 'syncNow'.tr(),
              onPressed: () => _showSyncDialog(context),
            ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildQueueContent(BuildContext context, d.CertificationQueueState? queue) {
    if (queue == null || queue.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        // Header with queue info
        Container(
          padding: const EdgeInsets.all(16),
          color: context.colorScheme.surfaceContainerHighest,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'queueLength'.tr(args: [queue.queueLength.toString()]),
                style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              if (queue.hasReadyCertification)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    'certificationReady'.tr(),
                    style: scaledTextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),

        // Queue list
        Expanded(
          child: ReorderableListView.builder(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 80),
            onReorder: (oldIndex, newIndex) => _onReorder(oldIndex, newIndex),
            itemCount: queue.pendingCertifications.length,
            itemBuilder: (context, index) {
              final cert = queue.pendingCertifications[index];
              final isFirst = index == 0;
              return _buildCertificationTile(context, cert, isFirst: isFirst, key: ValueKey(cert.id));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.queue_outlined, size: scaleSize(80), color: Colors.grey[400]),
            ScaledSizedBox(height: 24),
            Text(
              'certificationQueueEmpty'.tr(),
              style: scaledTextStyle(fontSize: 18, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            ScaledSizedBox(height: 16),
            Text(
              'certificationQueueEmptyHint'.tr(),
              style: scaledTextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Handle reorder with automatic sync
  Future<void> _onReorder(int oldIndex, int newIndex) async {
    // Capture provider references BEFORE async operations
    final queueNotifier = ref.read(certificationQueueProvider(widget.issuerAddress).notifier);
    final walletService = ref.read(walletServiceProvider);

    // Reorder locally first (instant feedback)
    await queueNotifier.reorder(oldIndex, newIndex);

    // Check if PIN is already cached
    if (PinCodeService.pinCode.isEmpty) {
      // Ask for PIN to sync
      if (!await PinCodeService.askPinCode(wallet: _issuerWallet)) return;
    }

    // Sync to CesiumPlus
    setState(() => _isSyncing = true);
    try {
      await _syncToRemoteWithRefs(walletService, queueNotifier);
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Widget _buildCertificationTile(BuildContext context, d.PendingCertification cert, {Key? key, bool isFirst = false}) {
    final isReady = cert.isReady;
    final displayName = cert.receiverName ?? cert.receiverUid ?? getShortPubkey(cert.receiverAddress);

    // Calculate remaining time info
    final timeInfo = _getTimeInfo(cert);

    // Determine card styling based on position and readiness
    final isHighlighted = isFirst || isReady;
    final cardColor = isReady ? Colors.green.shade50 : (isFirst ? Colors.blue.shade50 : null);
    final elevation = isHighlighted ? 4.0 : 1.0;

    return Card(
      key: key,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: isFirst ? 8 : 6),
      elevation: elevation,
      color: cardColor,
      shape: isFirst
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isReady ? Colors.green.shade300 : Colors.blue.shade300, width: 2),
            )
          : null,
      child: Padding(
        padding: EdgeInsets.all(isFirst ? 4 : 0),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: _buildPositionBadge(cert.position, isReady, isFirst: isFirst),
          title: GestureDetector(
            onTap: () {
              NavigationService.openProfile(context, address: cert.receiverAddress, username: displayName);
            },
            child: Text(
              displayName,
              style: scaledTextStyle(
                fontSize: isFirst ? 18 : 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScaledSizedBox(height: 6),
              _buildCertTypeBadge(cert.certType),
              ScaledSizedBox(height: 8),
              _buildTimeDisplay(timeInfo, isReady, cert.expectedAvailableDate),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isReady)
                IconButton(
                  icon: Icon(Icons.play_circle_filled, color: Colors.green.shade700, size: scaleSize(32)),
                  tooltip: 'executeNow'.tr(),
                  onPressed: () => _executeCertification(cert),
                ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: scaleSize(24)),
                tooltip: 'remove'.tr(),
                onPressed: () => _removeFromQueue(cert),
              ),
              ReorderableDragStartListener(
                index: cert.position - 1,
                child: Icon(Icons.drag_handle, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get time info for display (days remaining, date, etc.)
  ({String primary, String? secondary, bool isToday, bool isTomorrow}) _getTimeInfo(d.PendingCertification cert) {
    if (cert.isReady) {
      return (primary: 'readyToCertify'.tr(), secondary: null, isToday: true, isTomorrow: false);
    }

    final expectedDate = cert.expectedAvailableDate;
    if (expectedDate == null) {
      return (primary: 'pending'.tr(), secondary: null, isToday: false, isTomorrow: false);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(expectedDate.year, expectedDate.month, expectedDate.day);
    final daysRemaining = targetDay.difference(today).inDays;

    final timeStr = DateFormat.Hm().format(expectedDate);
    final dateStr = DateFormat.MMMd().format(expectedDate);

    if (daysRemaining <= 0) {
      return (primary: 'today'.tr(), secondary: timeStr, isToday: true, isTomorrow: false);
    } else if (daysRemaining == 1) {
      return (primary: 'tomorrow'.tr(), secondary: timeStr, isToday: false, isTomorrow: true);
    } else {
      return (
        primary: 'inXDays'.tr(args: [daysRemaining.toString()]),
        secondary: dateStr,
        isToday: false,
        isTomorrow: false,
      );
    }
  }

  /// Build time display widget
  Widget _buildTimeDisplay(
    ({String primary, String? secondary, bool isToday, bool isTomorrow}) timeInfo,
    bool isReady,
    DateTime? expectedDate,
  ) {
    final primaryColor = isReady
        ? Colors.green.shade700
        : timeInfo.isToday
        ? Colors.orange.shade700
        : timeInfo.isTomorrow
        ? Colors.blue.shade600
        : Colors.grey.shade600;

    return Row(
      children: [
        Icon(
          isReady
              ? Icons.check_circle
              : timeInfo.isToday
              ? Icons.schedule
              : Icons.calendar_today,
          size: scaleSize(14),
          color: primaryColor,
        ),
        ScaledSizedBox(width: 6),
        Text(
          timeInfo.primary,
          style: scaledTextStyle(
            fontSize: 13,
            fontWeight: isReady || timeInfo.isToday ? FontWeight.w600 : FontWeight.w500,
            color: primaryColor,
          ),
        ),
        if (timeInfo.secondary != null) ...[
          ScaledSizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
            child: Text(timeInfo.secondary!, style: scaledTextStyle(fontSize: 11, color: Colors.grey.shade700)),
          ),
        ],
      ],
    );
  }

  Widget _buildPositionBadge(int position, bool isReady, {bool isFirst = false}) {
    final size = isFirst ? 48.0 : 40.0;
    final iconSize = isFirst ? 28.0 : 24.0;
    final fontSize = isFirst ? 16.0 : 14.0;

    Color bgColor;
    if (isReady) {
      bgColor = Colors.green;
    } else if (isFirst) {
      bgColor = Colors.blue;
    } else {
      bgColor = Colors.blue.shade100;
    }

    return Container(
      width: scaleSize(size),
      height: scaleSize(size),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: isFirst
            ? [BoxShadow(color: bgColor.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: Center(
        child: isReady
            ? Icon(Icons.check, color: Colors.white, size: scaleSize(iconSize))
            : Text(
                '#$position',
                style: scaledTextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: isFirst ? Colors.white : Colors.blue.shade700,
                ),
              ),
      ),
    );
  }

  Widget _buildCertTypeBadge(d.CertificationType type) {
    final (label, color, icon) = switch (type) {
      d.CertificationType.invitation => ('certTypeInvitation'.tr(), Colors.purple.shade600, Icons.person_add),
      d.CertificationType.renewal => ('certTypeRenewal'.tr(), Colors.orange.shade700, Icons.autorenew),
      d.CertificationType.certification => ('certTypeCertification'.tr(), Colors.blue.shade600, Icons.verified_user),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: scaleSize(12), color: color),
          ScaledSizedBox(width: 4),
          Text(
            label,
            style: scaledTextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<void> _executeCertification(d.PendingCertification cert) async {
    // Capture provider references BEFORE async operations
    final walletService = ref.read(walletServiceProvider);
    final queueNotifier = ref.read(certificationQueueProvider(widget.issuerAddress).notifier);
    final identityWalletFuture = ref.read(effectiveCertificationWalletProvider.future);

    final displayName = cert.receiverName ?? cert.receiverUid ?? getShortPubkey(cert.receiverAddress);

    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'certification'.tr(),
      message: '${'areYouSureYouWantToCertify1'.tr()}\n\n**$displayName**',
      type: ConfirmationDialogType.question,
    );

    if (!confirmed) return;

    if (!await PinCodeService.askPinCode(wallet: _issuerWallet)) return;

    final identityWallet = await identityWalletFuture;
    if (identityWallet == null) {
      if (!context.mounted) return;
      showConfirmationDialog(context: context, type: ConfirmationDialogType.error, message: 'noIdentityWallet'.tr());
      return;
    }

    try {
      await CertificationTransactionHelper.executeCertification(
        context: context,
        ref: ref,
        issuerAddress: identityWallet.address,
        targetAddress: cert.receiverAddress,
        navigateToTargetProfile: true,
        targetUsername: cert.receiverName ?? cert.receiverUid,
        onBeforeNavigate: () async {
          // Remove from queue with optimistic cooldown update
          await queueNotifier.removeExecutedCertification(cert.id);
          // Sync to CesiumPlus (we already have the PIN)
          await _syncToRemoteWithRefs(walletService, queueNotifier);
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      log.e('Error executing certification: $e');
      showConfirmationDialog(context: context, type: ConfirmationDialogType.error, message: e.toString());
    }
  }

  Future<void> _removeFromQueue(d.PendingCertification cert) async {
    // Capture provider references BEFORE async operations
    final queueNotifier = ref.read(certificationQueueProvider(widget.issuerAddress).notifier);
    final walletService = ref.read(walletServiceProvider);

    final displayName = cert.receiverName ?? cert.receiverUid ?? getShortPubkey(cert.receiverAddress);

    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'remove'.tr(),
      message: 'confirmRemoveFromQueue'.tr(args: [displayName]),
      type: ConfirmationDialogType.question,
    );

    if (!confirmed) return;

    // Ask for PIN to sync after removal
    if (!await PinCodeService.askPinCode(wallet: _issuerWallet)) return;

    await queueNotifier.removeFromQueue(cert.id);

    // Sync to CesiumPlus
    await _syncToRemoteWithRefs(walletService, queueNotifier);

    if (!context.mounted) return;

    SnackbarService.showWarning(context, message: 'removedFromQueue'.tr(args: [displayName]));
  }

  /// Sync the queue to CesiumPlus using pre-captured references
  Future<bool> _syncToRemoteWithRefs(dynamic walletService, CertificationQueueNotifier queueNotifier) async {
    try {
      final keyPair = await walletService.getKeyPairFromAddress(
        address: widget.issuerAddress,
        pinCode: PinCodeService.pinCode,
      );

      log.d('🔄 [CertQueueScreen] Syncing queue to CesiumPlus...');
      return await queueNotifier.pushToRemote(keyPair.sign);
    } catch (e) {
      log.e('🔄 [CertQueueScreen] Sync failed: $e');
      return false;
    }
  }

  /// Show sync dialog and optionally trigger manual sync
  Future<void> _showSyncDialog(BuildContext context) async {
    // Capture provider references BEFORE async operations
    final queueNotifier = ref.read(certificationQueueProvider(widget.issuerAddress).notifier);
    final walletService = ref.read(walletServiceProvider);

    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'syncStatus'.tr(),
      message: 'queueNotSyncedConfirm'.tr(),
      type: ConfirmationDialogType.question,
    );

    if (!confirmed) return;
    if (!context.mounted) return;

    // Ask for PIN
    if (!await PinCodeService.askPinCode(wallet: _issuerWallet)) return;

    final success = await _syncToRemoteWithRefs(walletService, queueNotifier);

    if (!context.mounted) return;

    if (success) {
      SnackbarService.showSuccess(context, message: 'queueSynced'.tr());
    } else {
      SnackbarService.showWarning(context, message: 'syncFailed'.tr());
    }
  }
}
