// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' as d;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/main.dart';
import 'package:gecko/providers/certification_queue_provider.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/screens/certification_queue_screen.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/certify/certification_transaction_helper.dart';
import 'package:gecko/widgets/certify/ready_certification_modal.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';

/// Global listener for ready certification notifications.
/// This widget should be placed high in the widget tree to listen for
/// certification ready events and show modals from anywhere in the app.
class ReadyCertificationListener extends ConsumerStatefulWidget {
  const ReadyCertificationListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ReadyCertificationListener> createState() => _ReadyCertificationListenerState();
}

class _ReadyCertificationListenerState extends ConsumerState<ReadyCertificationListener> {
  final Set<String> _listeningAddresses = {};
  bool _isShowingModal = false;

  /// Set of certification IDs that have been snoozed for this session
  /// These won't show the modal again until the app is restarted
  final Set<String> _snoozedCertificationIds = {};

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  Future<void> _setupListeners() async {
    // Wait for storage to be online
    await _waitForOnlineMode();
    if (!mounted) return;

    // Get all identity wallets and setup listeners
    final identityWallets = await ref.read(identityWalletsAsyncProvider.future);
    if (!mounted) return;

    log.d('🔔 [GlobalCertListener] Found ${identityWallets.length} identity wallet(s), setting up listeners...');

    for (final wallet in identityWallets) {
      if (!mounted) return;
      await _setupListenerForWallet(wallet.address);
    }

    log.d('🔔 [GlobalCertListener] Setup complete for ${identityWallets.length} identity wallet(s)');
  }

  Future<void> _waitForOnlineMode() async {
    var storageState = ref.read(storageStateProvider);
    int attempts = 0;
    while (storageState != StorageState.onlineMode && attempts < 40) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      storageState = ref.read(storageStateProvider);
      attempts++;
    }
  }

  Future<void> _setupListenerForWallet(String issuerAddress) async {
    if (_listeningAddresses.contains(issuerAddress)) return;
    _listeningAddresses.add(issuerAddress);

    log.d('🔔 [GlobalCertListener] Setting up listener for ${issuerAddress.substring(0, 8)}...');

    // Setup listener for future notifications
    ref.listenManual(readyCertificationNotifierProvider(issuerAddress), (previous, next) {
      if (next != null && mounted && !_isShowingModal) {
        log.d('🔔 [GlobalCertListener] Certification ready notification for $issuerAddress');
        _showReadyCertificationModal(next, issuerAddress);
      }
    });

    // Read the queue provider to trigger sync with CesiumPlus
    await ref.read(certificationQueueProvider(issuerAddress).future);
    if (!mounted) return;

    // Check current state immediately after sync is complete
    final readyCert = ref.read(readyCertificationNotifierProvider(issuerAddress));
    if (readyCert != null && mounted && !_isShowingModal) {
      log.d('🔔 [GlobalCertListener] Found ready certification for ${issuerAddress.substring(0, 8)}');
      _showReadyCertificationModal(readyCert, issuerAddress);
    }
  }

  void _showReadyCertificationModal(d.PendingCertification pendingCert, String issuerAddress) {
    if (_isShowingModal) return;

    // Check if this certification was already snoozed in this session
    if (_snoozedCertificationIds.contains(pendingCert.id)) {
      log.d('🔔 [GlobalCertListener] Certification ${pendingCert.id} was snoozed, skipping modal');
      return;
    }

    // Use global navigator context since we're inside MaterialApp.builder
    final navContext = Gecko.navigatorContext;
    if (navContext == null) {
      log.w('🔔 [GlobalCertListener] Navigator context not available yet, will retry later');
      return;
    }

    _isShowingModal = true;

    ReadyCertificationModal.show(
      context: navContext,
      pendingCert: pendingCert,
      issuerAddress: issuerAddress,
      onCertify: () => _executeCertificationFromModal(pendingCert, issuerAddress),
      onViewQueue: () {
        // Snooze this certification so it doesn't show again this session
        _snoozedCertificationIds.add(pendingCert.id);
        log.d('🔔 [GlobalCertListener] Certification ${pendingCert.id} snoozed (view queue)');

        final ctx = Gecko.navigatorContext;
        if (ctx != null) {
          Navigator.push(
            ctx,
            MaterialPageRoute(builder: (context) => CertificationQueueScreen(issuerAddress: issuerAddress)),
          );
        }
      },
      onDismiss: () {
        // Snooze this certification so it doesn't show again this session
        _snoozedCertificationIds.add(pendingCert.id);
        log.d('🔔 [GlobalCertListener] Certification ${pendingCert.id} snoozed (remind later)');
      },
    ).then((_) {
      _isShowingModal = false;
    });
  }

  Future<void> _executeCertificationFromModal(d.PendingCertification pendingCert, String issuerAddress) async {
    final navContext = Gecko.navigatorContext;
    if (navContext == null) return;

    // Capture provider references BEFORE async operations
    final walletService = ref.read(walletServiceProvider);
    final queueNotifier = ref.read(certificationQueueProvider(issuerAddress).notifier);

    final displayName =
        pendingCert.receiverName ?? pendingCert.receiverUid ?? getShortPubkey(pendingCert.receiverAddress);

    // Show confirmation dialog
    final confirmed = await showConfirmationDialog(
      context: navContext,
      title: 'certification'.tr(),
      message: '${'areYouSureYouWantToCertify1'.tr()}\n\n**$displayName**',
      type: ConfirmationDialogType.question,
    );

    if (!confirmed || !mounted) return;

    // Ask for PIN
    if (!await PinCodeService.askPinCode()) return;
    if (!mounted) return;

    try {
      // Get fresh context for transaction
      final ctx = Gecko.navigatorContext;
      if (ctx == null) return;

      // Execute the certification with callback to remove from queue and sync
      await CertificationTransactionHelper.executeCertification(
        context: ctx,
        ref: ref,
        issuerAddress: issuerAddress,
        targetAddress: pendingCert.receiverAddress,
        navigateToTargetProfile: true,
        targetUsername: pendingCert.receiverName ?? pendingCert.receiverUid,
        onBeforeNavigate: () async {
          // Remove from queue with optimistic cooldown update
          await queueNotifier.removeExecutedCertification(pendingCert.id);
          // Sync to CesiumPlus (we already have the PIN)
          await _syncToRemote(walletService, queueNotifier, issuerAddress);
        },
      );
    } catch (e) {
      if (!mounted) return;
      log.e('❌ [GlobalCertListener] Certification failed: $e');
      final errorCtx = Gecko.navigatorContext;
      if (errorCtx != null) {
        showConfirmationDialog(context: errorCtx, type: ConfirmationDialogType.error, message: e.toString());
      }
    }
  }

  /// Sync the queue to CesiumPlus
  Future<bool> _syncToRemote(
    dynamic walletService,
    CertificationQueueNotifier queueNotifier,
    String issuerAddress,
  ) async {
    try {
      final keyPair = await walletService.getKeyPairFromAddress(
        address: issuerAddress,
        pinCode: PinCodeService.pinCode,
      );

      log.d('🔄 [GlobalCertListener] Syncing queue to CesiumPlus...');
      return await queueNotifier.pushToRemote(keyPair.sign);
    } catch (e) {
      log.e('🔄 [GlobalCertListener] Sync failed: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-setup listeners when identity wallets change
    ref.listen(identityWalletsAsyncProvider, (previous, next) {
      next.whenData((wallets) {
        for (final wallet in wallets) {
          _setupListenerForWallet(wallet.address);
        }
      });
    });

    return widget.child;
  }
}
