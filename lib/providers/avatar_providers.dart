import 'dart:typed_data';
import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/providers.dart';

/// Avatar cache provider using Riverpod
final avatarCacheProvider = StateNotifierProvider<AvatarCacheNotifier, Map<String, Uint8List?>>((ref) {
  return AvatarCacheNotifier(ref);
});

/// Provider to get avatar for a specific address
final avatarProvider = FutureProvider.family<Uint8List?, String>((ref, address) async {
  final avatarCache = ref.read(avatarCacheProvider.notifier);
  return await avatarCache.getAvatar(address);
});

/// Avatar cache notifier that manages avatar downloading and caching
class AvatarCacheNotifier extends StateNotifier<Map<String, Uint8List?>> {
  final Ref ref;

  AvatarCacheNotifier(this.ref) : super({});

  /// Get avatar for an address, with caching
  Future<Uint8List?> getAvatar(String address) async {
    try {
      // Check if already cached
      if (state.containsKey(address)) {
        return state[address];
      }

      // Convert address to SS58 prefix 42 for Datapod
      final ss5842Address = d.Address.decode(address).encode(prefix: 42);

      // Get avatar from Datapod service
      final datapodService = ref.read(datapodServiceProvider);
      final avatarBytes = await datapodService.getAvatar(ss5842Address);

      // Cache the result (even if null)
      state = {...state, address: avatarBytes};

      return avatarBytes;
    } catch (e) {
      log.e('Error getting avatar for $address: $e');
      // Cache null result to avoid retrying immediately
      state = {...state, address: null};
      return null;
    }
  }

  /// Clear cache for a specific address
  void clearAvatar(String address) {
    state = Map.from(state)..remove(address);
  }

  /// Clear all cached avatars
  void clearAll() {
    state = {};
  }
}
