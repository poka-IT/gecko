import 'dart:async';
import 'dart:typed_data';
import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/stream_providers.dart';
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
    log.d('🔒 [RecentCerts] In progress: $key');
  }

  /// Mark that a certification transaction completed successfully
  void markCompleted(String issuerAddress, String targetAddress) {
    final key = '$issuerAddress:$targetAddress';
    final existing = state[key];
    if (existing != null) {
      state = {...state, key: existing.copyWith(certState: RecentCertState.completed)};
      log.d('🔒 [RecentCerts] Completed: $key');
    } else {
      // If not in state (edge case), add as completed
      state = {...state, key: RecentCertData(timestamp: DateTime.now(), certState: RecentCertState.completed)};
      log.d('🔒 [RecentCerts] Added as completed: $key');
    }

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

    final isRecent = DateTime.now().difference(data.timestamp).inMinutes < 10;
    if (isRecent) {
      log.d('🔒 [RecentCerts] Found recent certification: $key');
    }
    return isRecent;
  }

  /// Remove a certification from cache (e.g., when transaction fails)
  void removeCertification(String issuerAddress, String targetAddress) {
    final key = '$issuerAddress:$targetAddress';
    if (state.containsKey(key)) {
      final newState = Map<String, RecentCertData>.from(state);
      newState.remove(key);
      state = newState;
      log.d('🔒 [RecentCerts] Removed (tx failed): $key');
    }
  }

  void _cleanup(String key) {
    if (state.containsKey(key)) {
      final newState = Map<String, RecentCertData>.from(state);
      newState.remove(key);
      state = newState;
      log.d('🔒 [RecentCerts] Cleaned up: $key');
    }
  }
}

/// Provider for recent certifications cache
final recentCertificationsProvider =
    NotifierProvider<RecentCertificationsNotifier, Map<String, RecentCertData>>(RecentCertificationsNotifier.new);

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
  Timer? _checkTimer;

  CertificationQueueNotifier(this.issuerAddress);

  @override
  FutureOr<d.CertificationQueueState?> build() async {
    log.d('🔧 [CertQueueProvider] Building for issuer: $issuerAddress');

    // Clean up timer on dispose
    ref.onDispose(() {
      log.d('🔧 [CertQueueProvider] Disposing for issuer: $issuerAddress');
      _checkTimer?.cancel();
    });

    // Check storage state first
    final storageState = ref.watch(storageStateProvider);
    if (storageState == StorageState.notInitialized) {
      log.d('🔧 [CertQueueProvider] Storage not initialized, returning null');
      return null;
    }

    // Load from local storage first
    log.d('🔧 [CertQueueProvider] Loading from local storage...');
    var queue = await CertificationQueueService.loadQueue(issuerAddress);

    // If no local queue, create an empty one
    if (queue == null) {
      log.d('🔧 [CertQueueProvider] No local queue, creating empty queue');
      queue = d.CertificationQueueState.empty(issuerAddress);
    }

    // Update expected dates based on current blockchain state
    queue = await _updateQueueDates(queue);

    // Start periodic check for ready certifications
    _startPeriodicCheck();

    // Sync with CesiumPlus in background (don't block UI)
    log.d('🔧 [CertQueueProvider] Starting background CesiumPlus sync...');
    _syncWithCesiumPlus();

    return queue;
  }

  /// Update the expected dates in the queue based on current blockchain state
  Future<d.CertificationQueueState> _updateQueueDates(d.CertificationQueueState queue) async {
    try {
      final storageService = ref.read(storageServiceProvider);
      final certData = await storageService.getCertsCounter(queue.issuerAddress);
      final currentBlock = await storageService.getCurrentBlockHeight();
      final genesisTime = await storageService.getGenesisBlockchainTime();
      final certPeriodBlocks = storageService.getCertPeriodBlocks();

      return CertificationQueueService.updateExpectedDates(
        queue: queue,
        certPeriodBlocks: certPeriodBlocks,
        currentBlockNumber: currentBlock,
        nextIssuableBlock: certData.nextIssuableOn,
        genesisTime: genesisTime,
      );
    } catch (e) {
      log.e('🔧 [CertQueueProvider] Error updating queue dates: $e');
      return queue;
    }
  }

  /// Start periodic check for ready certifications (every 30 seconds)
  void _startPeriodicCheck() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _checkAndNotifyReadyCertifications();
    });
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
        log.d('🔔 [CertQueueProvider] Certification ready for ${readyCert.receiverAddress}');
        ref.read(readyCertificationNotifierProvider(issuerAddress).notifier).notify(readyCert);
      }
    }

    // Update state if dates changed
    state = AsyncValue.data(updatedQueue);

    // Save updated queue locally
    await CertificationQueueService.saveQueue(updatedQueue);
  }

  /// Sync with CesiumPlus - PULL remote data first, then merge
  Future<void> _syncWithCesiumPlus() async {
    log.d('🔄 [CertQueueSync] ====== STARTING SYNC for $issuerAddress ======');

    try {
      final cesiumPlus = ref.read(cesiumPlusServiceProvider);
      final durt = ref.read(durtProvider);

      // Wait for Duniter to be connected (up to 10 seconds)
      if (!durt.isConnected) {
        log.d('🔄 [CertQueueSync] Waiting for Duniter connection...');
        int attempts = 0;
        while (!durt.isConnected && attempts < 20) {
          await Future.delayed(const Duration(milliseconds: 500));
          attempts++;
        }
        if (!durt.isConnected) {
          log.w('🔄 [CertQueueSync] Duniter not connected after 10s, skipping sync');
          return;
        }
        log.d('🔄 [CertQueueSync] Duniter connected after ${attempts * 500}ms');
      }

      // 1. PULL: Fetch remote queue from CesiumPlus
      log.d('🔄 [CertQueueSync] Step 1: Fetching remote queue from CesiumPlus...');
      d.CertificationQueueState? remoteQueue;

      try {
        remoteQueue = await cesiumPlus.getCertificationQueue(issuerAddress);
        if (remoteQueue != null) {
          log.d(
            '🔄 [CertQueueSync] Remote queue found: ${remoteQueue.queueLength} items, '
            'lastUpdated: ${remoteQueue.lastUpdated}',
          );
        } else {
          log.d('🔄 [CertQueueSync] No remote queue exists on CesiumPlus');
        }
      } catch (e) {
        log.e('🔄 [CertQueueSync] Error fetching remote queue: $e');
        // Continue with local-only mode
      }

      // 2. Get current local state
      final localQueue = state.value;
      log.d(
        '🔄 [CertQueueSync] Local queue: ${localQueue?.queueLength ?? 0} items, '
        'lastUpdated: ${localQueue?.lastUpdated}, isSynced: ${localQueue?.isSynced}',
      );

      // 3. MERGE: Determine which queue to use (last-write-wins)
      d.CertificationQueueState? mergedQueue;

      if (remoteQueue == null && localQueue == null) {
        log.d('🔄 [CertQueueSync] Both queues null, nothing to sync');
        return;
      } else if (remoteQueue == null) {
        // Only local exists - use local, mark as needing sync
        log.d('🔄 [CertQueueSync] Only local queue exists, will need to push');
        mergedQueue = localQueue!.copyWith(isSynced: localQueue.isEmpty);
      } else if (localQueue == null || localQueue.isEmpty) {
        // Only remote exists or local is empty - use remote
        log.d('🔄 [CertQueueSync] Using remote queue (local empty or null)');
        mergedQueue = await _updateQueueDates(remoteQueue);
        mergedQueue = mergedQueue.copyWith(isSynced: true);
      } else {
        // Both exist - use last-write-wins
        log.d(
          '🔄 [CertQueueSync] Both queues exist. '
          'Remote: ${remoteQueue.lastUpdated}, Local: ${localQueue.lastUpdated}',
        );

        if (remoteQueue.lastUpdated.isAfter(localQueue.lastUpdated)) {
          log.d('🔄 [CertQueueSync] Remote is NEWER, using remote queue');
          mergedQueue = await _updateQueueDates(remoteQueue);
          mergedQueue = mergedQueue.copyWith(isSynced: true);
        } else if (localQueue.lastUpdated.isAfter(remoteQueue.lastUpdated)) {
          log.d('🔄 [CertQueueSync] Local is NEWER, keeping local (needs push)');
          mergedQueue = localQueue.copyWith(isSynced: false);
        } else {
          log.d('🔄 [CertQueueSync] Timestamps equal, marking as synced');
          mergedQueue = localQueue.copyWith(isSynced: true);
        }
      }

      // 4. Update state and save locally
      // Note: mergedQueue is guaranteed to be non-null here because we return early if both queues are null
      state = AsyncValue.data(mergedQueue);
      await CertificationQueueService.saveQueue(mergedQueue);
      log.d(
        '🔄 [CertQueueSync] Sync complete. Final state: ${mergedQueue.queueLength} items, '
        'isSynced: ${mergedQueue.isSynced}',
      );

      // 5. Check and notify if any certification is ready immediately after sync
      if (mergedQueue.hasReadyCertification) {
        final readyCert = mergedQueue.nextReadyCertification;
        if (readyCert != null) {
          log.d('🔔 [CertQueueSync] Certification ready after sync for ${readyCert.receiverAddress}');
          ref.read(readyCertificationNotifierProvider(issuerAddress).notifier).notify(readyCert);
        }
      }

      log.d('🔄 [CertQueueSync] ====== SYNC COMPLETE ======');
    } catch (e, stack) {
      log.e('🔄 [CertQueueSync] ====== SYNC FAILED ======');
      log.e('🔄 [CertQueueSync] Error: $e');
      log.e('🔄 [CertQueueSync] Stack: $stack');
    }
  }

  /// Push queue to CesiumPlus (requires sign function from PIN validation)
  /// Note: saveCertificationQueue automatically creates a minimal profile if none exists
  Future<bool> pushToRemote(Uint8List Function(Uint8List) signFunction) async {
    log.d('⬆️ [CertQueuePush] ====== PUSHING TO REMOTE ======');

    final currentQueue = state.value;
    if (currentQueue == null) {
      log.w('⬆️ [CertQueuePush] No queue to push');
      return false;
    }

    log.d(
      '⬆️ [CertQueuePush] Pushing queue: ${currentQueue.queueLength} items, '
      'lastUpdated: ${currentQueue.lastUpdated}',
    );

    try {
      final cesiumPlus = ref.read(cesiumPlusServiceProvider);

      // Check if profile exists (for logging purposes)
      log.d('⬆️ [CertQueuePush] Checking if CesiumPlus profile exists...');
      final hasProfile = await cesiumPlus.hasProfile(issuerAddress);
      log.d('⬆️ [CertQueuePush] Profile exists: $hasProfile');

      // Save the queue to CesiumPlus
      // Note: saveCertificationQueue automatically creates a minimal profile if none exists
      log.d('⬆️ [CertQueuePush] Saving queue to CesiumPlus...');
      final success = await cesiumPlus.saveCertificationQueue(
        address: issuerAddress,
        signFunction: signFunction,
        queue: currentQueue,
      );

      if (success) {
        log.d('⬆️ [CertQueuePush] ✅ Queue pushed successfully');
        final syncedQueue = currentQueue.copyWith(isSynced: true);
        state = AsyncValue.data(syncedQueue);
        await CertificationQueueService.saveQueue(syncedQueue);
      } else {
        log.e('⬆️ [CertQueuePush] ❌ Failed to push queue');
      }

      log.d('⬆️ [CertQueuePush] ====== PUSH COMPLETE ======');
      return success;
    } catch (e, stack) {
      log.e('⬆️ [CertQueuePush] ====== PUSH FAILED ======');
      log.e('⬆️ [CertQueuePush] Error: $e');
      log.e('⬆️ [CertQueuePush] Stack: $stack');
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
  }) async {
    log.d('➕ [CertQueueAdd] Adding $receiverAddress to queue');

    final currentQueue = state.value;
    if (currentQueue == null) {
      log.e('➕ [CertQueueAdd] No queue available');
      return false;
    }

    // Check if already in queue
    if (currentQueue.containsAddress(receiverAddress)) {
      log.w('➕ [CertQueueAdd] Address already in queue');
      return false;
    }

    // Get current blockchain state for date calculation
    final storageService = ref.read(storageServiceProvider);
    final certData = await storageService.getCertsCounter(currentQueue.issuerAddress);
    final currentBlock = await storageService.getCurrentBlockHeight();
    final genesisTime = await storageService.getGenesisBlockchainTime();
    final certPeriodBlocks = storageService.getCertPeriodBlocks();

    final position = currentQueue.queueLength + 1;

    final expectedDate = CertificationQueueService.calculateExpectedDate(
      position: position,
      certPeriodBlocks: certPeriodBlocks,
      currentBlockNumber: currentBlock,
      nextIssuableBlock: certData.nextIssuableOn,
      genesisTime: genesisTime,
    );

    final expectedBlock = (certData.nextIssuableOn ?? currentBlock) + ((position - 1) * certPeriodBlocks);

    final newCert = d.PendingCertification(
      id: const Uuid().v4(),
      receiverAddress: receiverAddress,
      receiverIndex: receiverIndex,
      receiverUid: receiverUid,
      receiverName: receiverName,
      addedAt: DateTime.now(),
      expectedAvailableBlock: expectedBlock,
      expectedAvailableDate: expectedDate,
      position: position,
      certType: certType,
    );

    final newCertifications = [...currentQueue.pendingCertifications, newCert];
    final newQueue = currentQueue.copyWith(
      pendingCertifications: newCertifications,
      lastUpdated: DateTime.now(),
      isSynced: false, // Mark as needing sync
    );

    state = AsyncValue.data(newQueue);
    await CertificationQueueService.saveQueue(newQueue);

    log.d('➕ [CertQueueAdd] Added successfully. Queue now has ${newQueue.queueLength} items');
    log.d('➕ [CertQueueAdd] Queue marked as NOT SYNCED - needs push to remote');

    return true;
  }

  /// Remove a certification from the queue
  Future<void> removeFromQueue(String certificationId) async {
    log.d('➖ [CertQueueRemove] Removing certification $certificationId');

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

    log.d('➖ [CertQueueRemove] Removed. Queue now has ${newQueue.queueLength} items');
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
    log.d('🔀 [CertQueueReorder] Reordering from $oldIndex to $newIndex');

    final currentQueue = state.value;
    if (currentQueue == null) return;

    final certifications = List<d.PendingCertification>.from(currentQueue.pendingCertifications);

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

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

    log.d('🔀 [CertQueueReorder] Reorder complete');
  }

  /// Force refresh the queue (re-sync from remote)
  Future<void> refresh() async {
    log.d('🔃 [CertQueueProvider] Force refresh requested');
    ref.invalidateSelf();
  }

  /// Clear local queue data (use when deleting safe)
  Future<void> clearLocalData() async {
    log.d('🗑️ [CertQueueProvider] Clearing local data for $issuerAddress');
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
final certButtonStateProvider =
    FutureProvider.family<CertButtonState, ({String issuerAddress, String targetAddress})>((ref, params) async {
  final issuerAddress = params.issuerAddress;
  final targetAddress = params.targetAddress;

  // Check storage state first
  final storageState = ref.watch(storageStateProvider);
  if (storageState == StorageState.notInitialized) {
    return const CertButtonState(action: CertButtonAction.none);
  }

  // Watch the recent certifications provider to trigger rebuilds when state changes
  ref.watch(recentCertificationsProvider);
  final recentCertsNotifier = ref.read(recentCertificationsProvider.notifier);

  // CRITICAL: Check if certification is currently in progress FIRST
  // This shows "Certification en cours" instead of "Vous devez attendre..."
  final isInProgressNow = recentCertsNotifier.isInProgress(issuerAddress, targetAddress);
  if (isInProgressNow) {
    log.d('🔄 [CertButtonState] Certification in progress for $targetAddress');
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

  // Check if a certification already exists to this target - AWAIT to get real value
  final certificationAlreadyExists = await ref.watch(certificationExistsProvider(targetAddress).future);

  // Get target's identity status to check if we just created their identity
  // CRITICAL: Use 'unknown' as fallback, NOT 'none'!
  // 'none' means "no identity exists" which would incorrectly trigger "Schedule invitation"
  // 'unknown' means "we don't know yet" and should be treated as "identity might exist"
  final targetIdtyStatusAsync = ref.watch(smartIdtyStatusStreamProvider(targetAddress));
  final targetIdtyStatus = targetIdtyStatusAsync.value ?? d.IdtyStatus.unknown;

  // Check if target is in queue
  final pendingCert = queue?.getCertificationByAddress(targetAddress);
  final isInQueue = pendingCert != null;

  // If we recently certified this person, always show disabled state
  // This is the MOST RELIABLE check as it doesn't depend on blockchain propagation
  if (wasCertifiedRecently) {
    log.d('🔒 [CertButtonState] Recently certified $targetAddress, forcing disabled state');

    // Get the cert period duration from storage to calculate estimated wait time
    final storageService = ref.read(storageServiceProvider);
    final certPeriodDuration = storageService.getCertPeriodDuration();

    // Create a certState with estimated duration if the real one doesn't have it
    final effectiveCertState = (certState?.duration == null || certState!.duration == Duration.zero)
        ? d.CertState(
            status: d.CertStatus.mustWaitBeforeCert,
            duration: certPeriodDuration,
          )
        : certState;

    return CertButtonState(
      action: CertButtonAction.disabled,
      certState: effectiveCertState,
      disabledReason: 'mustWaitXBeforeCertify',
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
        return CertButtonState(
          action: CertButtonAction.executeQueued,
          certState: certState,
          pendingCert: pendingCert,
        );
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
      // Certification already exists - just show info, don't propose to add to queue
      // (User just certified this person, no need to plan another certification)
      if (pendingCert != null) {
        // If somehow in queue, allow execution when ready
        if (pendingCert.isReady) {
          return CertButtonState(
            action: CertButtonAction.executeQueued,
            certState: certState,
            pendingCert: pendingCert,
          );
        }
        return CertButtonState(action: CertButtonAction.inQueue, certState: certState, pendingCert: pendingCert);
      }
      // Show disabled state with renewal info
      return CertButtonState(
        action: CertButtonAction.disabled,
        certState: certState,
        disabledReason: 'canRenewCertInX',
      );

    case d.CertStatus.mustWaitBeforeCert:
      // Issuer's cooldown is active
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

      // Determine if we should show disabled state or propose adding to queue
      // Show disabled if:
      // 1. certificationAlreadyExists is true (blockchain confirms certification exists)
      // 2. Target has an identity (member, confirmed, created, etc.) - we just created it via invitation
      // 3. Target status is unknown (loading) - don't show "Schedule invitation" prematurely
      final hasIdentityOrUnknown = targetIdtyStatus != d.IdtyStatus.none;

      if (certificationAlreadyExists || hasIdentityOrUnknown) {
        // Choose the appropriate disabled reason based on what we know
        final disabledReason = certificationAlreadyExists
            ? 'canRenewCertInX' // We know cert exists, show renewal message
            : (targetIdtyStatus == d.IdtyStatus.unknown
                ? 'mustWaitXBeforeCertify' // Status unknown, show generic cooldown message
                : 'canRenewCertInX'); // Identity exists, show renewal message

        return CertButtonState(
          action: CertButtonAction.disabled,
          certState: certState,
          disabledReason: disabledReason,
        );
      }

      // Only propose to add to queue if target truly has NO identity
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
