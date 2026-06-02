import 'dart:async';
import 'dart:typed_data';
import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/block_height_provider.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/services/certification_queue_service.dart';
import 'package:uuid/uuid.dart';

/// State of a recent certification
enum RecentCertState {
  /// Transaction is being sent/processed
  inProgress,

  /// Transaction completed successfully
  completed,
}

/// Data for a recent certification
class RecentCertData {
  final DateTime timestamp;
  final RecentCertState certState;

  RecentCertData({required this.timestamp, required this.certState});

  RecentCertData copyWith({RecentCertState? certState}) {
    return RecentCertData(timestamp: timestamp, certState: certState ?? this.certState);
  }
}

/// Stores recent certifications to prevent showing "add to queue" immediately after certifying
/// Key: "issuerAddress:targetAddress", Value: certification data with state
class RecentCertificationsNotifier extends Notifier<Map<String, RecentCertData>> {
  final Map<String, Timer> _cleanupTimers = {};

  @override
  Map<String, RecentCertData> build() {
    // Cancel all timers when provider is disposed
    ref.onDispose(() {
      for (final timer in _cleanupTimers.values) {
        timer.cancel();
      }
      _cleanupTimers.clear();
    });
    return {};
  }

  /// Mark that a certification transaction is starting (in progress)
  void markInProgress(String issuerAddress, String targetAddress) {
    final key = '$issuerAddress:$targetAddress';
    state = {...state, key: RecentCertData(timestamp: DateTime.now(), certState: RecentCertState.inProgress)};
  }

  /// Mark that a certification transaction completed successfully.
  /// Resets the timestamp to now so the 10-minute `wasCertifiedRecently`
  /// window starts from completion, not from when the transaction was sent.
  void markCompleted(String issuerAddress, String targetAddress) {
    final key = '$issuerAddress:$targetAddress';
    state = {...state, key: RecentCertData(timestamp: DateTime.now(), certState: RecentCertState.completed)};

    // Cancel existing timer if any and start new auto-cleanup timer
    _cleanupTimers[key]?.cancel();
    _cleanupTimers[key] = Timer(const Duration(minutes: 10), () {
      _cleanup(key);
      _cleanupTimers.remove(key);
    });
  }

  /// Legacy method - marks as in progress (for backward compatibility during migration)
  void addCertification(String issuerAddress, String targetAddress) {
    markInProgress(issuerAddress, targetAddress);
  }

  /// Check if a certification is currently in progress
  bool isInProgress(String issuerAddress, String targetAddress) {
    final key = '$issuerAddress:$targetAddress';
    final data = state[key];
    if (data == null) return false;
    return data.certState == RecentCertState.inProgress;
  }

  /// Check if a certification was recently completed (within last 10 minutes)
  bool wasCertifiedRecently(String issuerAddress, String targetAddress) {
    final key = '$issuerAddress:$targetAddress';
    final data = state[key];
    if (data == null) return false;

    // Only count as "recently certified" if completed (not in progress)
    if (data.certState != RecentCertState.completed) return false;

    return DateTime.now().difference(data.timestamp).inMinutes < 10;
  }

  /// Remove a certification from cache (e.g., when transaction fails)
  void removeCertification(String issuerAddress, String targetAddress) {
    final key = '$issuerAddress:$targetAddress';
    if (state.containsKey(key)) {
      final newState = Map<String, RecentCertData>.from(state);
      newState.remove(key);
      state = newState;
    }
  }

  void _cleanup(String key) {
    if (state.containsKey(key)) {
      final newState = Map<String, RecentCertData>.from(state);
      newState.remove(key);
      state = newState;
    }
  }
}

/// Provider for recent certifications cache
final recentCertificationsProvider = NotifierProvider<RecentCertificationsNotifier, Map<String, RecentCertData>>(
  RecentCertificationsNotifier.new,
);

/// Action available for the certification button
enum CertButtonAction {
  /// No action available (not a member, etc.)
  none,

  /// Can certify immediately
  certifyNow,

  /// Must wait but can add to queue
  addToQueue,

  /// Already in the queue
  inQueue,

  /// First in queue and ready to execute
  executeQueued,

  /// Certification transaction is in progress
  inProgress,

  /// Cannot certify (empty wallet, revoked, etc.)
  disabled,
}

/// State of the certification button for a specific target
class CertButtonState {
  final CertButtonAction action;
  final d.CertState? certState;
  final d.PendingCertification? pendingCert;
  final String? disabledReason;

  const CertButtonState({required this.action, this.certState, this.pendingCert, this.disabledReason});

  /// Whether the target is in the queue
  bool get isInQueue => action == CertButtonAction.inQueue || action == CertButtonAction.executeQueued;
}

/// Main certification queue notifier - family notifier keyed by issuer address
class CertificationQueueNotifier extends AsyncNotifier<d.CertificationQueueState?> {
  final String issuerAddress;

  CertificationQueueNotifier(this.issuerAddress);

  @override
  FutureOr<d.CertificationQueueState?> build() async {
    final storageState = ref.watch(storageStateProvider);

    // Load from local Hive storage regardless of storage state.
    // The queue is persisted locally and should be available even offline.
    var queue = await CertificationQueueService.loadQueue(issuerAddress);

    // If no local queue exists (fresh install, app data cleared, Hive box
    // rebuilt), create an empty placeholder with an *epoch-0* lastUpdated.
    // CertificationQueueState.empty() uses DateTime.now(), which would make
    // the empty local always look newer than any pre-existing remote queue,
    // so sync would skip the remote and the user's queue would stay lost.
    // Using epoch 0 ensures remote always wins when local was never written.
    queue ??= d.CertificationQueueState(
      issuerAddress: issuerAddress,
      pendingCertifications: const [],
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(0),
      isSynced: false,
    );

    // If storage is not initialized yet, return the local queue as-is
    // without attempting blockchain date updates or remote sync.
    if (storageState == StorageState.notInitialized) {
      return queue;
    }

    // Update expected dates based on current blockchain state
    queue = await _updateQueueDates(queue);

    // Listen to block height to check ready certifications.
    // Only check when needed, not every block (~6s):
    // 1. When block height reaches the next cert's expected block (becomes ready)
    // 2. Every 100 blocks (~10 min) to catch external blockchain state changes
    //    (e.g. cert counter updated by another device via CesiumPlus)
    ref.listen(blockHeightProvider, (previous, next) async {
      if (next == 0 || next == previous) return;
      final currentState = state.value;
      if (currentState == null || currentState.isEmpty) return;

      final targetBlock = currentState.pendingCertifications.first.expectedAvailableBlock;
      final certMayBeReady = targetBlock != null && next >= targetBlock && !currentState.hasReadyCertification;
      final periodicSync = previous != null && (next ~/ 100) > (previous ~/ 100);

      if (certMayBeReady || periodicSync) {
        await _checkAndNotifyReadyCertifications();
      }
    });

    // Notify if any certification is ready at startup (before sync)
    if (queue.hasReadyCertification) {
      final readyCert = queue.nextReadyCertification;
      if (readyCert != null) {
        ref.read(readyCertificationNotifierProvider(issuerAddress).notifier).notify(readyCert);
      }
    }

    // Sync with CesiumPlus in background (don't block UI)
    _syncWithCesiumPlus(queue);

    return queue;
  }

  /// Update the expected dates in the queue based on current blockchain state.
  /// Uses the greater of blockchain's nextIssuableOn and the queue's local value
  /// to avoid overwriting an optimistic update after a cert execution.
  Future<d.CertificationQueueState> _updateQueueDates(d.CertificationQueueState queue) async {
    try {
      final storageService = ref.read(storageServiceProvider);
      final certData = await storageService.getCertsCounter(queue.issuerAddress);
      final currentBlock = await storageService.getCurrentBlockHeight();
      final certPeriodBlocks = storageService.getCertPeriodBlocks();

      // Use the greater of blockchain and local optimistic nextIssuableOn.
      // After executing a cert, the local value is set optimistically to
      // currentBlock + certPeriod. The blockchain won't reflect this until
      // the TX is finalized. Taking the max prevents stale blockchain data
      // from overwriting the optimistic value.
      final blockchainNext = certData.nextIssuableOn;
      final localNext = queue.nextIssuableOn;
      int? effectiveNext;
      if (blockchainNext != null && localNext != null) {
        effectiveNext = blockchainNext > localNext ? blockchainNext : localNext;
      } else {
        effectiveNext = blockchainNext ?? localNext;
      }

      return CertificationQueueService.updateExpectedDates(
        queue: queue,
        certPeriodBlocks: certPeriodBlocks,
        currentBlockNumber: currentBlock,
        nextIssuableBlock: effectiveNext,
        blockTimeSeconds: storageService.currencyConstants.blockTimeSeconds,
      );
    } catch (e) {
      log.e('[CertQueueProvider] Error updating queue dates: $e');
      return queue;
    }
  }

  /// Check if any certifications are ready and notify
  Future<void> _checkAndNotifyReadyCertifications() async {
    final currentState = state.value;
    if (currentState == null || currentState.isEmpty) return;

    // Update dates and check for ready certifications
    final updatedQueue = await _updateQueueDates(currentState);

    if (updatedQueue.hasReadyCertification) {
      final readyCert = updatedQueue.nextReadyCertification;
      if (readyCert != null) {
        ref.read(readyCertificationNotifierProvider(issuerAddress).notifier).notify(readyCert);
      }
    }

    // Only update state and save if something meaningful changed
    if (_hasQueueChanged(currentState, updatedQueue)) {
      state = AsyncValue.data(updatedQueue);
      await CertificationQueueService.saveQueue(updatedQueue);
    }
  }

  /// Check if the queue has meaningful changes (ignoring DateTime recalculations)
  bool _hasQueueChanged(d.CertificationQueueState oldQueue, d.CertificationQueueState newQueue) {
    if (oldQueue.nextIssuableOn != newQueue.nextIssuableOn) return true;
    if (oldQueue.queueLength != newQueue.queueLength) return true;

    for (var i = 0; i < oldQueue.pendingCertifications.length; i++) {
      if (oldQueue.pendingCertifications[i].expectedAvailableBlock !=
          newQueue.pendingCertifications[i].expectedAvailableBlock) {
        return true;
      }
    }

    return false;
  }

  /// Sync with CesiumPlus - at startup, remote is the source of truth.
  /// If the local queue is empty, only attempt sync when connections are
  /// already active (no waiting) to avoid blocking startup for nothing.
  /// [loadedQueue] is the queue loaded in build(), since state.value isn't
  /// set yet when this is called from build().
  Future<void> _syncWithCesiumPlus(d.CertificationQueueState loadedQueue) async {
    try {
      final durt = ref.read(durtProvider);
      final hasLocalItems = !loadedQueue.isEmpty;

      if (hasLocalItems) {
        // We have local items - worth waiting for connections
        if (!durt.isConnected) {
          try {
            await durt.duniterConnectionStatusStream
                .firstWhere((status) => status == d.ConnectionStatus.connected)
                .timeout(const Duration(seconds: 10));
          } on TimeoutException {
            log.w('[CertQueueSync] Duniter not connected after 10s, skipping sync');
            return;
          }
        }

        if (durt.datapodConnectionStatus != d.ConnectionStatus.connected) {
          try {
            await durt.datapodConnectionStatusStream
                .firstWhere((status) => status == d.ConnectionStatus.connected)
                .timeout(const Duration(seconds: 15));
          } on TimeoutException {
            log.w('[CertQueueSync] CesiumPlus not connected after 15s, skipping sync');
            return;
          }
        }
      } else {
        // No local items - only sync if connections are already active
        if (!durt.isConnected || durt.datapodConnectionStatus != d.ConnectionStatus.connected) {
          return;
        }
      }

      final cesiumPlus = ref.read(cesiumPlusServiceProvider);

      // Fetch remote queue from CesiumPlus
      d.CertificationQueueState? remoteQueue;
      try {
        remoteQueue = await cesiumPlus.getCertificationQueue(issuerAddress);
      } catch (e) {
        log.e('[CertQueueSync] Error fetching remote queue: $e');
        return;
      }

      // Determine the final queue state
      d.CertificationQueueState? finalQueue;

      if (remoteQueue != null) {
        log.d('[CertQueueSync] Remote queue found for $issuerAddress: ${remoteQueue.queueLength} items');

        // Guard: don't overwrite a locally-modified state that is newer than remote
        final currentState = state.value;
        if (currentState != null && !currentState.lastUpdated.isBefore(remoteQueue.lastUpdated)) {
          log.d('[CertQueueSync] Local state is same or newer than remote, skipping overwrite');
          return;
        }

        // Guard: never overwrite a non-empty local queue with an empty remote queue.
        // This prevents data loss when CesiumPlus returns an empty queue due to
        // sync issues, stale data, or a fresh remote profile.
        if (hasLocalItems && remoteQueue.isEmpty) {
          log.d('[CertQueueSync] Remote queue is empty but local has items, keeping local');
          finalQueue = loadedQueue.copyWith(isSynced: false);
        } else {
          finalQueue = await _updateQueueDates(remoteQueue);
          finalQueue = finalQueue.copyWith(isSynced: true);
        }
      } else if (hasLocalItems) {
        finalQueue = loadedQueue.copyWith(isSynced: false);
      } else {
        return;
      }

      state = AsyncValue.data(finalQueue);
      await CertificationQueueService.saveQueue(finalQueue);

      // Notify if any certification is ready immediately after sync
      if (finalQueue.hasReadyCertification) {
        final readyCert = finalQueue.nextReadyCertification;
        if (readyCert != null) {
          ref.read(readyCertificationNotifierProvider(issuerAddress).notifier).notify(readyCert);
        }
      }
    } catch (e, stack) {
      log.e('[CertQueueSync] Sync failed for $issuerAddress: $e\n$stack');
    }
  }

  /// Push queue to CesiumPlus (requires sign function from PIN validation)
  /// Note: saveCertificationQueue automatically creates a minimal profile if none exists
  Future<bool> pushToRemote(Uint8List Function(Uint8List) signFunction) async {
    final currentQueue = state.value;
    if (currentQueue == null) {
      log.w('[CertQueuePush] No queue to push');
      return false;
    }

    try {
      final cesiumPlus = ref.read(cesiumPlusServiceProvider);

      // Safety: if local is empty, check remote first. A non-empty remote
      // with empty local can mean either:
      //   (a) local data was lost (fresh install, app data cleared, Hive
      //       rebuild) — the empty local is the epoch-0 placeholder created
      //       in build(), i.e. OLDER than the remote queue;
      //   (b) the user deliberately removed the last queued certification —
      //       removeFromQueue/removeExecutedCertification stamp the empty
      //       queue with lastUpdated = now, i.e. NEWER than the remote queue.
      //
      // Only case (a) must recover from remote; pushing empty there would
      // destroy the user's CesiumPlus queue irreversibly. Case (b) is a
      // legitimate emptying that MUST be propagated — otherwise the last
      // entry resurrects on every sync and the app keeps prompting to
      // re-certify (the recurring "phantom last certification" bug).
      //
      // The discriminator is the same lastUpdated arbitration used in
      // _syncWithCesiumPlus: remote only wins when the local empty predates it.
      if (currentQueue.isEmpty) {
        try {
          final remoteQueue = await cesiumPlus.getCertificationQueue(issuerAddress);
          // Recover from remote unless the local empty is STRICTLY newer than
          // remote (a deliberate deletion). At equal timestamps we recover —
          // consistent with `_syncWithCesiumPlus`'s `!isBefore` arbitration,
          // which lets the (non-empty) remote win on ties.
          if (remoteQueue != null &&
              !remoteQueue.isEmpty &&
              !currentQueue.lastUpdated.isAfter(remoteQueue.lastUpdated)) {
            log.w(
              '[CertQueuePush] Local queue empty and older than remote (${remoteQueue.queueLength} items) — '
              'recovering from remote instead of overwriting it',
            );
            var recovered = await _updateQueueDates(remoteQueue);
            recovered = recovered.copyWith(isSynced: true);
            state = AsyncValue.data(recovered);
            await CertificationQueueService.saveQueue(recovered);

            if (recovered.hasReadyCertification) {
              final readyCert = recovered.nextReadyCertification;
              if (readyCert != null) {
                ref.read(readyCertificationNotifierProvider(issuerAddress).notifier).notify(readyCert);
              }
            }
            // Treat as success — the local state now matches remote.
            return true;
          }
        } catch (e) {
          log.e('[CertQueuePush] Pre-push remote check failed: $e — aborting push to avoid data loss');
          return false;
        }
      }

      final success = await cesiumPlus.saveCertificationQueue(
        address: issuerAddress,
        signFunction: signFunction,
        queue: currentQueue,
      );

      if (success) {
        final syncedQueue = currentQueue.copyWith(isSynced: true);
        state = AsyncValue.data(syncedQueue);
        await CertificationQueueService.saveQueue(syncedQueue);
      } else {
        log.e('[CertQueuePush] Failed to push queue for $issuerAddress');
      }

      return success;
    } catch (e, stack) {
      log.e('[CertQueuePush] Push failed for $issuerAddress: $e\n$stack');
      return false;
    }
  }

  /// Add a certification to the queue
  Future<bool> addToQueue({
    required String receiverAddress,
    required d.CertificationType certType,
    int? receiverIndex,
    String? receiverUid,
    String? receiverName,
    d.CertState? certState,
  }) async {
    final currentQueue = state.value;
    if (currentQueue == null) {
      log.e('[CertQueueAdd] No queue available');
      return false;
    }

    // Check if already in queue
    if (currentQueue.containsAddress(receiverAddress)) {
      return false;
    }

    // Get current blockchain state for date calculation
    final storageService = ref.read(storageServiceProvider);
    final certData = await storageService.getCertsCounter(currentQueue.issuerAddress);
    final currentBlock = await storageService.getCurrentBlockHeight();
    final certPeriodBlocks = storageService.getCertPeriodBlocks();

    // Use max(blockchain, local) to avoid stale blockchain value after a recent cert execution
    // (same logic as _updateQueueDates)
    final blockchainNext = certData.nextIssuableOn;
    final localNext = currentQueue.nextIssuableOn;
    final effectiveNext = (blockchainNext != null && localNext != null)
        ? (blockchainNext > localNext ? blockchainNext : localNext)
        : (blockchainNext ?? localNext);

    final position = currentQueue.queueLength + 1;
    final blockTimeSeconds = storageService.currencyConstants.blockTimeSeconds;

    // Compute cert-specific minimum constraint block (e.g. canRenewIn delay)
    int? minAvailableBlock;
    if (certState != null && certState.duration != null) {
      final minBlock =
          currentBlock + (certState.duration!.inSeconds / (blockTimeSeconds > 0 ? blockTimeSeconds : 6)).ceil();
      minAvailableBlock = minBlock;
    }

    // Position-based expected block
    var expectedBlock = (effectiveNext ?? currentBlock) + ((position - 1) * certPeriodBlocks);

    // Enforce cert-specific minimum (e.g. canRenewIn delay)
    if (minAvailableBlock != null && minAvailableBlock > expectedBlock) {
      expectedBlock = minAvailableBlock;
    }

    // Derive date from the already-constrained block
    final blocksUntil = expectedBlock - currentBlock;
    final finalDate = blocksUntil <= 0
        ? DateTime.now()
        : DateTime.now().add(Duration(seconds: blocksUntil * blockTimeSeconds));

    final newCert = d.PendingCertification(
      id: const Uuid().v4(),
      receiverAddress: receiverAddress,
      receiverIndex: receiverIndex,
      receiverUid: receiverUid,
      receiverName: receiverName,
      addedAt: DateTime.now(),
      expectedAvailableBlock: expectedBlock,
      expectedAvailableDate: finalDate,
      position: position,
      certType: certType,
      minAvailableBlock: minAvailableBlock,
    );

    final newCertifications = [...currentQueue.pendingCertifications, newCert];
    final newQueue = currentQueue.copyWith(
      pendingCertifications: newCertifications,
      lastUpdated: DateTime.now(),
      isSynced: false, // Mark as needing sync
    );

    state = AsyncValue.data(newQueue);
    await CertificationQueueService.saveQueue(newQueue);

    return true;
  }

  /// Remove a certification from the queue
  Future<void> removeFromQueue(String certificationId) async {
    final currentQueue = state.value;
    if (currentQueue == null) return;

    final newCertifications = currentQueue.pendingCertifications.where((c) => c.id != certificationId).toList();

    // Update positions
    for (var i = 0; i < newCertifications.length; i++) {
      newCertifications[i] = newCertifications[i].copyWith(position: i + 1);
    }

    var newQueue = currentQueue.copyWith(
      pendingCertifications: newCertifications,
      lastUpdated: DateTime.now(),
      isSynced: false, // Mark as needing sync
    );

    // Update dates
    newQueue = await _updateQueueDates(newQueue);

    state = AsyncValue.data(newQueue);
    await CertificationQueueService.saveQueue(newQueue);
  }

  /// Remove a certification that was just executed.
  /// Optimistically updates nextIssuableOn so remaining items get correct future dates
  /// and the next cert is NOT falsely marked as "ready".
  Future<void> removeExecutedCertification(String certificationId) async {
    final currentQueue = state.value;
    if (currentQueue == null) return;

    final newCertifications = currentQueue.pendingCertifications.where((c) => c.id != certificationId).toList();

    // Update positions
    for (var i = 0; i < newCertifications.length; i++) {
      newCertifications[i] = newCertifications[i].copyWith(position: i + 1);
    }

    // Optimistically compute the new nextIssuableOn:
    // A certification was just executed, so the issuer's cooldown resets to currentBlock + certPeriod
    try {
      final storageService = ref.read(storageServiceProvider);
      final currentBlock = await storageService.getCurrentBlockHeight();
      final certPeriodBlocks = storageService.getCertPeriodBlocks();
      final optimisticNextIssuable = currentBlock + certPeriodBlocks;

      var newQueue = currentQueue.copyWith(
        pendingCertifications: newCertifications,
        nextIssuableOn: optimisticNextIssuable,
        lastUpdated: DateTime.now(),
        isSynced: false,
      );

      // Recalculate dates using the optimistic nextIssuableOn
      newQueue = CertificationQueueService.updateExpectedDates(
        queue: newQueue,
        certPeriodBlocks: certPeriodBlocks,
        currentBlockNumber: currentBlock,
        nextIssuableBlock: optimisticNextIssuable,
        blockTimeSeconds: storageService.currencyConstants.blockTimeSeconds,
      );
      // Preserve lastUpdated and isSynced (updateExpectedDates doesn't touch them)
      newQueue = newQueue.copyWith(lastUpdated: DateTime.now(), isSynced: false);

      state = AsyncValue.data(newQueue);
      await CertificationQueueService.saveQueue(newQueue);
    } catch (e) {
      log.e('[CertQueueExecuted] Error computing optimistic dates: $e');
      await removeFromQueue(certificationId);
    }
  }

  /// Remove a certification by receiver address
  Future<void> removeByAddress(String receiverAddress) async {
    final currentQueue = state.value;
    if (currentQueue == null) return;

    final cert = currentQueue.getCertificationByAddress(receiverAddress);
    if (cert != null) {
      await removeFromQueue(cert.id);
    }
  }

  /// Reorder certifications in the queue
  Future<void> reorder(int oldIndex, int newIndex) async {
    final currentQueue = state.value;
    if (currentQueue == null) return;

    final certifications = List<d.PendingCertification>.from(currentQueue.pendingCertifications);

    // `newIndex` already accounts for the removed item (onReorderItem semantics),
    // so no `if (oldIndex < newIndex) newIndex -= 1` adjustment is needed here.
    final item = certifications.removeAt(oldIndex);
    certifications.insert(newIndex, item);

    // Update positions
    for (var i = 0; i < certifications.length; i++) {
      certifications[i] = certifications[i].copyWith(position: i + 1);
    }

    var newQueue = currentQueue.copyWith(
      pendingCertifications: certifications,
      lastUpdated: DateTime.now(),
      isSynced: false, // Mark as needing sync
    );

    // Update dates
    newQueue = await _updateQueueDates(newQueue);

    state = AsyncValue.data(newQueue);
    await CertificationQueueService.saveQueue(newQueue);
  }

  /// Pull the remote queue from CesiumPlus and update local state if remote is newer.
  /// This is a read-only operation (no PIN required).
  /// Returns true if the local state was updated from remote.
  Future<bool> pullFromRemote() async {
    try {
      final durt = ref.read(durtProvider);

      // Skip if CesiumPlus is not ready (don't block, just skip)
      if (durt.datapodConnectionStatus != d.ConnectionStatus.connected) {
        return false;
      }

      final cesiumPlus = ref.read(cesiumPlusServiceProvider);
      final remoteQueue = await cesiumPlus.getCertificationQueue(issuerAddress);

      if (remoteQueue == null) return false;

      // Compare lastUpdated timestamps to decide if update is needed
      final localQueue = state.value;
      if (localQueue != null && !localQueue.lastUpdated.isBefore(remoteQueue.lastUpdated)) {
        return false;
      }

      // Remote is newer - use it
      var finalQueue = await _updateQueueDates(remoteQueue);
      finalQueue = finalQueue.copyWith(isSynced: true);

      state = AsyncValue.data(finalQueue);
      await CertificationQueueService.saveQueue(finalQueue);

      return true;
    } catch (e) {
      log.e('[CertQueuePull] Error: $e');
      return false;
    }
  }

  /// Force refresh the queue (re-sync from remote)
  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  /// Clear local queue data (use when deleting safe)
  Future<void> clearLocalData() async {
    await CertificationQueueService.deleteQueue(issuerAddress);
    state = AsyncValue.data(d.CertificationQueueState.empty(issuerAddress));
  }
}

/// Provider for the certification queue - keyed by issuer address
final certificationQueueProvider =
    AsyncNotifierProvider.family<CertificationQueueNotifier, d.CertificationQueueState?, String>(
      (issuerAddress) => CertificationQueueNotifier(issuerAddress),
    );

/// Notifier for ready certification notifications - keyed by issuer address
class ReadyCertificationNotifier extends Notifier<d.PendingCertification?> {
  final String issuerAddress;

  ReadyCertificationNotifier(this.issuerAddress);

  @override
  d.PendingCertification? build() => null;

  /// Notify that a certification is ready
  void notify(d.PendingCertification cert) {
    state = cert;
  }

  /// Clear the notification
  void clear() {
    state = null;
  }

  /// Dismiss (snooze) the notification
  void dismiss() {
    state = null;
  }
}

/// Provider for ready certification notifications - keyed by issuer address
final readyCertificationNotifierProvider =
    NotifierProvider.family<ReadyCertificationNotifier, d.PendingCertification?, String>(
      (issuerAddress) => ReadyCertificationNotifier(issuerAddress),
    );

/// Provider for the certification button state for a specific target address
/// Takes (issuerAddress, targetAddress) as parameters
final certButtonStateProvider = FutureProvider.family<CertButtonState, ({String issuerAddress, String targetAddress})>((
  ref,
  params,
) async {
  final issuerAddress = params.issuerAddress;
  final targetAddress = params.targetAddress;

  // Check storage state first
  final storageState = ref.watch(storageStateProvider);
  if (storageState == StorageState.notInitialized) {
    return const CertButtonState(action: CertButtonAction.none);
  }

  // Check if target address has been migrated (identity moved away via changeOwnerKey)
  // If so, block certification to avoid confusion with the old address
  final migrationFrom = await ref.watch(
    migrationDataProvider((direction: MigrationDirection.from, address: targetAddress)).future,
  );
  if (migrationFrom != null) {
    return const CertButtonState(action: CertButtonAction.disabled, disabledReason: 'migratedAccountCannotBeCertified');
  }

  // Watch the recent certifications provider to trigger rebuilds when state changes
  ref.watch(recentCertificationsProvider);
  final recentCertsNotifier = ref.read(recentCertificationsProvider.notifier);

  // CRITICAL: Check if certification is currently in progress FIRST
  // This shows "Certification en cours" instead of "Vous devez attendre..."
  final isInProgressNow = recentCertsNotifier.isInProgress(issuerAddress, targetAddress);
  if (isInProgressNow) {
    return const CertButtonState(action: CertButtonAction.inProgress);
  }

  // Check if we recently completed a certification (local cache, not blockchain)
  // This prevents showing "add to queue" immediately after certifying when blockchain hasn't propagated yet
  final wasCertifiedRecently = recentCertsNotifier.wasCertifiedRecently(issuerAddress, targetAddress);

  // Get cert state - AWAIT the future to get fresh data
  final certState = await ref.watch(certStateProvider(targetAddress).future);

  // Get queue state for this specific issuer
  final queueAsync = ref.watch(certificationQueueProvider(issuerAddress));
  final queue = queueAsync.value;

  // Check if target is in queue
  final pendingCert = queue?.getCertificationByAddress(targetAddress);
  final isInQueue = pendingCert != null;

  // If we recently certified this person, always show disabled state
  // This is the MOST RELIABLE check as it doesn't depend on blockchain propagation
  if (wasCertifiedRecently) {
    // Get the cert period duration from storage to calculate estimated wait time
    final storageService = ref.read(storageServiceProvider);
    final certPeriodDuration = storageService.getCertPeriodDuration();

    // Create a certState with estimated duration if the real one doesn't have it
    final effectiveCertState = (certState?.duration == null || certState!.duration == Duration.zero)
        ? d.CertState(status: d.CertStatus.mustWaitBeforeCert, duration: certPeriodDuration)
        : certState;

    return CertButtonState(
      action: CertButtonAction.disabled,
      certState: effectiveCertState,
      disabledReason: 'justCertified',
    );
  }

  // If no cert state, return none
  if (certState == null) {
    if (isInQueue) {
      return CertButtonState(action: CertButtonAction.inQueue, pendingCert: pendingCert);
    }
    return const CertButtonState(action: CertButtonAction.none);
  }

  // Determine action based on cert state and queue state
  switch (certState.status) {
    case d.CertStatus.none:
      return const CertButtonState(action: CertButtonAction.none);

    case d.CertStatus.canCert:
      // If this target is in queue and ready, execute it
      if (pendingCert != null && pendingCert.isReady) {
        return CertButtonState(action: CertButtonAction.executeQueued, certState: certState, pendingCert: pendingCert);
      }

      // If this target is already in queue (but not ready yet), show inQueue
      if (pendingCert != null) {
        return CertButtonState(action: CertButtonAction.inQueue, certState: certState, pendingCert: pendingCert);
      }

      // CRITICAL: If queue is not empty, this target must go to the queue
      // to respect the queue order - even if we can technically certify now
      if (queue != null && !queue.isEmpty) {
        return CertButtonState(action: CertButtonAction.addToQueue, certState: certState);
      }

      // Queue is empty, can certify directly
      return CertButtonState(action: CertButtonAction.certifyNow, certState: certState);

    case d.CertStatus.canRenewIn:
    case d.CertStatus.mustWaitBeforeCert:
      // Both cases involve waiting before the user can certify.
      // Always propose the queue so the user can schedule the certification/renewal.
      // The wasCertifiedRecently guard (above) already prevents showing the queue
      // button immediately after certifying.
      if (pendingCert != null) {
        if (pendingCert.isReady) {
          return CertButtonState(
            action: CertButtonAction.executeQueued,
            certState: certState,
            pendingCert: pendingCert,
          );
        }
        return CertButtonState(action: CertButtonAction.inQueue, certState: certState, pendingCert: pendingCert);
      }
      return CertButtonState(action: CertButtonAction.addToQueue, certState: certState);

    case d.CertStatus.mustConfirmIdentity:
      return CertButtonState(
        action: CertButtonAction.disabled,
        certState: certState,
        disabledReason: 'mustConfirmHisIdentity',
      );

    case d.CertStatus.emptyWallet:
      return CertButtonState(
        action: CertButtonAction.disabled,
        certState: certState,
        disabledReason: 'emptyWalletCannotBeCertified',
      );

    case d.CertStatus.revoked:
      return CertButtonState(
        action: CertButtonAction.disabled,
        certState: certState,
        disabledReason: 'revokedAccountCannotBeCertified',
      );
  }
});

/// Provider to check if the queue has any items - keyed by issuer address
final hasQueueItemsProvider = Provider.family<bool, String>((ref, issuerAddress) {
  final queueAsync = ref.watch(certificationQueueProvider(issuerAddress));
  return queueAsync.value?.isEmpty == false;
});

/// Provider to check if there's a ready certification - keyed by issuer address
final hasReadyCertificationProvider = Provider.family<bool, String>((ref, issuerAddress) {
  final queueAsync = ref.watch(certificationQueueProvider(issuerAddress));
  return queueAsync.value?.hasReadyCertification ?? false;
});

/// Provider for the queue length - keyed by issuer address
final queueLengthProvider = Provider.family<int, String>((ref, issuerAddress) {
  final queueAsync = ref.watch(certificationQueueProvider(issuerAddress));
  return queueAsync.value?.queueLength ?? 0;
});
