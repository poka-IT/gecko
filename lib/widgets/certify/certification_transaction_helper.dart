import 'dart:async';

import 'package:durt2/durt2.dart' show TransactionState, TransactionStatus;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/certification_list_providers.dart';
import 'package:gecko/providers/certification_queue_provider.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/stream_providers.dart';
import 'package:gecko/widgets/certs_list.dart';
import 'package:gecko/services/certification_queue_service.dart';
import 'package:gecko/services/contact_service.dart';
import 'package:gecko/services/navigation_service.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/widgets/transaction_status.dart' show lookupTransactionError;

/// Helper class for executing certification transactions with proper cache management
class CertificationTransactionHelper {
  /// Execute a certification transaction with proper cache management
  ///
  /// This method:
  /// 1. Marks the certification as "in progress" immediately
  /// 2. Creates a broadcast stream that can be listened to by multiple consumers
  /// 3. Sets up a listener to update the cache when the transaction completes
  /// 4. Calls optional [onBeforeNavigate] callback (e.g., for queue/sync operations)
  /// 5. Navigates to the target's ProfileViewScreen if [navigateToTargetProfile] is true
  ///
  /// Set [navigateToTargetProfile] to true when calling from a screen that is NOT
  /// already the target's profile (e.g., queue screen, global modal).
  /// Leave false when already on the target's profile view.
  ///
  /// Returns the broadcast stream if successful, null if cancelled or failed before sending
  static Future<Stream<TransactionStatus>?> executeCertification({
    required BuildContext context,
    required WidgetRef ref,
    required String issuerAddress,
    required String targetAddress,
    Future<void> Function()? onBeforeNavigate,
    bool navigateToTargetProfile = false,
    String? targetUsername,
  }) async {
    // Capture ALL provider references NOW while ref is still valid
    // This prevents "ref used after widget unmounted" errors
    final notifier = ref.read(recentCertificationsProvider.notifier);
    final walletService = ref.read(walletServiceProvider);
    final duniterService = ref.read(duniterServiceProvider);
    final container = ProviderScope.containerOf(context);

    // Capture ScaffoldMessenger now while context is valid,
    // so stream errors can show a snackbar even after navigation.
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Mark as in progress immediately
    notifier.markInProgress(issuerAddress, targetAddress);

    // Force refresh of the button state provider - use microtask to avoid "setState during build"
    Future.microtask(() {
      container.invalidate(certButtonStateProvider((issuerAddress: issuerAddress, targetAddress: targetAddress)));
    });

    try {
      final keypair = await walletService.getKeyPairFromAddress(
        address: issuerAddress,
        pinCode: PinCodeService.pinCode,
      );

      // Convert to broadcast stream so it can be listened to multiple times
      final transactionStream = duniterService
          .certify(keypair: keypair, destAddress: targetAddress)
          .asBroadcastStream();

      // Listen to the stream independently to update the cache
      // This ensures we update the cache even if the user navigates away
      _listenToTransactionResult(
        notifier: notifier,
        transactionStream: transactionStream,
        issuerAddress: issuerAddress,
        targetAddress: targetAddress,
        targetUsername: targetUsername,
        container: container,
        scaffoldMessenger: scaffoldMessenger,
        removeFromPersistentQueue: true,
      );

      // Optional callback before navigation (e.g., queue removal, sync)
      if (onBeforeNavigate != null) {
        await onBeforeNavigate();
      }

      // Navigate to target's profile if requested (when not already on it)
      if (navigateToTargetProfile && context.mounted) {
        NavigationService.openProfileReplacement(context, address: targetAddress, username: targetUsername);
      }

      return transactionStream;
    } catch (e) {
      // Remove from cache since certification failed before sending
      notifier.removeCertification(issuerAddress, targetAddress);
      // Use microtask to avoid "setState during build"
      Future.microtask(() {
        container.invalidate(certButtonStateProvider((issuerAddress: issuerAddress, targetAddress: targetAddress)));
      });
      log.d('❌ [CertificationHelper] Error before sending, removed from recent cache');
      rethrow;
    }
  }

  /// Listen to the transaction stream and update the cache when the transaction completes.
  ///
  /// When [removeFromPersistentQueue] is true and the transaction fails,
  /// also removes the target from the persistent Hive queue to prevent
  /// phantom entries that linger indefinitely after a failed certification.
  static void _listenToTransactionResult({
    required RecentCertificationsNotifier notifier,
    required Stream<TransactionStatus> transactionStream,
    required String issuerAddress,
    required String targetAddress,
    String? targetUsername,
    required ProviderContainer container,
    required ScaffoldMessengerState scaffoldMessenger,
    bool removeFromPersistentQueue = false,
  }) {
    bool hasHandled = false;
    late StreamSubscription<TransactionStatus> subscription;

    subscription = transactionStream.listen(
      (status) {
        if (hasHandled) return;

        if (status.state == TransactionState.finalized || status.state == TransactionState.inBlock) {
          hasHandled = true;
          log.d('✅ [CertificationHelper] Transaction SUCCESS - marking as completed');
          notifier.markCompleted(issuerAddress, targetAddress);

          // Auto-add certified person to contacts
          final contactService = container.read(contactServiceProvider);
          contactService.addContact(G1WalletsList(address: targetAddress, username: targetUsername));

          // Invalidate identity status, cert existence, and cert state for the target
          // so child widgets (CertifyButton, AddToQueueButton) get fresh data.
          // This is critical after an invitation that creates a new identity.
          container.invalidate(idtyStatusStreamProvider(targetAddress));
          container.invalidate(certificationExistsProvider(targetAddress));
          container.invalidate(certStateProvider(targetAddress));

          // Refresh the issuer's sent cert list so cert expiration alerts
          // disappear immediately without waiting for the Squid WebSocket push.
          container
              .read(certificationListProvider((address: issuerAddress, direction: CertDirection.sent)).notifier)
              .refresh();
          subscription.cancel();
        } else if (status.state == TransactionState.error) {
          hasHandled = true;
          log.d('❌ [CertificationHelper] Transaction ERROR - removing from cache');
          notifier.removeCertification(issuerAddress, targetAddress);
          if (removeFromPersistentQueue) {
            _removeFromPersistentQueue(container, issuerAddress, targetAddress);
          }
          _showErrorSnackbar(scaffoldMessenger, status.errorMessage);
          subscription.cancel();
        }
      },
      onError: (error) {
        if (hasHandled) return;
        hasHandled = true;
        log.d('❌ [CertificationHelper] Stream ERROR - removing from cache: $error');
        notifier.removeCertification(issuerAddress, targetAddress);
        if (removeFromPersistentQueue) {
          _removeFromPersistentQueue(container, issuerAddress, targetAddress);
        }
        _showErrorSnackbar(scaffoldMessenger, error.toString());
        subscription.cancel();
      },
      onDone: () {
        if (hasHandled) return;
        hasHandled = true;
        log.w('⚠️ [CertificationHelper] Stream closed without terminal state - clearing in-progress');
        notifier.removeCertification(issuerAddress, targetAddress);
        if (removeFromPersistentQueue) {
          _removeFromPersistentQueue(container, issuerAddress, targetAddress);
        }
      },
      cancelOnError: false,
    );
  }

  /// Remove a failed certification from the persistent Hive queue.
  /// This prevents phantom entries that stay indefinitely after a failed transaction.
  /// Uses the provider if available, falls back to direct Hive removal.
  static Future<void> _removeFromPersistentQueue(
    ProviderContainer container,
    String issuerAddress,
    String targetAddress,
  ) async {
    try {
      final queueNotifier = container.read(certificationQueueProvider(issuerAddress).notifier);
      await queueNotifier.removeByAddress(targetAddress);
      log.d('🗑️ [CertificationHelper] Removed failed cert target $targetAddress from persistent queue');
    } catch (e) {
      // Fallback: remove directly from Hive if provider is not available
      log.w('[CertificationHelper] Could not remove via provider, trying direct Hive removal: $e');
      try {
        final queue = await CertificationQueueService.loadQueue(issuerAddress);
        if (queue != null && queue.containsAddress(targetAddress)) {
          final filtered = queue.pendingCertifications.where((c) => c.receiverAddress != targetAddress).toList();
          for (var i = 0; i < filtered.length; i++) {
            filtered[i] = filtered[i].copyWith(position: i + 1);
          }
          final updatedQueue = queue.copyWith(
            pendingCertifications: filtered,
            lastUpdated: DateTime.now(),
            isSynced: false,
          );
          await CertificationQueueService.saveQueue(updatedQueue);
          log.d('🗑️ [CertificationHelper] Removed failed cert target $targetAddress from Hive directly');
        }
      } catch (e2) {
        log.e('[CertificationHelper] Failed to remove from Hive: $e2');
      }
    }
  }

  /// Show a translated error message via the captured ScaffoldMessenger.
  static void _showErrorSnackbar(ScaffoldMessengerState scaffoldMessenger, String? errorMessage) {
    final translated = lookupTransactionError(errorMessage);
    final message = translated ?? errorMessage ?? 'Unknown error';
    try {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          padding: EdgeInsets.all(scaleSize(19)),
          content: Text(message, style: scaledTextStyle(fontSize: 14, color: Colors.white)),
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      // ScaffoldMessenger may have been disposed if the app navigated away entirely
      log.w('Could not show error snackbar: $message');
    }
  }
}
