# Technology Stack

**Project:** Gecko v0.3 -- CesiumPlus Names & Federated Search
**Researched:** 2026-03-31

## Executive Summary

No new Flutter packages are needed. The existing durt2 `CesiumPlusService` already has profile read/write/search capabilities via REST API, and the Squid indexer already provides ranked identity search. The work is composing these two existing data sources into a federated search provider with scoring, adding a search method to `CesiumPlusService` in durt2, and building anti-usurpation UX using standard Flutter widgets.

## Recommended Stack

### No New Packages Required

After analyzing both Gecko's codebase and Ginkgo's reference implementation, all building blocks already exist:

| Technology | Version | Purpose | Status |
|------------|---------|---------|--------|
| `durt2` | local override (`../durt2`) | CesiumPlus REST API (read, write, **search to add**), Squid identity search | Already installed |
| `flutter_riverpod` | ^3.2.1 | Federated search providers, name cache providers | Already installed |
| `easy_localization` | ^3.0.8 | Anti-usurpation tooltip strings, search UI labels | Already installed |
| `http` | ^1.6.0 | HTTP client for CesiumPlus REST calls (used inside durt2) | Already installed |
| `crypto` | ^3.0.7 | SHA256 hashing for CesiumPlus profile signing | Already installed |
| `truncate` | ^3.0.1 | Display truncation for search results | Already installed |

## CesiumPlus API Endpoints (from Ginkgo Reference)

### REST API Structure (Elasticsearch-based)

The Cesium+ pods run an Elasticsearch-backed REST API. The durt2 `CesiumPlusService` already uses this for profile CRUD. From Ginkgo's `searchProfilesV1()`:

| Endpoint | Method | Purpose | Currently in durt2? |
|----------|--------|---------|---------------------|
| `GET /user/profile/{pubkey}` | GET | Fetch single profile | YES -- `getProfileByAddress()` |
| `POST /user/profile` | POST | Create new profile | YES -- `uploadProfile()` |
| `POST /user/profile/{pubkey}/_update` | POST | Update existing profile | YES -- `uploadProfile()` |
| `POST /history/delete` | POST | Delete profile | YES -- `deleteProfile()` |
| `GET /user/profile/_search?q=...` | GET | **Search profiles by title/issuer** | **NO -- needs to be added** |
| `GET /node/summary` | GET | Test endpoint connectivity | YES -- `testEndpoint()` |

### Search Endpoint Details

From Ginkgo `lib/g1/api.dart` line 1559-1560:

```
GET /user/profile/_search?q=title:{term_lower} OR issuer:{term} OR title:{term_capitalized} OR title:{term}
```

**Response format** (Elasticsearch hits):
```json
{
  "hits": {
    "hits": [
      {
        "_id": "BASE58_PUBKEY",
        "_source": {
          "title": "User Name",
          "description": "...",
          "city": "...",
          "avatar": { "_content_type": "image/png", "_content": "base64..." },
          "issuer": "BASE58_PUBKEY",
          "time": 1698012284,
          "version": 2,
          "socials": [{"type": "twitter", "url": "..."}],
          "geoPoint": {"lat": "48.8566", "lon": "2.3522"},
          "tags": ["tag1"]
        }
      }
    ]
  }
}
```

**Key observation:** The `_id` field is the **base58 pubkey** (Cesium v1 format), NOT the SS58 address. The durt2 service already handles SS58-to-base58 conversion via `_addressToPubkeyBase58()`.

### Authentication for Profile Writes

From durt2 `CesiumPlusService.uploadProfile()` (verified in source):

1. Build JSON document with `version: 2`, `issuer: base58_pubkey`, `title`, optional fields
2. Calculate SHA256 hash of the JSON string
3. Sign the hash with the wallet's Ed25519 keypair (via `signFunction`)
4. Prepend `hash` and `signature` as first JSON fields
5. POST to `/user/profile` (create) or `/user/profile/{pubkey}/_update` (update)

This mechanism is already fully implemented. For name registration when renaming a wallet, the same `uploadProfile()` method is used -- the `title` field IS the CesiumPlus name.

**Confidence:** HIGH -- verified by reading durt2 source code at `lib/src/services/cesium_plus_service.dart`.

## What Needs to Be Added to durt2

### 1. Search Method on CesiumPlusService

**Location:** `durt2/lib/src/services/cesium_plus_service.dart`

The service currently lacks a search method. Add:

```dart
/// Search CesiumPlus profiles by name (title field)
/// Returns a list of search results with pubkey, title, and metadata
/// Uses the Elasticsearch _search endpoint
Future<List<CesiumPlusSearchResult>> searchByName(String searchTerm) async {
  // Build query: /user/profile/_search?q=title:{lower} OR title:{capitalized} OR title:{term}
  // Parse Elasticsearch hits response
  // Convert base58 pubkeys to SS58 addresses for caller
}
```

**Data model needed:**

```dart
class CesiumPlusSearchResult {
  final String address;      // SS58 address (converted from base58)
  final String title;        // The CesiumPlus name
  final String? description;
  final String? city;
  final int? time;           // Unix timestamp of last profile update
}
```

**Confidence:** HIGH -- the REST endpoint is confirmed working in Ginkgo's production code.

### 2. No Changes to Squid Identity Search

The existing `SquidService.client.searchAddressByName()` already implements a three-tier ranked search (exact > startsWith > contains) for on-chain identity names. This is already used by `searchIdentityProvider` in Gecko. No changes needed.

## Federated Search Scoring Algorithm

### Architecture: No External Package Needed

The search scoring is a simple weighted merge of two result sets, not a graph-based PageRank. Pure Dart computation in a Riverpod provider.

### Proposed Scoring Model

```dart
enum SearchResultSource {
  identity,     // On-chain identity (Squid indexer)
  cesiumPlus,   // Self-declared CesiumPlus name
  local,        // Local contacts/wallet names
}

class ScoredSearchResult {
  final String address;
  final String displayName;
  final SearchResultSource source;
  final double score;         // 0.0 to 1.0
  final bool isVerified;      // true for on-chain identities
}
```

### Scoring Rules (from PROJECT.md: "identities priorisees, CesiumPlus differencies")

| Source | Base Score | Match Type Bonus | Rationale |
|--------|-----------|------------------|-----------|
| On-chain identity | 0.8 | +0.2 exact, +0.1 startsWith, +0.0 contains | Verified on blockchain, highest trust |
| CesiumPlus name | 0.3 | +0.2 exact, +0.1 startsWith, +0.0 contains | Self-declared, lower trust |
| Local contact | 0.6 | +0.2 exact, +0.1 startsWith, +0.0 contains | User's own data, medium trust |

**Merge logic:**
1. Run identity search (Squid) and CesiumPlus search in parallel
2. Score each result
3. Deduplicate by address (keep highest-scoring source)
4. Sort descending by score
5. Tag each result with its source for UI differentiation

**Why not a real PageRank/graph algorithm:** The search space is two flat lists (identities + CesiumPlus profiles), not a graph. A weighted scoring merge is the correct tool. PageRank would be appropriate if we were scoring based on certification graph connectivity, which is not the current requirement.

**Confidence:** HIGH -- this is a straightforward weighted merge pattern.

## Anti-Usurpation UX: No New Packages

### Visual Differentiation Strategy

Standard Flutter widgets are sufficient for the anti-usurpation UX:

| UI Element | Flutter Widget | Purpose |
|------------|---------------|---------|
| Verified badge (checkmark) | `Icon(Icons.verified, color: Colors.blue)` | Next to on-chain identity names |
| Self-declared indicator | `Icon(Icons.person_outline, color: Colors.grey)` | Next to CesiumPlus-only names |
| Tooltip explanation | `Tooltip` + translation string | Explains what "verified" vs "self-declared" means |
| Color coding | `Theme.of(context).colorScheme` variants | Different text colors for identity vs CesiumPlus names |
| Chip/Badge | `Chip` or `Container` with label | "Identity" vs "CesiumPlus" label in search results |

**Ginkgo reference:** Ginkgo does NOT currently implement anti-usurpation UX. This is a Gecko-original feature. The visual language should be:
- **Green checkmark + bold name** for on-chain identities (verified by blockchain consensus)
- **Grey person icon + regular weight name** for CesiumPlus names (self-declared, anyone can claim any name)
- **Warning icon** if a CesiumPlus name matches an existing on-chain identity name (potential usurpation)

**Confidence:** HIGH -- standard Flutter Material widgets, no packages needed.

## Integration Points with Existing Gecko Code

### Existing Providers to Modify

| Provider | File | Change Needed |
|----------|------|--------------|
| `searchIdentityProvider` | `identity_providers.dart` | Expand to federated search: run Squid + CesiumPlus in parallel |
| `hybridIdentityNameProvider` | `identity_providers.dart` | Fallback to CesiumPlus name when no on-chain identity found |
| `NameByAddress` widget | `name_by_address.dart` | Show CesiumPlus name as fallback with visual differentiation |

### Existing Providers Used As-Is

| Provider | File | Role |
|----------|------|------|
| `cesiumPlusServiceProvider` | `providers.dart` | Access to CesiumPlusService for search + name write |
| `cesiumProfileProvider` | `cesium_profile_provider.dart` | Fetch full profile (already cached by Riverpod) |
| `avatarProvider` | `avatar_providers.dart` | Avatar fetching from CesiumPlus (already works) |
| `walletServiceProvider` | `providers.dart` | Key pair access for signing profile updates |

### New Providers Needed

```dart
// 1. CesiumPlus name search provider
final cesiumPlusSearchProvider = FutureProvider.family<List<CesiumPlusSearchResult>, String>(
  (ref, searchTerm) async {
    final cesiumPlus = ref.read(cesiumPlusServiceProvider);
    return await cesiumPlus.searchByName(searchTerm);
  },
);

// 2. Federated search provider (merges Squid + CesiumPlus + local)
final federatedSearchProvider = FutureProvider.family<List<ScoredSearchResult>, String>(
  (ref, searchTerm) async {
    // Run all three searches in parallel
    // Score, deduplicate, sort
  },
);

// 3. CesiumPlus name cache (persisted)
// Uses existing cesiumProfileProvider but adds name-only caching
final cesiumPlusNameProvider = FutureProvider.family<String?, String>(
  (ref, address) async {
    final profile = await ref.watch(cesiumProfileProvider(address).future);
    return profile?['title'] as String?;
  },
);

// 4. Name registration provider (upload name to CesiumPlus on wallet rename)
final registerCesiumPlusNameProvider = FutureProvider.family<bool, ({String address, String name})>(
  (ref, params) async {
    // Use cesiumPlusService.uploadProfile() with title = name
    // Requires PIN for key pair access
  },
);
```

### Wallet Rename Integration

Current flow in `WalletManagementService.renameWallet()`:
1. User renames wallet
2. Name saved to local ObjectBox only

New flow:
1. User renames wallet
2. Name saved to local ObjectBox
3. **If name is NOT a default name (no `#` prefix)**: upload to CesiumPlus as profile title
4. **If name IS a default name**: do NOT upload (don't pollute CesiumPlus with "Portefeuille principal")

This matches the PROJECT.md requirement: "Enregistrement CesiumPlus quand l'utilisateur renomme un portefeuille (pas le nom par defaut)".

The `WalletNameService.isDefault(name)` method already distinguishes default from custom names.

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Search scoring | Weighted merge (pure Dart) | `graphs` package PageRank | Not a graph problem; two flat lists need weighted merge, not graph traversal |
| CesiumPlus search | Add method to durt2 `CesiumPlusService` | Direct HTTP calls from Gecko | Keep all CesiumPlus API calls centralized in durt2 for consistency |
| Anti-usurpation badges | Flutter `Icon` + `Chip` widgets | `badges` package | Overkill; standard Material icons (verified, person_outline) are sufficient |
| Profile name cache | `FutureProvider.family` with Riverpod auto-cache | `riverpod_sqflite` persisted provider | CesiumPlus name can change; Riverpod's built-in cache with TTL is enough; persistent cache adds stale data risk |
| Search debouncing | `Timer` in provider (already used in search) | `easy_debounce` package | Already in Flutter SDK; Ginkgo uses `easy_debounce` but Gecko's existing search uses standard Timer |
| CesiumPlus datapod (GraphQL) | **NOT recommended** -- use REST API | Ginkgo's `duniter_datapod` package (Ferry GraphQL) | Datapod endpoints are deprecated in Ginkgo (marked `@Deprecated`); REST API is the current standard for CesiumPlus |

## Installation

```bash
# No new packages required.
# All dependencies are already in pubspec.yaml.
# durt2 needs a minor addition (searchByName method) but no version bump.
```

## durt2 Changes Summary

| Change | File | Scope |
|--------|------|-------|
| Add `searchByName(String)` method | `cesium_plus_service.dart` | ~50 lines: HTTP GET + response parsing |
| Add `CesiumPlusSearchResult` model | `cesium_plus_service.dart` or new file | ~20 lines: simple data class |
| No changes to Squid queries | -- | Identity search already works |
| No changes to profile write methods | -- | `uploadProfile()` already handles name via `title` field |

## Confidence Assessment

| Decision | Confidence | Rationale |
|----------|------------|-----------|
| No new Flutter packages needed | HIGH | Verified: all capabilities exist in durt2 + Flutter SDK |
| CesiumPlus REST search endpoint works | HIGH | Verified in Ginkgo production code (searchProfilesV1) |
| durt2 needs search method addition | HIGH | Verified: `cesium_plus_service.dart` has no search, endpoint confirmed working |
| Weighted merge for scoring | HIGH | Two flat result sets, not a graph; weighted merge is the correct pattern |
| Material icons for anti-usurpation | HIGH | Standard Flutter widgets; Ginkgo has no reference for this (Gecko-original feature) |
| Upload on rename (not on default names) | HIGH | `WalletNameService.isDefault()` already exists; `uploadProfile()` already works |
| Datapod GraphQL NOT recommended | HIGH | Ginkgo marks datapod methods as `@Deprecated`; REST API is current |

## Sources

- **Gecko codebase:** `lib/providers/identity_providers.dart` (searchIdentityProvider, hybridIdentityNameProvider), `lib/providers/cesium_profile_provider.dart`, `lib/providers/providers.dart` (cesiumPlusServiceProvider), `lib/services/wallet_name_service.dart`, `lib/services/wallet_management_service.dart`, `lib/widgets/name_by_address.dart`, `lib/widgets/search_identity_query.dart`, `lib/widgets/search_result_list.dart`
- **durt2 codebase:** `lib/src/services/cesium_plus_service.dart` (full REST API implementation), `lib/src/services/squid/squid_account_queries.dart` (searchAddressByName with ranked results)
- **Ginkgo codebase:** `lib/g1/api.dart` lines 1554-1581 (searchProfilesV1 with Elasticsearch query), `lib/g1/duniter_datapod_helper.dart` (datapod marked @Deprecated), `lib/ui/ui_helpers.dart` lines 150-173 (contactFromResultSearch response parsing), `lib/ui/widgets/first_screen/contact_search_page.dart` (parallel search with WoT + CesiumPlus)
- **Ginkgo datapod package:** `packages/duniter_datapod/lib/graphql/schema/duniter-datapod-queries.graphql` (GraphQL schema for reference, but deprecated)
