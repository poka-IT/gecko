import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/cesium_profile_provider.dart';

/// CesiumPlus name provider: returns the self-declared name for [address], or null.
///
/// Watches [cesiumProfileProvider] to reuse the existing cached profile fetch,
/// extracts the 'title' field, and filters out meaningless defaults
/// (null, empty, or the literal 'Duniter Wallet').
final cesiumNameProvider = FutureProvider.family<String?, String>((ref, address) async {
  try {
    final profile = await ref.watch(cesiumProfileProvider(address).future);
    if (profile == null) return null;

    final title = profile['title'] as String?;
    if (title == null || title.isEmpty || title == 'Duniter Wallet') {
      return null;
    }

    return title;
  } catch (_) {
    return null;
  }
});

/// Detects if a CesiumPlus name conflicts with an existing on-chain identity on a different address.
///
/// Watches [cesiumNameProvider] to get the self-declared name, then queries the
/// Squid indexer for on-chain identities with the same name (case-insensitive).
/// Returns the conflicting address if found, or null if no conflict.
final cesiumNameConflictProvider = FutureProvider.family<String?, String>((ref, address) async {
  try {
    final csName = await ref.watch(cesiumNameProvider(address).future);
    if (csName == null) return null;

    final results = await d.SquidService.client.searchAddressByName(csName);

    for (final result in results) {
      if (result.name.toLowerCase() == csName.toLowerCase() && result.address != address) {
        return result.address;
      }
    }

    return null;
  } catch (_) {
    return null;
  }
});
