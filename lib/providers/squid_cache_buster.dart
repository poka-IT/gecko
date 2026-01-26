import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';

/// Notifier for squid cache buster
class SquidCacheBusterNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state = state + 1;
}

/// Simple cache buster that changes when Squid endpoint changes
/// This forces all dependent providers to rebuild completely
final squidCacheBusterProvider = NotifierProvider<SquidCacheBusterNotifier, int>(SquidCacheBusterNotifier.new);

/// Increment the cache buster to force refresh of all Squid-dependent providers
void forceSquidProviderRefresh(WidgetRef ref) {
  try {
    log.i('🔥 FORCING complete Squid provider refresh with cache buster');

    // Increment the cache buster - this will force ALL providers that watch it to rebuild
    final currentValue = ref.read(squidCacheBusterProvider);
    ref.read(squidCacheBusterProvider.notifier).increment();

    log.i('🔥 Cache buster incremented to ${currentValue + 1} - all dependent providers will rebuild');
  } catch (e) {
    log.e('❌ Error forcing Squid provider refresh: $e');
  }
}
