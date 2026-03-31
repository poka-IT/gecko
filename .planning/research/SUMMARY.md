# Project Research Summary

**Project:** Gecko v0.3 — CesiumPlus Names & Federated Search
**Domain:** Decentralized wallet name integration & hybrid identity search (Duniter v2s / Ḡ1v2)
**Researched:** 2026-03-31
**Confidence:** HIGH

## Executive Summary

Gecko v0.3 adds CesiumPlus name integration and federated search to the existing Duniter v2s wallet. This is a name-resolution and search-federation feature, not a new blockchain integration. All required infrastructure already exists: the `durt2` package already speaks the CesiumPlus REST API (read, write, profile management), the Squid indexer already provides ranked on-chain identity search, and no new Flutter packages are needed. The only upstream addition required is a `searchByName()` method in `durt2/CesiumPlusService` (~50 lines) to hit the existing Elasticsearch `_search` endpoint. Everything else is composition inside Gecko.

The recommended approach is a strict two-tier trust model: on-chain identity names (verified by the web-of-trust) are always shown first with a positive verification badge; CesiumPlus self-declared names are shown as a fallback with a clearly subordinate visual treatment. Research from Bluesky's dual-badge system, ENS impersonation losses ($600K/month), and Twitter's blue-check degradation all converge on the same principle: never conflate self-declared names with cryptographically-verified ones. The visual system must be designed and implemented before any CesiumPlus name appears anywhere in the app.

The key risks center on the existing codebase's assumption that names come only from on-chain identities. The `walletNameIndexer` (20+ read sites), `NameByAddress` widget (6+ call sites), and `G1WalletsList.username` Hive field all carry implicit "verified" semantics. Injecting CesiumPlus names into any of these without an explicit trust annotation would create a silent impersonation vector across the entire app. The correct mitigation is a separate `cesiumNameProvider` composed at widget level, not mixed into the existing identity name infrastructure.

## Key Findings

### Recommended Stack

No new packages are needed. The full capability set required for v0.3 is already in the project: `durt2` for CesiumPlus REST API (profile CRUD, signing, SS58/base58 conversion), `flutter_riverpod` for federated search providers and name caching, `easy_localization` for anti-usurpation tooltip strings, and standard Flutter Material widgets (`Icon`, `Chip`, `Tooltip`) for trust badges. The Ginkgo reference app uses `easy_debounce` for search input debouncing, but Gecko's existing search already uses a standard `Timer` — consistent with existing patterns.

**Core technologies:**
- `durt2` (local `../durt2` override): CesiumPlus REST API, profile signing, address conversion — already installed, needs one search method added (~50 lines)
- `flutter_riverpod` ^3.2.1: federated search providers, per-address name cache via `FutureProvider.family` with `autoDispose` — already installed
- `easy_localization` ^3.0.8: trust badge labels, anti-usurpation UI strings — already installed
- Flutter Material widgets (`Icon`, `Chip`, `Tooltip`): visual trust differentiation — no new package needed
- `crypto` ^3.0.7: SHA256 hashing for CesiumPlus profile signing — already installed

### Expected Features

**Must have (table stakes):**
- Search wallets by CesiumPlus name — Ginkgo and Cesium already support this; blocking dependency for everything else in v0.3
- Display CesiumPlus name for non-member wallets — addresses without on-chain identity currently show only a truncated address
- Visual distinction between on-chain identity names and CesiumPlus self-declared names — non-negotiable per ENS/Twitter/Bluesky research; shipping name search without trust indicators is irresponsible
- Hybrid search results merging on-chain identities and CesiumPlus names — users expect all matches regardless of source
- On-chain results ranked above CesiumPlus results — verified names must never be pushed below the fold by self-declared ones
- Graceful degradation when CesiumPlus pod is unavailable — pod downtime must not block the core identity search experience

**Should have (differentiators):**
- CesiumPlus name publish on wallet rename (opt-in, non-default names only) — lets users be discoverable by their custom wallet name
- Sectioned search results with labeled headers ("Identités vérifiées" / "Noms auto-déclarés") — better trust communication than Ginkgo's flat mixed list
- "Self-declared name" label on profile view for CesiumPlus-only profiles — explicit anti-usurpation callout without using a warning banner
- Offline CesiumPlus name display via `g1WalletsBox.csName` Hive field — field already exists in the model, currently unused

**Defer (v2+):**
- Persistent ObjectBox/Hive name cache with TTL — in-memory Riverpod `autoDispose` cache is sufficient for v0.3
- Batch name lookup optimization for contacts list — worth revisiting if CesiumPlus names become widespread
- Search score transparency labels per result — sectioned display already communicates trust tiers sufficiently

**Anti-features (explicitly do not build):**
- Autocomplete names while typing in the payment address field — ENS impersonation attacks prove this is dangerous ($600K/month losses documented)
- CesiumPlus name as primary identifier anywhere — erodes trust signal (Twitter Blue Check precedent)
- CesiumPlus name in transaction confirmation screen — attacker could register "Alice" to intercept payments meant for real Alice
- Complex PageRank-style scoring — overkill for a community of thousands; simple two-tier section separation is correct and transparent

### Architecture Approach

The architecture strictly separates CesiumPlus names from on-chain identity names at every layer. `durt2` provides the raw HTTP search method. Gecko adds a `cesiumNameProvider` (`FutureProvider.family` with `autoDispose`) and `hybridSearchProvider` (`FutureProvider.family`) as distinct providers — fully separate from the existing `hybridIdentityNameProvider`. Composition happens at the widget level: `NameByAddress` tries identity name first, then `cesiumNameProvider`, then local wallet name. The existing `walletNameIndexer` and `G1WalletsList.username` remain identity-only; CesiumPlus names go into `G1WalletsList.csName` (the field already exists in the Hive model but is currently unused everywhere).

**Major components:**
1. `CesiumPlusService.searchByName()` (durt2, NEW) — Elasticsearch title search, returns `(address, title)` pairs with base58→SS58 conversion
2. `CesiumPlusService.getNameByAddress()` (durt2, NEW) — single-address name lookup, extracts `title` from existing `getProfileByAddress()`
3. `cesiumNameProvider(address)` (Gecko, NEW) — per-address CesiumPlus name, `FutureProvider.family` with `autoDispose`; returns `null` on error or empty title
4. `hybridSearchProvider(term)` (Gecko, NEW) — parallel `Future.wait` over Squid + CesiumPlus; deduplicates with identity-wins priority; returns `List<HybridSearchResult>` with source tag
5. `NameSourceBadge` widget (Gecko, NEW) — reusable widget showing shield/checkmark for verified identity or muted "self-declared" indicator for CesiumPlus
6. `NameByAddress` widget (MODIFY) — add opt-in `showCesiumPlusName` parameter (defaults `false`); CesiumPlus fallback step between identity name and local wallet name
7. `WalletManagementService.renameWallet()` (MODIFY) — fire-and-forget CesiumPlus upload for non-default names after local save succeeds

### Critical Pitfalls

1. **Identity impersonation via visually indistinguishable CesiumPlus names** — design the trust visual system (shield badge for identity, italic+muted for self-declared) before writing any name display code; implement conflict detection for CesiumPlus names that exactly match existing on-chain identity names

2. **Injecting CesiumPlus names into `walletNameIndexer` or `NameByAddress` without trust annotation** — `walletNameIndexer` has 20+ read sites and `NameByAddress` has 6+ call sites that all assume verified names; keep a separate `cesiumNameProvider` and compose at widget level via an opt-in parameter; never mix trust levels in the same cache

3. **Ginkgo's backwards search order (CesiumPlus first, WoT second)** — Ginkgo's `contact_search_page.dart` adds CesiumPlus results before identity results, which is the wrong trust order; Gecko must strictly section identity results first, CesiumPlus second, never interleaved regardless of which API responds faster

4. **Race condition on wallet rename: local rename succeeds, CesiumPlus upload fails silently** — always save locally first (immediate), then fire-and-forget CesiumPlus upload with a persistent retry indicator on failure; never gate local rename on network success

5. **Unescaped Elasticsearch query injection** — Ginkgo's `api.dart` line 1560 injects the search term directly into the query string without escaping; sanitize `+ - = && || > < ! ( ) { } [ ] ^ " ~ * ? : \ /` before any CesiumPlus search query; this is a documented Ginkgo bug to not replicate

## Implications for Roadmap

Based on the dependency graph in FEATURES.md and the phase warnings in PITFALLS.md, the natural phase structure is four phases ordered by dependency and risk:

### Phase 1: Trust Visual System & Name Display Foundation

**Rationale:** Every subsequent feature depends on a correct trust visual system. Building search, name display, or name registration before it exists risks shipping impersonation vulnerabilities that require full rewrites to fix. This phase resolves the most critical architectural decisions (data model, cache separation, widget opt-in strategy) before any user-visible feature lands.

**Delivers:** The durt2 `searchByName()` and `getNameByAddress()` methods (unblocks Phase 2). New `cesiumNameProvider` and `NameSourceBadge` widget. Updated `NameByAddress` with `showCesiumPlusName` opt-in parameter. `G1WalletsList.csName` wired for offline fallback. Helper `displayInfo` on `G1WalletsList` carrying trust metadata.

**Addresses:** Table-stakes "display CesiumPlus name for non-member wallets"; anti-usurpation visual distinction requirement.

**Avoids:** Pitfall 1 (impersonation), Pitfall 2 (NameByAddress assumptions), Pitfall 3 (walletNameIndexer mixing), Pitfall 7 (stale name after identity change), Pitfall 8 (G1WalletsList field confusion), Pitfall 13 (visual fatigue from too many indicators), Pitfall 15 (offline shows nothing).

### Phase 2: Hybrid Search Integration

**Rationale:** Once the trust visual system and name providers exist from Phase 1, search can be built on them. This phase wires `hybridSearchProvider` into all existing search entry points (mobile search screen, desktop `GlobalSearchOverlay`, `DesktopSearchSection`). It is the core user-facing feature of v0.3.

**Delivers:** Full federated search with parallel Squid + CesiumPlus queries, strict section separation ("Identités vérifiées" above "Noms auto-déclarés"), CesiumPlus results capped at 5-10 per query. Updates to `SearchIdentityQuery`, `SearchResultList`, `GlobalSearchOverlay` (third section), and `DesktopSearchSection`. Sanitized Elasticsearch query input.

**Uses:** `hybridSearchProvider`, `NameSourceBadge`, `CesiumPlusService.searchByName()` from Phase 1.

**Avoids:** Pitfall 5 (API unavailability blocking identity results), Pitfall 9 (unverified results drowning verified), Pitfall 11 (query escaping), Pitfall 14 (desktop overlay overflow from third section).

### Phase 3: CesiumPlus Name Registration on Wallet Rename

**Rationale:** Name publishing is a write operation with its own failure modes (PIN requirement, network dependency, default-name guard). It depends on Phase 1 (name display, csName Hive field) but is independent of Phase 2 (search). Deferring keeps Phase 2 scoped to read-only operations, reducing integration risk.

**Delivers:** Opt-in CesiumPlus name publish when user sets a custom (non-default) wallet name. Local rename always succeeds immediately. CesiumPlus upload is fire-and-forget with a persistent retry indicator on failure. Includes read-then-merge on profile saves (preserves description/city when only updating title).

**Avoids:** Pitfall 4 (race condition), Pitfall 10 (default name publishing), Pitfall 12 (title field overwrite on profile save).

### Phase 4: Cache Polish & Offline Refinement

**Rationale:** In-memory Riverpod `autoDispose` cache is sufficient for the v0.3 MVP. This phase adds `g1WalletsBox.csName` population on first fetch for true offline fallback, TTL-aware cache invalidation triggered by identity subscription events, and LRU eviction if memory growth is observed during QA.

**Delivers:** Populated `g1WalletsBox.csName` on fetch for offline display, TTL-aware invalidation (hook into `HybridIdentityNameNotifier._startNameSubscription()` to clear CesiumPlus cache when identity name arrives), LRU eviction strategy if needed.

**Avoids:** Pitfall 6 (unbounded cache growth on long-session low-RAM devices), strengthens Pitfall 15 mitigation.

### Phase Ordering Rationale

- Phase 1 is strictly first: the visual trust system must be an invariant that all subsequent phases rely on; retrofitting trust indicators after search is built is error-prone and dangerous.
- Phase 2 before Phase 3: search is read-only and lower risk; name registration introduces write operations with PIN flow and failure modes that require Phase 1 to be proven stable.
- Phase 4 last: the MVP can ship without persistence; it is a polish pass on caching architecture that can be sequenced after user-visible features are working.
- durt2 changes (`searchByName`, `getNameByAddress`) land in Phase 1 because they are a hard dependency for Phase 2 and benefit from early empirical validation against the live pod.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3 (Name Registration):** The opt-in consent UX and exact integration point with the PIN unlock flow have not been prototyped. The "retry indicator for failed CesiumPlus uploads" is Gecko-original with no reference implementation in Ginkgo. Consider a brief `/gsd:research-phase` pass on the wallet rename flow and PIN unlock integration.

Phases with standard patterns (skip research-phase):
- **Phase 1 (Foundation):** All code patterns are directly readable in existing Gecko/durt2 source. `FutureProvider.family`, `autoDispose`, and Hive field usage are well-documented in the codebase.
- **Phase 2 (Hybrid Search):** Ginkgo `contact_search_page.dart` is a complete working reference. The delta (sectioned display, correct trust order, desktop overlay) is mechanical.
- **Phase 4 (Cache Polish):** Standard LRU + TTL patterns with no niche domain knowledge required.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Verified by reading durt2, Gecko, and Ginkgo source directly; all required capabilities confirmed present; no speculative package recommendations |
| Features | HIGH | Anti-usurpation research backed by multiple primary sources (Bluesky official blog, Nature peer-reviewed 2024 study, ENS developer statements, Baymard Institute data); Ginkgo reference implementation verified for feature parity gaps |
| Architecture | HIGH | Data flow verified against actual Gecko source (identity_providers.dart, cesium_plus_service.dart, name_by_address.dart); component boundaries grounded in existing patterns; anti-patterns identified from concrete code analysis (walletNameIndexer grep confirmed 20+ sites, NameByAddress call sites enumerated) |
| Pitfalls | HIGH | All 15 pitfalls identified from codebase analysis with specific file/line references; not theoretical — each has a concrete existing code path that could trigger it |

**Overall confidence:** HIGH

### Gaps to Address

- **base58-to-SS58 reverse conversion in durt2:** The `searchByName` method will receive base58 pubkeys from CesiumPlus (`issuer` field) and must convert them to SS58 addresses. Need to verify that the reverse of `_addressToPubkeyBase58()` exists or can be derived; if not, it must be added in Phase 1 alongside `searchByName`.
- **Elasticsearch result count cap:** The `_search` endpoint may return a capped number of hits (Elasticsearch default: 10). For Phase 2, empirically test whether the live pod is configured with a lower cap and whether a `?size=N` parameter is supported to request more results.
- **CesiumPlus pod failover:** The app currently targets a single hardcoded pod. A pod rotation list is out of scope for v0.3 but should be noted as a v1 scalability gap.
- **`_source=title` optimization for `getNameByAddress`:** Using `getProfileByAddress` to extract only `title` fetches the full profile unnecessarily. The Elasticsearch endpoint supports `?_source=title` to return only the title field. Whether this optimization is worth the added complexity is a Phase 1 implementation decision.

## Sources

### Primary (HIGH confidence)
- Gecko codebase: `lib/providers/identity_providers.dart`, `lib/providers/cesium_profile_provider.dart`, `lib/widgets/name_by_address.dart`, `lib/widgets/search_identity_query.dart`, `lib/services/wallet_name_service.dart`, `lib/services/wallet_management_service.dart`, `lib/models/g1_wallets_list.dart`, `lib/widgets/global_search_overlay.dart`
- durt2 codebase: `lib/src/services/cesium_plus_service.dart`, `lib/src/services/squid/squid_account_queries.dart`
- Ginkgo reference: `lib/ui/widgets/first_screen/contact_search_page.dart`, `lib/g1/api.dart` (lines 1554-1581)
- [Bluesky Verification Blog Post (April 2025)](https://bsky.social/about/blog/04-21-2025-verification) — dual-badge design, verification source transparency
- [Misinformation in Search Results — Nature Scientific Reports 2024](https://www.nature.com/articles/s41598-024-61645-8) — warning banners backfire; peer-reviewed
- [ENS Impersonation — Cointelegraph](https://cointelegraph.com/news/wallet-impersonation-scam-ens-uniswap) — autocomplete dangers, Nick Johnson's official guidance
- [Cesium+ Pod REST API docs](http://doc.e-is.pro/cesium-plus-pod/REST_API.html) — profile search/create/update endpoints and rate limits

### Secondary (MEDIUM confidence)
- [Federated Search Scoring — Searchcraft](https://www.searchcraft.io/academy/federated-search) — weight multipliers per index, score normalization patterns
- [Federated Search Guide — Algolia](https://www.algolia.com/blog/ux/what-is-federated-search) — multi-source result merging patterns
- [Trust UX Badges Research — UserIntuition.ai / Baymard Institute](https://www.userintuition.ai/reference-guides/trust-ux-badges-proof-and-the-research-behind-them) — 1-3 trust signal types optimal; 7+ decreases conversion

### Tertiary (LOW confidence / background)
- [Twitter Verification — Wikipedia](https://en.wikipedia.org/wiki/Twitter_verification) — gold/gray checkmark multi-tier evolution (illustrative precedent)
- [ENS Impersonation Details — DailyCoin](https://dailycoin.com/uniswaps-hayden-adams-exposes-ens-wallet-impersonation-scam/) — $600K losses figure (corroborating source)

---
*Research completed: 2026-03-31*
*Ready for roadmap: yes*
