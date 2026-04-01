import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/providers.dart';

/// Fetches CesiumPlus profile data for a given address.
/// Returns null if no profile exists or on error (silent degradation).
final cesiumProfileProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, address) async {
  try {
    final cesiumPlus = ref.read(cesiumPlusServiceProvider);
    return await cesiumPlus.getProfileByAddress(address);
  } catch (_) {
    return null;
  }
});

/// Derives profile existence from [cesiumProfileProvider].
/// Non-blocking: returns false while loading, true when data confirms a profile exists.
/// Reuses the same cached fetch - no extra network call.
final cesiumProfileExistsProvider = Provider.family<bool, String>((ref, address) {
  final profileAsync = ref.watch(cesiumProfileProvider(address));
  if (!profileAsync.hasValue) return false;
  final profile = profileAsync.value;
  if (profile == null) return false;
  // Check that there's actual content, not just an empty shell
  final description = profile['description']?.toString();
  final city = profile['city']?.toString();
  final socials = profile['socials'];
  final tags = profile['tags'];
  return (description != null && description.isNotEmpty) ||
      (city != null && city.isNotEmpty) ||
      (socials is List && socials.isNotEmpty) ||
      (tags is List && tags.isNotEmpty);
});
