# Phase 4: Hybrid Search - Research

**Researched:** 2026-03-31
**Domain:** Federated search (Squid identity + CesiumPlus name) with trust-tier sectioned results
**Confidence:** HIGH

## Summary

Phase 4 adds CesiumPlus name search alongside existing on-chain identity search, with results displayed in labeled trust-tier sections. The existing search infrastructure is well-structured with clear separation points for extension. The `searchIdentityProvider` (Squid indexer), `searchResultsProvider` (local address matching), and four distinct UI entry points (mobile `SearchResultScreen`, desktop `GlobalSearchOverlay`, `GlobalSearchPaletteDialog`, and `DesktopSearchSection`) all follow the same pattern: watch both providers, merge results, display in sections.

Phase 3 has already delivered the foundational pieces: `cesiumNameProvider`, `cesiumNameConflictProvider`, `NameSourceBadge`, and `NameByAddress` with `showCesiumPlusName` opt-in. The remaining work is: (1) add a `searchByName(term)` method to `CesiumPlusService` in durt2, (2) create a `cesiumPlusSearchProvider` in Gecko that calls it, (3) modify the 4 UI entry points to add a third "CesiumPlus names" section below identity results, (4) verify that payment popup and related address fields do NOT use CesiumPlus names (TRUST-02), and (5) add translation keys for section headers.

The CesiumPlus pod's Elasticsearch `_search` endpoint is proven by Ginkgo's `searchProfilesV1()` at line 1560 of `api.dart`. The query format is `/user/profile/_search?q=title:<term>`. The response structure is `{hits: {hits: [{_source: {title, issuer, ...}}, ...]}}`. The `issuer` field is a base58 pubkey that must be converted to SS58 address using `Utils.pubkeyV1ToAddress()` which already exists in durt2. The critical Ginkgo pitfall to avoid: their search inserts the term directly into the query string without escaping Elasticsearch special characters.

**Primary recommendation:** Add `CesiumPlusService.searchByName()` in durt2 (with query sanitization), create a `cesiumPlusSearchProvider` in Gecko, then extend all 4 search UI widgets to show a third labeled section for CesiumPlus results below identity results, with graceful degradation on pod unavailability.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SRCH-01 | User can search wallets by CesiumPlus name in addition to on-chain identities | `CesiumPlusService.searchByName()` method + `cesiumPlusSearchProvider` in Gecko |
| SRCH-02 | Search results merge identities and CesiumPlus names with identities always above | All 4 UI entry points already use sectioned layout; add third section below existing "Identity" section |
| SRCH-03 | Results displayed in labeled sections ("Identites verifiees" / "Noms auto-declares") | `_ResultsSectionTitle` widget already exists in `GlobalSearchOverlay` and `GlobalSearchPaletteDialog`; add new translation keys |
| SRCH-04 | Identity search continues normally if CesiumPlus pod is unreachable | `cesiumPlusSearchProvider` uses `.catchError()` returning `[]` on failure; UI treats empty CesiumPlus results as no section |
| TRUST-02 | No CesiumPlus autocomplete in payment/transfer address fields | Payment popup already uses `NameByAddress` with `showCesiumPlusName: false` (default); search fields in payment context never call CesiumPlus search |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| durt2 | local (`../durt2`) | CesiumPlus REST API, SS58/base58 conversion | Already provides `getProfileByAddress`, `_addressToPubkeyBase58`, `Utils.pubkeyV1ToAddress` |
| flutter_riverpod | ^3.2.1 | Search providers, async state management | Already used for `searchIdentityProvider`, `cesiumNameProvider` |
| easy_localization | ^3.0.8 | Section header translations | Already used for `desktopIdentityShortLabel`, `desktopWalletShortLabel` |
| base_codecs | (transitive via durt2) | base58 encode/decode for pubkey<->address conversion | Already used in `CesiumPlusService._addressToPubkeyBase58` |

### Supporting
No new packages needed. All capabilities already present in the dependency tree.

## Architecture Patterns

### Current Search Data Flow
```
User types query
    |
    v
searchTextProvider (Notifier<String>)
    |
    +--> searchResultsProvider (local address match -> G1WalletsList)
    |
    +--> searchIdentityProvider (Squid GraphQL -> List<IdentitySuggestion>)
    |
    v
UI widgets merge both, display in sections ("Wallets" / "Identity")
```

### Target Search Data Flow (Phase 4)
```
User types query
    |
    v
searchTextProvider (Notifier<String>)
    |
    +--> searchResultsProvider (local address match -> G1WalletsList)
    |
    +--> searchIdentityProvider (Squid GraphQL -> List<IdentitySuggestion>)
    |
    +--> cesiumPlusSearchProvider (NEW: CesiumPlus REST -> List<CesiumPlusSearchResult>)
    |
    v
UI widgets merge all three, display in 3 sections:
  1. "Wallets" (local address matches, existing)
  2. "Verified identities" (Squid identity results)
  3. "Self-declared names" (CesiumPlus search results, deduped against identities)
```

### Search Entry Points to Modify (4 total)

1. **`lib/widgets/search_result_list.dart`** (`SearchResult`) - Mobile search results
   - Currently: shows `searchResultsProvider` results, falls back to `SearchIdentityQuery`
   - Change: also watch `cesiumPlusSearchProvider`, add CesiumPlus section below identity results

2. **`lib/widgets/search_identity_query.dart`** (`SearchIdentityQuery`) - Mobile identity search fallback
   - Currently: shows `searchIdentityProvider` results only
   - Change: also watch `cesiumPlusSearchProvider`, add CesiumPlus section below identity results

3. **`lib/widgets/global_search_overlay.dart`** (`_GlobalSearchResults`) - Desktop overlay
   - Currently: 2 sections (wallets + identities) using `_ResultsSectionTitle`
   - Change: add 3rd section for CesiumPlus results

4. **`lib/widgets/global_search_palette_dialog.dart`** (`_buildResultsPane`) - Desktop palette dialog
   - Currently: 2 sections (wallets + identities) using `_ResultsSectionTitle`
   - Change: add 3rd section for CesiumPlus results, update `_PaletteSearchEntryKind` enum

5. **`lib/screens/home/desktop/desktop_search_section.dart`** (`DesktopSearchSection`) - Desktop inline search bar
   - Currently: builds suggestions from addresses + identities
   - Change: add CesiumPlus results to suggestion list with type tag, update `DesktopSearchSuggestionType`

### Pattern: New durt2 Method (CesiumPlusService.searchByName)

```dart
// In durt2/lib/src/services/cesium_plus_service.dart

/// Search CesiumPlus profiles by name using Elasticsearch query API.
/// Returns list of (address, title) pairs.
/// On error, returns empty list (graceful degradation).
Future<List<({String address, String title})>> searchByName(String term) async {
  if (_baseEndpoint == null) return [];

  // Sanitize Elasticsearch special characters
  final sanitized = term.replaceAll(RegExp(r'[+\-=&|><!(){}\[\]^"~*?:\\/]'), '');
  if (sanitized.isEmpty) return [];

  final query = Uri.encodeFull(
    '/user/profile/_search?q=title:${sanitized.toLowerCase()}'
    ' OR title:${sanitized[0].toUpperCase()}${sanitized.substring(1).toLowerCase()}'
    ' OR title:$sanitized'
    '&_source=title,issuer'
    '&size=10'
  );

  try {
    final httpClient = HttpClientConfig.createHttpClient();
    final response = await httpClient
        .get(Uri.parse('$_baseEndpoint$query'))
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) return [];

    final data = json.decode(response.body) as Map<String, dynamic>;
    final hits = (data['hits'] as Map<String, dynamic>?)?['hits'] as List<dynamic>? ?? [];

    final results = <({String address, String title})>[];
    for (final hit in hits) {
      final source = (hit as Map<String, dynamic>)['_source'] as Map<String, dynamic>?;
      if (source == null) continue;
      final issuer = source['issuer'] as String?;
      final title = source['title'] as String?;
      if (issuer == null || title == null || title.isEmpty) continue;

      // Convert base58 pubkey to SS58 address
      try {
        final pubkeyBytes = base58BitcoinDecode(issuer);
        final address = Address(prefix: Durt.i.network.ss58, pubkey: pubkeyBytes).encode();
        results.add((address: address, title: title));
      } catch (_) {
        // Skip entries with invalid pubkeys
      }
    }
    return results;
  } catch (e) {
    log.w('CesiumPlus searchByName failed: $e');
    return [];
  }
}
```

**Source:** Ginkgo `api.dart` line 1560 (query format), durt2 `utils.dart` line 22-26 (base58->SS58 conversion).

### Pattern: New Gecko Provider (cesiumPlusSearchProvider)

```dart
// In lib/providers/cesium_plus_search_provider.dart

/// Search result from CesiumPlus profile search.
class CesiumPlusSearchResult {
  final String address;
  final String title;
  const CesiumPlusSearchResult({required this.address, required this.title});
}

/// Searches CesiumPlus profiles by name.
/// Returns empty list on error (graceful degradation per SRCH-04).
/// Deduplicates against identity results by address.
final cesiumPlusSearchProvider = FutureProvider.family<List<CesiumPlusSearchResult>, String>((ref, searchTerm) async {
  if (searchTerm.trim().length < 2) return [];

  try {
    final cesiumPlus = ref.read(cesiumPlusServiceProvider);
    final results = await cesiumPlus.searchByName(searchTerm);
    return results
        .map((r) => CesiumPlusSearchResult(address: r.address, title: r.title))
        .toList();
  } catch (_) {
    return []; // SRCH-04: silent degradation
  }
});
```

### Pattern: UI Section Addition (example for GlobalSearchOverlay)

```dart
// In _GlobalSearchResults.build():
final cesiumPlusResultsAsync = query.length >= 2
    ? ref.watch(cesiumPlusSearchProvider(query))
    : const AsyncValue<List<CesiumPlusSearchResult>>.data([]);

final cesiumPlusResults = cesiumPlusResultsAsync.asData?.value ?? const <CesiumPlusSearchResult>[];

// Deduplicate: remove CesiumPlus results that match an identity address
final identityAddresses = identityResults.map((i) => i.address).toSet();
final dedupedCesiumPlus = cesiumPlusResults
    .where((cs) => !identityAddresses.contains(cs.address))
    .toList();

// In ListView children:
if (dedupedCesiumPlus.isNotEmpty) ...[
  if (walletResults.isNotEmpty || identityResults.isNotEmpty) const SizedBox(height: 12),
  _ResultsSectionTitle(title: 'selfDeclaredNamesSection'.tr()),
  const SizedBox(height: 8),
  ...dedupedCesiumPlus.map((cs) => _CesiumPlusResultTile(result: cs)),
],
```

### Anti-Patterns to Avoid

- **Mixing CesiumPlus results into `searchIdentityProvider`:** This provider returns `IdentitySuggestion` which has implicit "verified" semantics. CesiumPlus results must use a separate type and provider.
- **Displaying CesiumPlus results without deduplication against identities:** A wallet with both an on-chain identity and a CesiumPlus profile would appear twice. Always deduplicate by address with identity-wins priority.
- **Ginkgo's trust order inversion:** Ginkgo adds CesiumPlus results BEFORE WoT results (line 165-170 in `contact_search_page.dart`). Gecko must strictly order: verified identities first, CesiumPlus second.
- **Injecting unsanitized search terms into Elasticsearch query:** Ginkgo's `api.dart` line 1560 directly interpolates the term. Sanitize all Elasticsearch special characters before query construction.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Base58 to SS58 address conversion | Custom byte conversion | `Utils.pubkeyV1ToAddress()` in durt2 | Already handles prefix, checksum, and network-specific encoding |
| Elasticsearch query escaping | Ad-hoc regex | Simple `replaceAll` for documented ES special chars | Well-defined character set: `+ - = & \| > < ! ( ) { } [ ] ^ " ~ * ? : \ /` |
| CesiumPlus HTTP client | Custom http setup | `HttpClientConfig.createHttpClient()` from durt2 | Handles SSL certificate configuration consistently |
| Search debouncing | Custom Timer | Existing pattern: Riverpod's `FutureProvider.family` auto-cancels when parameter changes | When `searchTextProvider` updates, old provider instances are automatically disposed |

## Common Pitfalls

### Pitfall 1: CesiumPlus Pod Unavailability Breaking Identity Search
**What goes wrong:** If the CesiumPlus HTTP call throws and the error propagates up, it could block the entire search result rendering.
**Why it happens:** `Future.wait()` with both Squid and CesiumPlus futures would reject if either fails.
**How to avoid:** Use separate providers (`searchIdentityProvider` and `cesiumPlusSearchProvider`), each with independent error handling returning `[]` on failure. The UI watches both independently and renders available results.
**Warning signs:** Search screen shows loading spinner when CesiumPlus pod is down despite Squid being up.

### Pitfall 2: Duplicate Results for Wallets with Both Identity and CesiumPlus Profile
**What goes wrong:** A wallet that has both an on-chain identity (e.g., "Alice") and a CesiumPlus profile (also named "Alice") appears in both sections.
**Why it happens:** The identity search and CesiumPlus search are independent queries that don't know about each other.
**How to avoid:** After fetching both result sets, build a `Set<String>` of addresses from identity results. Filter CesiumPlus results to exclude any address already present in identity results.
**Warning signs:** Same address appearing with the same name in two different sections.

### Pitfall 3: Elasticsearch Query Injection
**What goes wrong:** A search term like `"test AND _exists_:avatar"` could retrieve unintended results or cause query errors.
**Why it happens:** Elasticsearch's query string syntax treats certain characters as operators.
**How to avoid:** Strip all Elasticsearch special characters (`+ - = & | > < ! ( ) { } [ ] ^ " ~ * ? : \ /`) from the search term before constructing the query URL.
**Warning signs:** Search returns unexpected results for terms containing special characters, or returns 400 errors.

### Pitfall 4: CesiumPlus Results Section Appearing During Identity-Only Loading
**What goes wrong:** CesiumPlus results load faster than Squid identity results (simpler HTTP vs GraphQL). If rendered immediately, users see CesiumPlus names first in the UI, then identity names appear above them, causing visual reflow.
**Why it happens:** Independent async providers resolve at different times.
**How to avoid:** While identity results are still loading (`identityResultsAsync.isLoading`), show the main loading indicator. Only render CesiumPlus section after identity results have resolved (even if empty). This prevents the jarring reflow.
**Warning signs:** CesiumPlus names flash briefly at the top of results before being pushed down by identity results.

### Pitfall 5: Desktop Search Palette Keyboard Navigation Breaks with Third Section
**What goes wrong:** `GlobalSearchPaletteDialog` uses `_highlightedIndex` for arrow-key navigation, counting entries across sections. Adding a third section breaks the index math if not properly accounted for.
**Why it happens:** `_buildEntries()` currently only builds entries from wallets + identities. Must include CesiumPlus entries with their own `_PaletteSearchEntryKind`.
**How to avoid:** Add `cesiumPlus` to `_PaletteSearchEntryKind` enum. Update `_buildEntries()` to include CesiumPlus results. The `runningIndex` counting in `_buildResultsPane` will then work naturally.
**Warning signs:** Arrow keys skip CesiumPlus results, or pressing Enter on a CesiumPlus result opens the wrong profile.

### Pitfall 6: `_openFirstResult` in Desktop Widgets Ignores CesiumPlus Results
**What goes wrong:** When user presses Enter without arrow-key selection, `_openFirstResult()` in `GlobalSearchOverlay` and `GlobalSearchPaletteDialog` only checks wallet and identity results. If both are empty but CesiumPlus has results, nothing happens.
**Why it happens:** The Enter handler was written before CesiumPlus search existed.
**How to avoid:** Add CesiumPlus results as the third fallback in `_openFirstResult()` methods.
**Warning signs:** User types a CesiumPlus-only name, sees results, presses Enter, nothing happens.

## Code Examples

### Elasticsearch Response Structure (from CesiumPlus Pod)

```json
// GET /user/profile/_search?q=title:alice&_source=title,issuer&size=10
{
  "hits": {
    "total": 2,
    "hits": [
      {
        "_index": "user",
        "_type": "profile",
        "_id": "8hgzKKW9BjPK7Hbyy6L2fYfBGUWjLVm4PeZfVo3pCPfT",
        "_score": 4.5,
        "_source": {
          "title": "Alice",
          "issuer": "8hgzKKW9BjPK7Hbyy6L2fYfBGUWjLVm4PeZfVo3pCPfT"
        }
      }
    ]
  }
}
```

**Source:** Ginkgo `api.dart` lines 1559-1581, Cesium+ Pod REST API docs.

### Deduplication Pattern

```dart
/// Remove CesiumPlus results that duplicate identity results (by address).
/// Identity results always win.
List<CesiumPlusSearchResult> deduplicateCesiumPlusResults(
  List<CesiumPlusSearchResult> cesiumPlusResults,
  List<IdentitySuggestion> identityResults,
  List<G1WalletsList> walletResults,
) {
  final knownAddresses = <String>{
    ...identityResults.map((i) => i.address),
    ...walletResults.map((w) => w.address),
  };
  return cesiumPlusResults
      .where((cs) => !knownAddresses.contains(cs.address))
      .toList();
}
```

### TRUST-02 Verification Points

The following call sites use `NameByAddress` without `showCesiumPlusName` (defaults to `false`), which is correct:
- `lib/widgets/payment_popup.dart` lines 577, 612 -- payment amount entry form
- All `NameByAddress` calls that don't explicitly pass `showCesiumPlusName: true`

Call sites that correctly use `showCesiumPlusName: true` (search/display contexts, not payment):
- `lib/widgets/search_result_list.dart` line 92
- `lib/widgets/global_search_overlay.dart` line 403
- `lib/widgets/global_search_palette_dialog.dart` line 494
- `lib/widgets/contacts_list.dart` line 188
- `lib/widgets/wallet_tile.dart` line 129
- `lib/widgets/wallet_tile_membre.dart` line 131
- `lib/screens/home/desktop/desktop_wallet_overview.dart` line 534
- `lib/widgets/desktop/panels/contacts_panel.dart` line 279

**TRUST-02 is already enforced by design:** the `showCesiumPlusName` parameter defaults to `false`. Payment popup and all transaction-related screens never pass `true`. No CesiumPlus autocomplete suggestions exist in any address input field. The search providers (`searchIdentityProvider`, `searchResultsProvider`) are never connected to the payment popup. This requirement is already satisfied and just needs verification, not new code.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single-source identity search (Squid only) | Federated search (Squid + CesiumPlus) | Phase 4 (this phase) | Users can find non-member wallets by name |
| Flat mixed search results (Ginkgo) | Trust-tier sectioned results | Phase 4 | Verified identities visually separated from self-declared names |
| Unsafe direct query interpolation (Ginkgo) | Sanitized Elasticsearch query | Phase 4 | Prevents query injection |

## Open Questions

1. **Elasticsearch result count cap**
   - What we know: Elasticsearch defaults to 10 results. Ginkgo uses the default. Adding `&size=10` makes this explicit.
   - What's unclear: Whether the live CesiumPlus pod has a different configured maximum.
   - Recommendation: Use `&size=10` explicitly. 10 CesiumPlus results per query is sufficient; users can refine their search for more precision. This matches the existing Squid identity search which also returns a limited set.

2. **CesiumPlus search response time**
   - What we know: The pod uses Elasticsearch which is typically fast. Ginkgo uses 500ms debounce.
   - What's unclear: Actual latency of the live pod for search queries.
   - Recommendation: Use independent providers. If CesiumPlus is slow, identity results appear immediately and CesiumPlus results appear when ready. No need for artificial debounce beyond Riverpod's natural parameter-change cancellation.

## Project Constraints (from CLAUDE.md)

### Critical Rules
- **Never run `flutter build`/`flutter run`** -- only `flutter pub get`, `flutter analyze`, `dart format .`
- **Never use destructive git commands** -- no `git stash`, `git checkout .`, `git restore .`, etc.
- **Git commit:** subject line only, no body, no `Co-Authored-By` signature
- **Riverpod conventions:** never use codegen (`@riverpod`), write providers manually, prefer `AsyncNotifier` for async state, `FutureProvider` for cached async data, document providers in English with `///`
- **UTF-8 accents in ALL translation strings** -- French, Spanish, Italian, Esperanto, German
- **Desktop/Mobile dual layout** -- every new screen must support both (not applicable here: we modify existing search widgets, not add new screens)
- **Never use plain `Text` for markdown translation strings** -- use `TextMarkDown` when markdown is involved
- **durt2 is at `../durt2`** via `dependency_overrides` in `pubspec.yaml`

### Search-Specific Constraints (from STATE.md decisions)
- CesiumPlus names use italic + alpha 0.8 for visual distinction from identity names
- Payment popup and `idty_status` excluded from CesiumPlus display for anti-usurpation
- `cesiumNameProvider` watches `cesiumProfileProvider` to reuse cached fetch, no extra HTTP call
- Used `asData?.value` for `AsyncValue` extraction (consistent with codebase pattern)

## Sources

### Primary (HIGH confidence)
- Gecko codebase: `lib/providers/identity_providers.dart` (searchIdentityProvider), `lib/providers/search_provider.dart` (searchResultsProvider, searchTextProvider), `lib/widgets/search_identity_query.dart`, `lib/widgets/search_result_list.dart`, `lib/widgets/global_search_overlay.dart`, `lib/widgets/global_search_palette_dialog.dart`, `lib/screens/home/desktop/desktop_search_section.dart`, `lib/widgets/payment_popup.dart`, `lib/widgets/name_by_address.dart`, `lib/providers/cesium_name_provider.dart`, `lib/widgets/name_source_badge.dart`, `lib/models/g1_wallets_list.dart`
- durt2 codebase: `lib/src/services/cesium_plus_service.dart` (CesiumPlusService, _addressToPubkeyBase58), `lib/src/services/squid/squid_account_queries.dart` (searchAddressByName, searchByAddress, IdentitySuggestion), `lib/src/services/utils.dart` (pubkeyV1ToAddress, base58Bitcoin.decode), `lib/src/models/identity_suggestion.dart`
- Ginkgo reference: `lib/ui/widgets/first_screen/contact_search_page.dart` (parallel searchProfiles+searchWot, CesiumPlus-first ordering to avoid), `lib/g1/api.dart` lines 1554-1581 (searchProfilesV1, Elasticsearch query format, response parsing), `lib/g1/service_manager.dart` (V2ServiceManager.searchProfiles delegates to searchProfilesV1)

### Secondary (MEDIUM confidence)
- Cesium+ Pod REST API docs (http://doc.e-is.pro/cesium-plus-pod/REST_API.html) -- search endpoint format
- Project-level SUMMARY.md research (2026-03-31) -- trust model, anti-usurpation patterns, ENS/Twitter/Bluesky precedents

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all required capabilities verified in existing codebase, no new packages needed
- Architecture: HIGH -- all 5 search entry points read and analyzed, data flow mapped, modification points identified
- Pitfalls: HIGH -- Ginkgo reference code analyzed for antipatterns (trust order, query injection), desktop keyboard navigation edge cases identified from reading palette dialog source
- TRUST-02: HIGH -- all `NameByAddress` call sites enumerated, payment popup verified to use default `showCesiumPlusName: false`

**Research date:** 2026-03-31
**Valid until:** 2026-04-30 (stable: no new packages, all patterns from existing codebase)
