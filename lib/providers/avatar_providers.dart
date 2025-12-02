import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/providers.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

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

  /// Get cache file for an address
  File _getCacheFile(String address) {
    // Use SHA256 hash of address as filename to avoid special characters
    final hash = sha256.convert(utf8.encode(address)).toString();
    return File('${avatarsCacheDirectory.path}/$hash.png');
  }

  /// Get avatar for an address, with persistent caching
  Future<Uint8List?> getAvatar(String address) async {
    try {
      // 1. Check if already in memory cache
      if (state.containsKey(address)) {
        log.d('Avatar for $address loaded from memory cache');
        return state[address];
      }

      // 2. Check if cached on disk
      final cacheFile = _getCacheFile(address);
      if (await cacheFile.exists()) {
        log.d('Avatar for $address loaded from disk cache');
        final cachedBytes = await cacheFile.readAsBytes();
        // Store in memory cache for faster access
        state = {...state, address: cachedBytes};

        // Refresh avatar in background (non-blocking)
        _refreshAvatarInBackground(address);

        return cachedBytes;
      }

      // 3. Download from Cesium+ (blocking)
      log.d('Downloading avatar for $address from Cesium+');
      final avatarBytes = await _downloadAndCacheAvatar(address);

      return avatarBytes;
    } catch (e) {
      log.e('Error getting avatar for $address: $e');
      // Cache null result to avoid retrying immediately
      state = {...state, address: null};
      return null;
    }
  }

  /// Download avatar from Cesium+ and cache it
  Future<Uint8List?> _downloadAndCacheAvatar(String address) async {
    try {
      final cesiumPlusService = ref.read(cesiumPlusServiceProvider);
      final avatarBytes = await cesiumPlusService.getAvatar(address);

      if (avatarBytes != null) {
        // Save to disk cache
        final cacheFile = _getCacheFile(address);
        await cacheFile.writeAsBytes(avatarBytes);
        log.d('Avatar for $address cached to disk');
      }

      // Cache the result in memory (even if null)
      state = {...state, address: avatarBytes};

      return avatarBytes;
    } catch (e) {
      log.e('Error downloading avatar for $address: $e');
      return null;
    }
  }

  /// Refresh avatar in background (non-blocking)
  Future<void> _refreshAvatarInBackground(String address) async {
    try {
      final cesiumPlusService = ref.read(cesiumPlusServiceProvider);
      final newAvatarBytes = await cesiumPlusService.getAvatar(address);

      // Compare with cached version
      final cacheFile = _getCacheFile(address);
      final cachedBytes = await cacheFile.readAsBytes();

      // If different, update cache
      if (newAvatarBytes != null && !_bytesEqual(cachedBytes, newAvatarBytes)) {
        log.i('🔄 Avatar updated for $address from Cesium+');
        await cacheFile.writeAsBytes(newAvatarBytes);

        // Update memory cache and notify listeners
        state = {...state, address: newAvatarBytes};
      }
    } catch (e) {
      log.d('Background avatar refresh failed for $address: $e');
      // Non-blocking, so we don't propagate the error
    }
  }

  /// Compare two byte arrays
  bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Clear cache for a specific address (both memory and disk)
  /// If forceReload is true, will immediately trigger a re-download
  Future<void> clearAvatar(String address, {bool forceReload = false}) async {
    try {
      // Clear from memory
      state = Map.from(state)..remove(address);

      // Clear from disk
      final cacheFile = _getCacheFile(address);
      if (await cacheFile.exists()) {
        await cacheFile.delete();
        log.d('Disk cache cleared for $address');
      }

      // If forceReload, immediately download new avatar without invalidating provider
      if (forceReload) {
        log.d('Force reloading avatar for $address');
        await _downloadAndCacheAvatar(address);
      }
    } catch (e) {
      log.e('Error clearing avatar cache for $address: $e');
    }
  }

  /// Clear all cached avatars (both memory and disk)
  Future<void> clearAll() async {
    try {
      // Clear memory cache
      state = {};

      // Clear disk cache
      if (await avatarsCacheDirectory.exists()) {
        final files = avatarsCacheDirectory.listSync();
        for (final file in files) {
          if (file is File) {
            await file.delete();
          }
        }
        log.i('All avatar disk cache cleared');
      }
    } catch (e) {
      log.e('Error clearing all avatar cache: $e');
    }
  }
}
