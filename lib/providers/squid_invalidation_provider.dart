import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/squid_cache_buster.dart';

/// Provider that listens to Squid endpoint changes and invalidates affected providers
final squidEndpointInvalidatorProvider = StreamProvider<String>((ref) {
  final durt = ref.watch(durtProvider);

  // Listen to Squid endpoint changes
  return durt.squidEndpointChangeStream;
});

/// Provider that tracks Squid endpoint changes and triggers invalidation
final squidEndpointChangeNotifierProvider = Provider<void>((ref) {
  // Watch for Squid endpoint changes
  ref.listen(squidEndpointInvalidatorProvider, (previous, next) {
    next.whenData((endpoint) {
      log.i('🔔 Squid endpoint changed to: $endpoint - invalidating affected providers');

      // Invalidate all providers that depend on Squid data
      _invalidateSquidDependentProviders(ref);
    });
  });
});

/// Invalidate all providers that depend on Squid data
void _invalidateSquidDependentProviders(Ref ref) {
  try {
    log.i('🔄 Starting NUCLEAR invalidation of Squid-dependent providers');

    // NUCLEAR APPROACH: Clear everything and force rebuild

    // 1. Invalidate the core service providers
    ref.invalidate(squidServiceProvider);
    ref.invalidate(durtProvider);

    // 2. Trigger cache buster to force refresh of all StateNotifierProviders
    final currentBuster = ref.read(squidCacheBusterProvider);
    ref.read(squidCacheBusterProvider.notifier).state = currentBuster + 1;
    log.i('🔥 Cache buster incremented to ${currentBuster + 1}');

    // 3. Force a complete refresh by invalidating self
    ref.invalidateSelf();

    log.i('✅ Completed NUCLEAR invalidation - all Squid data should be refreshed');
  } catch (e) {
    log.e('❌ Error invalidating Squid-dependent providers: $e');
  }
}
