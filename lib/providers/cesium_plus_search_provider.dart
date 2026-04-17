import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/stream_providers.dart';

/// A CesiumPlus search result with the wallet's SS58 address and self-declared name.
class CesiumPlusSearchResult {
  final String address;
  final String title;

  const CesiumPlusSearchResult({required this.address, required this.title});
}

/// Searches CesiumPlus profiles by name. Returns empty list on error (graceful degradation per SRCH-04).
final cesiumPlusSearchProvider = FutureProvider.family<List<CesiumPlusSearchResult>, String>((ref, searchTerm) async {
  if (searchTerm.trim().length < 2) return [];

  try {
    final results = await ref.read(cesiumPlusServiceProvider).searchByName(searchTerm);
    return results.map((r) => CesiumPlusSearchResult(address: r.address, title: r.title)).toList();
  } catch (_) {
    return [];
  }
});

/// Remove CesiumPlus results whose address already appears in identity or wallet results.
/// Identity/wallet results always take priority.
List<CesiumPlusSearchResult> deduplicateCesiumPlusResults(
  List<CesiumPlusSearchResult> cesiumPlusResults,
  Set<String> knownAddresses,
) {
  return cesiumPlusResults.where((cs) => !knownAddresses.contains(cs.address)).toList();
}

/// Hides self-declared CesiumPlus results whose on-chain balance is zero or
/// not yet resolved. Empty self-declared wallets are noise in search results:
/// anyone can publish a CesiumPlus profile against an unfunded address, so the
/// presence of balance is the cheapest signal that a match is worth showing.
///
/// Watches [smartBalanceStreamProvider] for each address; the caller's widget
/// rebuilds as balances stream in, populating the filtered list progressively.
List<CesiumPlusSearchResult> filterOutEmptyCesiumPlusResults(WidgetRef ref, List<CesiumPlusSearchResult> results) {
  return results.where((cs) {
    final balanceAsync = ref.watch(smartBalanceStreamProvider(cs.address));
    final balance = balanceAsync.asData?.value.total;
    final keep = balance != null && balance > BigInt.zero;
    log.d('🔎 CS filter ${cs.address.substring(0, 8)}… total=$balance keep=$keep');
    return keep;
  }).toList();
}
