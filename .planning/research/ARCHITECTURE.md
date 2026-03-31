# Architecture Patterns

**Domain:** CesiumPlus wallet name integration & search for Duniter v2s wallet (Gecko)
**Researched:** 2026-03-31

## Current Architecture Analysis

### Existing Search Flow

The search system has TWO separate code paths that diverge based on input type:

```
User types in SearchScreen
  |
  v
searchTextProvider (raw text)
  |
  +--> searchResultsProvider (FutureProvider)
  |      Tries to convert input to SS58 address
  |      If valid address/pubkey: returns [G1WalletsList(address)]
  |      If not valid: returns []
  |
  +--> SearchResult widget checks results:
         |
         +--> If results non-empty: show address tile (balance + NameByAddress)
         +--> If results empty: delegate to SearchIdentityQuery widget
                |
                v
              searchIdentityProvider(name) (FutureProvider.family)
                Calls SquidService: searchAddressByName + searchByAddress
                Returns List<IdentitySuggestion> (on-chain identities only)
```

**Desktop (DesktopSearchSection)** runs BOTH paths in parallel: `searchResultsProvider` for address matches + `searchIdentityProvider` for identity name matches, then merges them into `DesktopSearchSuggestion` list.

### Existing CesiumPlus Integration

CesiumPlus is currently used for:
1. **Profiles** (description, city, socials, tags, avatar) - view & edit
2. **Certification queue** persistence
3. **Avatar display** via DatapodAvatar widget

CesiumPlus is NOT currently used for:
1. Name lookup by address
2. Name-based search
3. Name display alongside identity names

The `cesiumProfileProvider(address)` returns the full profile map. The `title` field in CesiumPlus profiles is the wallet name.

### Existing Name Resolution Chain

```
NameByAddress widget
  |
  v
hybridIdentityNameProvider(address) - AsyncNotifier
  |
  +--> SquidService.getIdentityName(address)  [on-chain identity name]
  |    Subscribed via SquidService.subscribeIdentityName(address)
  |
  +--> If null: falls through to WalletName widget
         |
         v
       WalletNameService.displayName(wallet.name)  [local wallet name]
         Only shows for user's OWN wallets (stored in ObjectBox)
```

**Gap:** For external wallets without an on-chain identity, nothing is shown. CesiumPlus names are never consulted.

### CesiumPlus REST API Patterns (from Ginkgo)

The CesiumPlus pod (Elasticsearch-backed) exposes:

| Operation | Endpoint | Notes |
|-----------|----------|-------|
| Get profile by pubkey | `GET /user/profile/{pubkey}` | Returns `_source` with `title`, `description`, etc. |
| Search by name | `GET /user/profile/_search?q=title:{term}` | Elasticsearch query syntax, searches `title` field |
| Create profile | `POST /user/profile` | Requires hash + signature |
| Update profile | `POST /user/profile/{pubkey}/_update` | Requires hash + signature |
| Delete profile | `POST /history/delete` | Requires hash + signature |

The `title` field is the CesiumPlus "name" (self-declared, no verification).

Ginkgo's search pattern (from `contact_search_page.dart`):
```
Future.wait([
  searchProfiles(term),     // CesiumPlus: /user/profile/_search?q=title:...
  searchWot(term),          // Squid indexer: identity names on-chain
])
-> deduplicate by address
-> merge results
```

## Recommended Architecture

### New Provider/Service Split

#### durt2 Layer (CesiumPlusService additions)

Add two methods to the existing `CesiumPlusService` in durt2:

```dart
/// Search profiles by name (title field) via Elasticsearch query
/// Returns list of (address, title) pairs
Future<List<({String address, String title})>> searchByName(String term) async {
  // GET /user/profile/_search?q=title:{term}
  // Parse Elasticsearch hits, convert pubkey->address for each result
}

/// Get just the title (name) from a profile, optimized for name-only lookups
/// Uses the same getProfileByAddress but extracts only the title
Future<String?> getNameByAddress(String address) async {
  final profile = await getProfileByAddress(address);
  return profile?['title'] as String?;
}
```

**Rationale:** Keep all CesiumPlus HTTP logic in durt2. Gecko should not make raw HTTP calls to CesiumPlus pods.

#### Gecko Provider Layer (new providers)

```
lib/providers/
  cesium_name_provider.dart       (NEW - name lookup + cache)
  hybrid_search_provider.dart     (NEW - merged search results)
```

#### Gecko Service Layer (modifications)

```
lib/services/
  wallet_name_service.dart        (MODIFY - add CesiumPlus registration hook)
  wallet_management_service.dart  (MODIFY - trigger CesiumPlus name upload on rename)
```

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| `CesiumPlusService.searchByName()` (durt2, NEW) | Elasticsearch name search via REST | CesiumPlus pod |
| `CesiumPlusService.getNameByAddress()` (durt2, NEW) | Single name lookup | CesiumPlus pod |
| `cesiumNameProvider(address)` (NEW) | Cached CesiumPlus name per address | `cesiumPlusServiceProvider` |
| `hybridSearchProvider(term)` (NEW) | Merged identity + CesiumPlus search with scoring | `searchIdentityProvider`, `cesiumPlusServiceProvider` |
| `NameByAddress` (MODIFY) | Add CesiumPlus name fallback after identity name | `hybridIdentityNameProvider`, `cesiumNameProvider` |
| `WalletManagementService.renameWallet()` (MODIFY) | Trigger CesiumPlus profile upload when name changes | `cesiumPlusServiceProvider`, `walletServiceProvider` |
| `SearchIdentityQuery` (MODIFY or REPLACE) | Show merged results with source badges | `hybridSearchProvider` |
| `DesktopSearchSection` (MODIFY) | Add CesiumPlus results to suggestions | `hybridSearchProvider` |

### Data Flow

#### Name Resolution (augmented)

```
NameByAddress widget
  |
  v
hybridIdentityNameProvider(address) [existing]
  |
  +--> SquidService.getIdentityName(address)  [on-chain, PRIORITY 1]
  |    Result: "Alice" with VERIFIED badge
  |
  +--> If null: check cesiumNameProvider(address)  [NEW STEP]
  |    CesiumPlusService.getNameByAddress(address)
  |    Result: "Bob's Shop" with SELF-DECLARED indicator
  |
  +--> If null: WalletName(wallet.name)  [local only, own wallets]
```

#### Search (merged, scored)

```
User types search term (>= 2 chars)
  |
  v
hybridSearchProvider(term) [NEW FutureProvider.family]
  |
  +--> Future.wait([
  |      searchIdentityProvider(term),           // Squid: on-chain identities
  |      cesiumPlusService.searchByName(term),   // CesiumPlus: self-declared names
  |    ])
  |
  v
Merge + Score + Deduplicate:
  1. On-chain identity matches (highest priority)
  2. CesiumPlus name matches (lower priority)
  3. Address/pubkey direct match (from searchResultsProvider)
Dedup by address (identity result wins over CesiumPlus result for same address)
  |
  v
List<HybridSearchResult> with source tag:
  - source: identity | cesiumPlus | address
  - name: String?
  - address: String
```

#### Name Registration (on wallet rename)

```
User renames wallet in WalletNameDialogService
  |
  v
WalletManagementService.renameWallet(wallet, newName)
  |
  +--> walletBox.put(wallet)  [local, immediate]
  |
  +--> IF newName is NOT default (#main, #2, etc.):
         Ask PIN -> cesiumPlusService.uploadProfile(
           address: wallet.address,
           signFunction: keyPair.sign,
           title: newName,
         )
         [async, fire-and-forget with error logging]
         Invalidate cesiumNameProvider(wallet.address) on success
```

## Patterns to Follow

### Pattern 1: FutureProvider.family for CesiumPlus Name Cache

```dart
/// CesiumPlus name provider: cached per-address, auto-disposed when unused.
/// Returns null if no CesiumPlus profile or no title set.
final cesiumNameProvider = FutureProvider.family<String?, String>((ref, address) async {
  try {
    final cesiumPlus = ref.read(cesiumPlusServiceProvider);
    final profile = await cesiumPlus.getProfileByAddress(address);
    final title = profile?['title'] as String?;
    // Filter out default/meaningless titles
    if (title == null || title.isEmpty || title == 'Duniter Wallet') return null;
    return title;
  } catch (_) {
    return null;
  }
});
```

**Why FutureProvider.family:** Same pattern as the existing `cesiumProfileProvider`. Riverpod auto-caches per address, auto-disposes when no widget watches it. No manual TTL needed because Riverpod's `keepAlive` mechanism handles lifecycle.

**Why NOT a separate persistent cache:** The CesiumPlus pod is the source of truth. Names change rarely. The Riverpod in-memory cache is sufficient. Adding ObjectBox persistence adds complexity for marginal benefit (names reload quickly on app restart when profiles are viewed).

### Pattern 2: Merged Search Result Model

```dart
enum SearchResultSource { identity, cesiumPlus, address }

class HybridSearchResult {
  final String address;
  final String? name;
  final SearchResultSource source;

  const HybridSearchResult({
    required this.address,
    this.name,
    required this.source,
  });
}
```

### Pattern 3: Anti-Usurpation Visual Distinction

```dart
// In search result tiles and NameByAddress widget:
if (source == SearchResultSource.identity) {
  // Show with a shield/checkmark icon, normal text style
  // This name is verified by the blockchain
} else if (source == SearchResultSource.cesiumPlus) {
  // Show with a lighter color, italic, and "self-declared" tooltip
  // This name is NOT verified, anyone can claim any name
}
```

### Pattern 4: Parallel Search with Short-Circuit

```dart
final hybridSearchProvider = FutureProvider.family<List<HybridSearchResult>, String>((ref, term) async {
  final squidStatus = ref.watch(squidConnectionStatusProvider);
  final isOnline = squidStatus == d.ConnectionStatus.connected;

  // Run all searches in parallel
  final results = await Future.wait([
    // Identity search (on-chain, requires Squid)
    if (isOnline)
      ref.watch(searchIdentityProvider(term).future)
    else
      Future.value(<d.IdentitySuggestion>[]),

    // CesiumPlus name search (separate service, may work when Squid is down)
    ref.read(cesiumPlusServiceProvider).searchByName(term)
        .catchError((_) => <({String address, String title})>[]),
  ]);

  // Merge with dedup (identity wins)
  final seen = <String>{};
  final merged = <HybridSearchResult>[];

  // Priority 1: on-chain identities
  for (final identity in results[0] as List<d.IdentitySuggestion>) {
    if (seen.add(identity.address)) {
      merged.add(HybridSearchResult(
        address: identity.address,
        name: identity.name,
        source: SearchResultSource.identity,
      ));
    }
  }

  // Priority 2: CesiumPlus names (skip if already in identity results)
  for (final cp in results[1] as List<({String address, String title})>) {
    if (seen.add(cp.address)) {
      merged.add(HybridSearchResult(
        address: cp.address,
        name: cp.title,
        source: SearchResultSource.cesiumPlus,
      ));
    }
  }

  return merged;
});
```

## Anti-Patterns to Avoid

### Anti-Pattern 1: Storing CesiumPlus Names in ObjectBox

**What:** Creating a persistent local cache of CesiumPlus names in ObjectBox.
**Why bad:** Stale data risk (names change on the pod, local cache diverges), extra entity/adapter complexity, migration burden. The CesiumPlus pod is already the cache.
**Instead:** Use Riverpod's `FutureProvider.family` with `ref.keepAlive()` for session-level caching. The pod lookup is fast (single HTTP GET).

### Anti-Pattern 2: Showing CesiumPlus Names Without Source Indicator

**What:** Displaying CesiumPlus self-declared names identically to on-chain identity names.
**Why bad:** Usurpation risk. A malicious user sets their CesiumPlus title to "Alice" to impersonate the real Alice (who has an on-chain identity).
**Instead:** Always visually distinguish the source. Identity names get a shield icon, CesiumPlus names get italic + "self-declared" marker.

### Anti-Pattern 3: Blocking Wallet Rename on CesiumPlus Upload Failure

**What:** Making the rename dialog wait for CesiumPlus upload before closing.
**Why bad:** CesiumPlus pod may be slow or down. User expects instant local rename.
**Instead:** Rename locally first (immediate), then fire-and-forget the CesiumPlus upload. Show a discrete error toast if upload fails, with a retry option.

### Anti-Pattern 4: Modifying hybridIdentityNameProvider

**What:** Adding CesiumPlus name lookup inside the existing `HybridIdentityNameNotifier`.
**Why bad:** It currently has a clean concern (on-chain identity name with Squid subscription). Mixing CesiumPlus logic would make it harder to reason about and test.
**Instead:** Create a separate `cesiumNameProvider` and compose at the widget level (in `NameByAddress`). The widget tries identity name first, then CesiumPlus name, then local wallet name.

## Recommended Architecture: Modified Files Summary

### durt2 (upstream library)

| File | Change | Description |
|------|--------|-------------|
| `cesium_plus_service.dart` | ADD methods | `searchByName(term)` and `getNameByAddress(address)` |

### Gecko (this app)

| File | Change | Description |
|------|--------|-------------|
| `lib/providers/cesium_name_provider.dart` | NEW | `cesiumNameProvider` FutureProvider.family |
| `lib/providers/hybrid_search_provider.dart` | NEW | `hybridSearchProvider`, `HybridSearchResult` model |
| `lib/widgets/name_by_address.dart` | MODIFY | Add CesiumPlus name fallback step |
| `lib/widgets/search_identity_query.dart` | MODIFY | Use `hybridSearchProvider` instead of `searchIdentityProvider` directly |
| `lib/widgets/search_result_list.dart` | MODIFY | Integrate merged results display |
| `lib/screens/search_result.dart` | MODIFY | Unified result display with source badges |
| `lib/screens/home/desktop/desktop_search_section.dart` | MODIFY | Use `hybridSearchProvider` |
| `lib/services/wallet_management_service.dart` | MODIFY | Add CesiumPlus name upload on rename |
| `lib/services/wallet_name_dialog_service.dart` | MODIFY | Support async CesiumPlus registration feedback |
| `lib/widgets/commons/name_source_badge.dart` | NEW | Reusable identity/cesiumPlus badge widget |

## Scalability Considerations

| Concern | Current (100s users) | At 10K users | At 100K users |
|---------|---------------------|--------------|---------------|
| CesiumPlus search latency | Elasticsearch fast (<100ms) | Still fast, indexed | May need pagination |
| Name cache memory | Negligible | ~10KB per 100 cached | Riverpod auto-disposes unused |
| CesiumPlus pod availability | Single pod (g1.data.e-is.pro) | May need failover | Need pod list rotation |
| Search result merging | Instant, <50 results | Still fast | May need server-side unified search |

## Sources

- Gecko codebase: `lib/providers/search_provider.dart`, `lib/widgets/search_identity_query.dart`, `lib/providers/cesium_profile_provider.dart`
- Ginkgo codebase: `lib/g1/api.dart` (searchProfilesV1, getProfileUserName), `lib/ui/widgets/first_screen/contact_search_page.dart`
- durt2: `lib/src/services/cesium_plus_service.dart`
- CesiumPlus REST API pattern: `/user/profile/_search?q=title:{term}` (Elasticsearch-backed)
- Datapod GraphQL queries: `SearchProfileByTerm`, `GetProfileByAddress` (for reference, datapods deprecated in favor of C+ REST)
