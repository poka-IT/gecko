import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/services/distance_service.dart';

/// Sealed state for the distance/quality computation.
sealed class DistanceState {
  const DistanceState();
}

class DistanceIdle extends DistanceState {
  const DistanceIdle();
}

class DistanceComputing extends DistanceState {
  final double progress;
  const DistanceComputing(this.progress);
}

class DistanceCompleted extends DistanceState {
  final DistanceResult result;
  const DistanceCompleted(this.result);
}

class DistanceError extends DistanceState {
  final String message;
  const DistanceError(this.message);
}

/// Notifier for distance/quality computation, keyed by address.
class DistanceNotifier extends Notifier<DistanceState> {
  DistanceNotifier(this.address);
  final String address;

  // Static cache with TTL (shared across instances)
  static final Map<String, _CachedResult> _cache = {};
  static const _cacheTtl = Duration(hours: 1);

  @override
  DistanceState build() {
    // Check cache
    final cached = _cache[address];
    if (cached != null && DateTime.now().difference(cached.timestamp) < _cacheTtl) {
      return DistanceCompleted(cached.result);
    }
    return const DistanceIdle();
  }

  /// Manually trigger the distance/quality computation.
  Future<void> compute() async {
    // Don't re-compute if already computing
    if (state is DistanceComputing) return;

    state = const DistanceComputing(0.0);

    try {
      final storageService = ref.read(storageServiceProvider);
      final idtyIndex = await storageService.getIdentityIndexOf(address);

      if (idtyIndex == null) {
        state = const DistanceError('noIdentity');
        return;
      }

      final result = await DistanceService.computeDistanceAndQuality(
        accountIndex: idtyIndex,
        onProgress: (progress) {
          state = DistanceComputing(progress);
        },
      );

      // Cache the result
      _cache[address] = _CachedResult(result: result, timestamp: DateTime.now());

      state = DistanceCompleted(result);
    } catch (e) {
      state = DistanceError(e.toString());
    }
  }
}

class _CachedResult {
  final DistanceResult result;
  final DateTime timestamp;
  const _CachedResult({required this.result, required this.timestamp});
}

/// Provider for distance/quality computation, keyed by address.
final distanceProvider = NotifierProvider.family<DistanceNotifier, DistanceState, String>(DistanceNotifier.new);
