import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:gecko/globals.dart';

/// Simple cache buster that changes when Squid endpoint changes
/// This forces all dependent providers to rebuild completely
final squidCacheBusterProvider = StateProvider<int>((ref) => 0);

/// Increment the cache buster to force refresh of all Squid-dependent providers
void forceSquidProviderRefresh(WidgetRef ref) {
  try {
    log.i('🔥 FORCING complete Squid provider refresh with cache buster');

    // Increment the cache buster - this will force ALL providers that watch it to rebuild
    final currentValue = ref.read(squidCacheBusterProvider);
    ref.read(squidCacheBusterProvider.notifier).state = currentValue + 1;

    log.i('🔥 Cache buster incremented to ${currentValue + 1} - all dependent providers will rebuild');
  } catch (e) {
    log.e('❌ Error forcing Squid provider refresh: $e');
  }
}
