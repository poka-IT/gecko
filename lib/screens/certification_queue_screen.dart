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
import 'package:gecko/widgets/datapod_avatar.dart';

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
                  icon: Icon(Icons.sync_problem, color: context.geckoColors.warning),
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
              icon: Icon(Icons.sync_problem, color: context.geckoColors.warning),
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
        // Compact header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(10)),
          child: Row(
            children: [
              Text(
                'queueLength'.tr(args: [queue.queueLength.toString()]),
                style: scaledTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              if (queue.hasReadyCertification)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: scaleSize(10), vertical: scaleSize(4)),
                  decoration: BoxDecoration(
                    color: context.geckoColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.geckoColors.success.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'certificationReady'.tr(),
                    style: scaledTextStyle(
                      fontSize: 11,
                      color: context.geckoColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Queue list
        Expanded(
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
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

    // Ask for PIN BEFORE committing the reorder locally. Previously the reorder
    // was applied first and then the PIN was prompted — if the user cancelled,
    // the local queue kept the new order but the remote was never synced, so
    // the next `pullFromRemote` (on screen reopen) silently reverted the
    // user's action. Prompting first keeps local and remote state in sync.
    if (!mounted) return;
    final capturedPin = await PinCodeService.askPinCodeAndCapture(context, wallet: _issuerWallet);
    if (capturedPin == null) return;

    // Reorder locally first (instant feedback) now that we know the sync will run.
    await queueNotifier.reorder(oldIndex, newIndex);

    // Sync to CesiumPlus
    setState(() => _isSyncing = true);
    try {
      await _syncToRemoteWithRefs(walletService, queueNotifier, capturedPin);
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Widget _buildCertificationTile(BuildContext context, d.PendingCertification cert, {Key? key, bool isFirst = false}) {
    final isReady = cert.isReady;
    final displayName = cert.receiverName ?? cert.receiverUid ?? getShortPubkey(cert.receiverAddress);
    final hasName = cert.receiverName != null || cert.receiverUid != null;
    final timeInfo = _getTimeInfo(cert);

    // Accent color: green if ready, subtle border if first
    final accentColor = isReady
        ? context.geckoColors.success
        : isFirst
        ? context.colorScheme.primary
        : null;

    return Container(
      key: key,
      margin: EdgeInsets.symmetric(horizontal: scaleSize(8), vertical: scaleSize(3)),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(scaleSize(12)),
        border: Border.all(
          color: accentColor?.withValues(alpha: 0.4) ?? context.colorScheme.outline.withValues(alpha: 0.1),
          width: accentColor != null ? 1.5 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(scaleSize(12)),
        onTap: () => NavigationService.openProfile(context, address: cert.receiverAddress, username: displayName),
        child: Padding(
          padding: EdgeInsets.all(scaleSize(12)),
          child: Row(
            children: [
              // Avatar with position overlay
              Stack(
                clipBehavior: Clip.none,
                children: [
                  DatapodAvatar(address: cert.receiverAddress, size: 40, name: hasName ? displayName : null),
                  Positioned(
                    right: -scaleSize(4),
                    bottom: -scaleSize(4),
                    child: Container(
                      width: scaleSize(20),
                      height: scaleSize(20),
                      decoration: BoxDecoration(
                        color: isReady ? context.geckoColors.success : context.colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.colorScheme.surfaceContainer, width: 2),
                      ),
                      child: Center(
                        child: isReady
                            ? Icon(Icons.check, color: Colors.white, size: scaleSize(12))
                            : Text(
                                '${cert.position}',
                                style: scaledTextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: context.colorScheme.onSurface,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              ScaledSizedBox(width: 12),

              // Name + type + time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      displayName,
                      style: scaledTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasName) ...[
                      ScaledSizedBox(height: 1),
                      Text(
                        getShortPubkey(cert.receiverAddress),
                        style: scaledTextStyle(
                          fontSize: 11,
                          color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                    ScaledSizedBox(height: 4),
                    // Type badge + time on same row
                    Row(
                      children: [
                        _buildCertTypeBadge(_effectiveCertType(cert)),
                        const Spacer(),
                        _buildTimeDisplay(timeInfo, isReady, cert.expectedAvailableDate),
                      ],
                    ),
                  ],
                ),
              ),
              ScaledSizedBox(width: 8),

              // Actions column
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Play (only when ready) + delete are always available together,
                  // so a ready certification can still be removed from the queue.
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isReady) ...[
                        SizedBox(
                          width: scaleSize(32),
                          height: scaleSize(32),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              Icons.play_circle_filled,
                              color: context.geckoColors.success,
                              size: scaleSize(26),
                            ),
                            tooltip: 'executeNow'.tr(),
                            onPressed: () => _executeCertification(cert),
                          ),
                        ),
                        ScaledSizedBox(width: 2),
                      ],
                      SizedBox(
                        width: scaleSize(32),
                        height: scaleSize(32),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.close,
                            color: context.geckoColors.danger.withValues(alpha: 0.6),
                            size: scaleSize(18),
                          ),
                          tooltip: 'remove'.tr(),
                          onPressed: () => _removeFromQueue(cert),
                        ),
                      ),
                    ],
                  ),
                  ScaledSizedBox(height: 2),
                  ReorderableDragStartListener(
                    index: cert.position - 1,
                    child: Icon(
                      Icons.drag_handle,
                      color: context.colorScheme.outline.withValues(alpha: 0.3),
                      size: scaleSize(18),
                    ),
                  ),
                ],
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

  /// Build compact inline time display.
  Widget _buildTimeDisplay(
    ({String primary, String? secondary, bool isToday, bool isTomorrow}) timeInfo,
    bool isReady,
    DateTime? expectedDate,
  ) {
    final color = isReady
        ? context.geckoColors.success
        : timeInfo.isToday
        ? context.geckoColors.warning
        : context.colorScheme.onSurface.withValues(alpha: 0.5);

    final text = timeInfo.secondary != null ? '${timeInfo.primary} · ${timeInfo.secondary}' : timeInfo.primary;

    return Text(
      text,
      style: scaledTextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
    );
  }

  /// If the cert was queued as "renewal" but the underlying certification has since
  /// expired, downgrade the display type to "certification".
  d.CertificationType _effectiveCertType(d.PendingCertification cert) {
    if (cert.certType != d.CertificationType.renewal) return cert.certType;
    final exists = ref.watch(certificationExistsProvider(cert.receiverAddress)).value ?? true;
    return exists ? d.CertificationType.renewal : d.CertificationType.certification;
  }

  Widget _buildCertTypeBadge(d.CertificationType type) {
    final (label, color, icon) = switch (type) {
      d.CertificationType.invitation => ('certTypeInvitation'.tr(), Colors.purple.shade600, Icons.person_add),
      d.CertificationType.renewal => ('certTypeRenewal'.tr(), context.geckoColors.warning, Icons.autorenew),
      d.CertificationType.certification => (
        'certTypeCertification'.tr(),
        context.geckoColors.info,
        Icons.verified_user,
      ),
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

    if (!mounted) return;
    final capturedPin = await PinCodeService.askPinCodeAndCapture(context, wallet: _issuerWallet);
    if (capturedPin == null) return;

    final identityWallet = await identityWalletFuture;
    if (identityWallet == null) {
      // Use the State's own null-safe `mounted`, NOT `context.mounted`:
      // reading `State.context` after disposal throws "Null check operator
      // used on a null value" (framework `_element!`) before `.mounted` is
      // even evaluated.
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      showConfirmationDialog(context: context, type: ConfirmationDialogType.error, message: 'noIdentityWallet'.tr());
      return;
    }

    try {
      if (!mounted) return;
      await CertificationTransactionHelper.executeCertification(
        context: context,
        ref: ref,
        issuerAddress: identityWallet.address,
        targetAddress: cert.receiverAddress,
        pinCode: capturedPin,
        navigateToTargetProfile: true,
        targetUsername: cert.receiverName ?? cert.receiverUid,
        onBeforeNavigate: () async {
          // Remove from queue with optimistic cooldown update
          await queueNotifier.removeExecutedCertification(cert.id);
          // Sync to CesiumPlus using the captured PIN (the service cache may
          // have been cleared by debounceResetPinCode at this point).
          await _syncToRemoteWithRefs(walletService, queueNotifier, capturedPin);
        },
      );
    } catch (e) {
      log.e('Error executing certification: $e');
      // `mounted` (State) is null-safe; `context.mounted` would throw on a
      // disposed State because evaluating `context` dereferences `_element!`.
      if (!mounted) return;
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
    if (!mounted) return;
    final capturedPin = await PinCodeService.askPinCodeAndCapture(context, wallet: _issuerWallet);
    if (capturedPin == null) return;

    await queueNotifier.removeFromQueue(cert.id);

    // Sync to CesiumPlus with the captured PIN
    await _syncToRemoteWithRefs(walletService, queueNotifier, capturedPin);

    // AXIOM-TEAM-HG: the user often taps the back button during this network
    // sync, disposing this State. Guard with the State's own null-safe
    // `mounted` — `context.mounted` crashed here because reading `State.context`
    // dereferences `_element!`, which is null after disposal.
    if (!mounted) return;
    SnackbarService.showWarning(context, message: 'removedFromQueue'.tr(args: [displayName]));
  }

  /// Sync the queue to CesiumPlus using pre-captured references.
  ///
  /// [pinCode] must be a locally-captured PIN obtained from
  /// [PinCodeService.askPinCodeAndCapture] so that the crypto step survives
  /// the user-facing delay of the enclosing flow (confirmation dialogs,
  /// navigation, etc.).
  Future<bool> _syncToRemoteWithRefs(
    dynamic walletService,
    CertificationQueueNotifier queueNotifier,
    String pinCode,
  ) async {
    try {
      final keyPair = await walletService.getKeyPairFromAddress(address: widget.issuerAddress, pinCode: pinCode);

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

    // Ask for PIN and capture it locally for the sync crypto step.
    final capturedPin = await PinCodeService.askPinCodeAndCapture(context, wallet: _issuerWallet);
    if (capturedPin == null) return;

    final success = await _syncToRemoteWithRefs(walletService, queueNotifier, capturedPin);

    if (!context.mounted) return;

    if (success) {
      SnackbarService.showSuccess(context, message: 'queueSynced'.tr());
    } else {
      SnackbarService.showWarning(context, message: 'syncFailed'.tr());
    }
  }
}
