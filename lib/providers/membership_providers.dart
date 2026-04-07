import 'package:durt2/durt2.dart' show MembershipStatus;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/block_height_provider.dart';
import 'package:gecko/providers/certification_list_providers.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/stream_providers.dart';
import 'package:gecko/widgets/certs_list.dart' show CertDirection;

/// Reactive provider for membership status of a given address.
///
/// Watches storageState and hybridIdtyStatus for reactivity,
/// and refreshes on block height changes (throttled every 10 blocks).
class MembershipStatusNotifier extends AsyncNotifier<MembershipStatus> {
  MembershipStatusNotifier(this.arg);
  final String arg;

  int _lastRefreshBlock = 0;

  @override
  Future<MembershipStatus> build() async {
    final address = arg;

    // Return empty if storage not initialized
    final storageState = ref.watch(storageStateProvider);
    if (storageState == StorageState.notInitialized) {
      return MembershipStatus.empty();
    }

    // Watch identity status to rebuild when it changes
    ref.watch(hybridIdtyStatusProvider(address));

    // Refresh renewal eligibility whenever the number of received certifications
    // changes — canRenew depends on the distance rule which needs ≥ 5 certs.
    // Without this, users reported a stale "cannot renew yet" state after
    // reaching 5 certs. We `select` on count + the latest activity id to avoid
    // rebuilding on every loading/error state transition of the cert list.
    ref.watch(
      certificationListProvider((
        address: address,
        direction: CertDirection.received,
      )).select((s) => (s.certifications.length, s.lastActivityId)),
    );

    // Listen to block height with throttle (refresh every 10 blocks ~60s)
    ref.listen(blockHeightProvider, (previous, next) {
      if (next == 0 || next == previous) return;
      if (next - _lastRefreshBlock >= 10) {
        _lastRefreshBlock = next;
        _refresh(address);
      }
    });

    final storageService = ref.read(storageServiceProvider);
    final status = await storageService.getMembershipStatus(address);
    _lastRefreshBlock = ref.read(blockHeightProvider);
    return status;
  }

  void _refresh(String address) async {
    final storageState = ref.read(storageStateProvider);
    if (storageState == StorageState.notInitialized) return;

    try {
      final storageService = ref.read(storageServiceProvider);
      final newStatus = await storageService.getMembershipStatus(address);
      state = AsyncValue.data(newStatus);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void forceRefresh() {
    _lastRefreshBlock = 0;
    ref.invalidateSelf();
  }
}

/// Provides reactive membership status for a given address.
final membershipStatusProvider = AsyncNotifierProvider.family<MembershipStatusNotifier, MembershipStatus, String>(
  MembershipStatusNotifier.new,
);
