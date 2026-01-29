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
