import 'dart:async';

import 'package:durt2/durt2.dart' show TransactionState, TransactionStatus;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/certification_queue_provider.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/stream_providers.dart';
import 'package:gecko/screens/profile_view.dart';
import 'package:gecko/services/pin_cache_service.dart';

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
        container: container,
      );

      // Optional callback before navigation (e.g., queue removal, sync)
      if (onBeforeNavigate != null) {
        await onBeforeNavigate();
      }

      // Navigate to target's profile if requested (when not already on it)
      if (navigateToTargetProfile && context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileViewScreen(address: targetAddress, username: targetUsername),
          ),
        );
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

  /// Listen to the transaction stream and update the cache when the transaction completes
  static void _listenToTransactionResult({
    required RecentCertificationsNotifier notifier,
    required Stream<TransactionStatus> transactionStream,
    required String issuerAddress,
    required String targetAddress,
    required ProviderContainer container,
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
          // Invalidate identity status and cert existence for the target
          // so child widgets (CertifyButton, AddToQueueButton) get fresh data.
          // This is critical after an invitation that creates a new identity.
          container.invalidate(idtyStatusStreamProvider(targetAddress));
          container.invalidate(certificationExistsProvider(targetAddress));
          subscription.cancel();
        } else if (status.state == TransactionState.error) {
          hasHandled = true;
          log.d('❌ [CertificationHelper] Transaction ERROR - removing from cache');
          notifier.removeCertification(issuerAddress, targetAddress);
          subscription.cancel();
        }
      },
      onError: (error) {
        if (hasHandled) return;
        hasHandled = true;
        log.d('❌ [CertificationHelper] Stream ERROR - removing from cache: $error');
        notifier.removeCertification(issuerAddress, targetAddress);
        subscription.cancel();
      },
      cancelOnError: false,
    );
  }
}
