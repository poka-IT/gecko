import 'package:durt2/durt2.dart' hide Provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers.dart';

/// Cache state for certifications
class CertificationsCache {
  final Map<String, CertificationData> _cache = {};
  final Map<String, DateTime> _lastUpdated = {};
  final Duration _cacheValidDuration = const Duration(minutes: 5);

  /// Get cached data for an address
  CertificationData? getCachedData(String address) {
    return _cache[address];
  }

  /// Check if cached data is still valid
  bool isCacheValid(String address) {
    final lastUpdate = _lastUpdated[address];
    if (lastUpdate == null) return false;
    return DateTime.now().difference(lastUpdate) < _cacheValidDuration;
  }

  /// Update cache with new data
  void updateCache(String address, CertificationData data) {
    _cache[address] = data;
    _lastUpdated[address] = DateTime.now();
  }

  /// Clear cache for an address
  void clearCache(String address) {
    _cache.remove(address);
    _lastUpdated.remove(address);
  }

  /// Clear all cache
  void clearAllCache() {
    _cache.clear();
    _lastUpdated.clear();
  }
}

/// State for certification data with loading state
class CertificationState {
  final CertificationData? data;
  final bool isLoading;
  final String? error;

  const CertificationState({this.data, this.isLoading = false, this.error});

  CertificationState copyWith({CertificationData? data, bool? isLoading, String? error}) {
    return CertificationState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Notifier for managing certification cache
class CertificationsCacheNotifier extends StateNotifier<Map<String, CertificationState>> {
  final Ref ref;
  final CertificationsCache _cache = CertificationsCache();

  CertificationsCacheNotifier(this.ref) : super({});

  /// Get certification data for an address
  /// Returns cached data immediately if available, and updates in background
  Future<CertificationData?> getCertificationData(String address) async {
    // Check if we have cached data
    final cachedData = _cache.getCachedData(address);

    // If we have cached data, show it immediately
    if (cachedData != null) {
      // Update state with cached data
      state = {
        ...state,
        address: CertificationState(
          data: cachedData,
          isLoading: !_cache.isCacheValid(address), // Show loading if cache is old
        ),
      };

      // If cache is still valid, return cached data
      if (_cache.isCacheValid(address)) {
        return cachedData;
      }
    } else {
      // No cached data, show loading state
      state = {...state, address: const CertificationState(isLoading: true)};
    }

    // Always fetch fresh data in background
    try {
      final freshData = await ref.read(storageServiceProvider).getCertsCounter(address);

      // Update cache
      _cache.updateCache(address, freshData);

      // Update state with fresh data
      state = {...state, address: CertificationState(data: freshData, isLoading: false)};

      return freshData;
    } catch (e) {
      // If fetch fails but we have cached data, keep showing cached data
      if (cachedData != null) {
        state = {...state, address: CertificationState(data: cachedData, isLoading: false, error: e.toString())};
        return cachedData;
      } else {
        // No cached data and fetch failed
        state = {...state, address: CertificationState(isLoading: false, error: e.toString())};
        return null;
      }
    }
  }

  /// Force refresh for an address
  Future<void> forceRefresh(String address) async {
    _cache.clearCache(address);
    await getCertificationData(address);
  }

  /// Clear all cache
  void clearAllCache() {
    _cache.clearAllCache();
    state = {};
  }
}

/// Provider for certifications cache
final certificationsCacheProvider = StateNotifierProvider<CertificationsCacheNotifier, Map<String, CertificationState>>(
  (ref) {
    return CertificationsCacheNotifier(ref);
  },
);

/// Helper provider to get certification data for a specific address
final certificationDataProvider = Provider.family<CertificationState?, String>((ref, address) {
  final cacheState = ref.watch(certificationsCacheProvider);
  return cacheState[address];
});
