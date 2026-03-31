# Feature Landscape

**Domain:** CesiumPlus wallet name integration & hybrid search for Duniter v2s wallet
**Researched:** 2026-03-31

## Table Stakes

Features users expect for a name-aware wallet search. Missing = product feels incomplete compared to Ginkgo and Cesium.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Search wallets by CesiumPlus name | Ginkgo and Cesium already support this; users like Ma.aude managing multiple accounts expect it | Medium | Requires new `searchByName` method in durt2 CesiumPlusService using `/user/profile/_search?q=title:TERM` Elasticsearch endpoint |
| Display CesiumPlus name for non-member wallets | Wallets without on-chain identity currently show only truncated address; users need human-readable names | Low | Existing `cesiumProfileProvider` already fetches profiles; need to extract `title` field and display it |
| Visual distinction between on-chain identity names and CesiumPlus self-declared names | Without distinction, users cannot assess trust level of a displayed name | Medium | Core anti-usurpation requirement; see detailed analysis below |
| Hybrid search results: on-chain identities + CesiumPlus names | Users search by name and expect all matches regardless of source | Medium | Parallel queries to Squid (on-chain) + CesiumPlus pod, merge with dedup |
| On-chain results ranked above CesiumPlus results | On-chain names are verified by the web-of-trust; self-declared names are not | Low | Simple ordering: verified section first, then self-declared section |
| Debounced search input | Cesium+ pod has rate limits (5 queries/min for updates); avoid hammering server | Low | Ginkgo uses 500ms debounce via `EasyDebounce`; Gecko should do the same |
| Graceful degradation when CesiumPlus pod is unavailable | Pod downtime should not break search; on-chain search should still work | Low | Already natural with parallel queries + `catchError` pattern |

## Differentiators

Features that set Gecko apart from Ginkgo and Cesium. Not expected, but valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Persistent Riverpod cache for CesiumPlus names | Offline name display and faster repeat lookups; Ginkgo uses in-memory `ContactsCache` only | Medium | Requires ObjectBox or shared_preferences persistence layer, keyed by address, with TTL-based invalidation |
| CesiumPlus name publish on wallet rename | When user customizes a wallet name (not default `#main`/`#2`), automatically publish to CesiumPlus pod | Medium | Requires PIN for signing; should be opt-in with clear explanation of what "publishing" means |
| Sectioned search results with visual headers | Ginkgo shows "Network results" header; Gecko can improve with "Verified identities" vs "Self-declared names" sections | Low | Better trust communication than a flat list |
| Search score transparency | Show why a result ranked where it did (e.g., "on-chain member" badge, "self-declared name" label) | Low | Small UI addition per result tile, high trust-building value |
| "This name is not verified" warning on CesiumPlus-only profiles | Explicit anti-usurpation callout when viewing a profile with CesiumPlus name but no on-chain identity | Low | Single line of text + icon on profile view screen |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Autocomplete names while typing in payment address field | ENS impersonation attacks proved this is dangerous; ENS lead developer Nick Johnson: "interfaces shouldn't autocomplete names at all; it's far too dangerous." Uniswap founder Hayden Adams exposed $600K in losses from ENS autocomplete scams in January 2024 alone. | Show search results only AFTER explicit submit; never suggest names inline while typing an address |
| CesiumPlus name as primary identifier anywhere | Self-declared names create false trust; Twitter Blue Check degradation showed that paid/self-declared verification erodes trust in the entire system | Always show address as primary identifier; CesiumPlus name is supplementary info only |
| Name uniqueness enforcement in CesiumPlus | CesiumPlus pods are federated Elasticsearch nodes with no global uniqueness constraint; trying to enforce uniqueness would be fragile and misleading | Accept name collisions; differentiate by address + verification badge instead |
| Automatic CesiumPlus name publish for default wallet names | Publishing `#main` or `Portefeuille principal` clutters the pod with non-meaningful names | Only publish when user explicitly sets a custom name (detected via `WalletNameService.isDefault()` returning false) |
| CesiumPlus name in transaction confirmation screen | Attacker could register name "Alice" on their wallet to intercept payments meant for Alice's on-chain identity | Transaction confirmation must show full address + on-chain identity name ONLY; never CesiumPlus name |
| Complex relevance scoring algorithm (PageRank-style) | Overkill for a small community (Duniter has thousands, not millions, of users); TrustRank/Dirichlet PageRank algorithms solve problems at Google scale, not here | Simple two-tier ranking: on-chain identity results first (already trust-verified via WoT), CesiumPlus results second |
| CesiumPlus name editing directly in search results | Confusing UX, name editing belongs in wallet settings | Keep rename in WalletOptions / CesiumProfileScreen |
| Full-text search across CesiumPlus descriptions/city | Scope creep; name search is sufficient for v0.3 | Search only the `title` field, not description/city/socials |

## Anti-Usurpation Patterns: Detailed Analysis

### The Problem

CesiumPlus names are self-declared. Anyone can register the name "Alice" on any wallet. Without visual distinction, a user searching for "Alice" might send money to a scammer's wallet instead of the real Alice (who has an on-chain identity verified by the web-of-trust).

### Real-World Precedents

**Twitter/X Blue Check Degradation (2022-present)**
- Before: Blue check = platform-verified notable person. Users trusted it implicitly.
- After: Blue check = $8/month subscription. Impersonators got blue checks as easily as real accounts. A bug in Twitter's iOS app made the checkmarks for a senator's official account and an impersonation account virtually indistinguishable.
- Twitter introduced gold and gray checkmarks to compensate -- gold for Verified Organizations ($1000+/month), gray for government accounts -- showing that multi-tier badge systems emerge naturally when single-tier trust breaks.
- Lesson: When a trust signal becomes purchasable/self-declared, it loses all value. **Never equate CesiumPlus names with on-chain identities.**
- Source confidence: HIGH (widely documented, Wikipedia "Twitter verification" article)

**Bluesky Dual Badge System (April 2025)**
- Blue check in scalloped circle = Trusted Verifier (platform-verified, e.g., Bluesky itself, The New York Times).
- Blue check in standard rounded circle = normal verified user.
- Tapping the badge shows WHO verified the account ("Verified by The New York Times").
- Users can hide their badge while remaining verified behind the scenes.
- Lesson: **Two visually distinct badges** for two trust levels works well. Users can audit the verification source. The system balances platform approval with community-driven trust.
- Source confidence: HIGH (official Bluesky blog post April 21, 2025)

**ENS Wallet Impersonation (January-February 2024)**
- Scammers registered Ethereum wallet addresses as `.eth` ENS domains.
- Wallet UIs autocompleted these fake ENS names when users pasted real addresses, showing the fake ENS as the top suggestion.
- Nearly $600K stolen in January 2024 alone.
- ENS lead developer Nick Johnson's official guidance: "interfaces shouldn't autocomplete names at all; it's far too dangerous."
- MyCrypto broke all `0x...` ENS name registrations entirely as a preventive measure.
- Lesson: **Never autocomplete unverified names in payment flows.** Search is acceptable; payment address input fields are not. The attack vector is the inline suggestion, not the search itself.
- Source confidence: HIGH (Cointelegraph, DailyCoin, ENS developer statements)

**Federated Search Scoring Best Practices**
- Searchcraft's federated search engine normalizes scoring across sources and allows weight multipliers per index to fine-tune how much each source contributes to final ranking.
- Example pattern: official FAQ entries (precise, authoritative) weighted 3x over community forum threads (variable quality).
- Different systems have different scoring methods, so federated search must harmonize scores.
- Lesson: **Weight multipliers per source** are the standard approach for mixing results with different trust levels. Simple and effective.
- Source confidence: MEDIUM (Searchcraft documentation, Algolia federated search guide)

**Trust UX Badge Research (Baymard Institute)**
- Trust signals increased conversion rates by 15-30% on average, but ranged from -5% to +75% depending on implementation.
- Pages with 1-3 trust signal types converted 23% better than no signals. Pages with 7+ signals converted 8% WORSE than 1-3 signals.
- Unfamiliar badges actually decreased trust by 12% compared to no badge.
- Placement matters: security indicators near sensitive form fields outperformed headers/footers by 2-3x.
- Lesson: **Keep it simple.** One clear badge for verified, one clear label for unverified. Do not overload with multiple signal types.
- Source confidence: MEDIUM (Baymard Institute research cited in UserIntuition.ai reference guide)

**Scientific Research on Misinformation in Search Results (Nature, 2024)**
- Misinformation does not damage trust in accurate results displayed alongside it.
- However, warning banners on misinformation can BACKFIRE, reducing trust in accurate content that follows.
- Lesson: **Do not use warning banners** that say "this result may be fake." Instead, use positive trust indicators on verified results and neutral presentation on unverified results.
- Source confidence: HIGH (Nature Scientific Reports, peer-reviewed)

### Recommended Visual Design

Based on research, the anti-usurpation UX should follow Bluesky's dual-badge model with Gecko-specific adaptations:

**On-chain identity (verified by WoT):**
- Shield icon or filled checkmark in a distinct color (e.g., primary/green)
- Label: "Membre" / "Member" -- displayed alongside the name
- Name displayed in normal weight, primary color
- No additional warning text needed -- positive trust signal only

**CesiumPlus self-declared name:**
- No badge, or a subtle "person" icon (explicitly NO checkmark)
- Label: "Nom auto-declare" / "Self-declared name" in subdued text
- Name displayed in lighter weight or italic, secondary color
- First time a user encounters CesiumPlus results: brief one-time tooltip explaining the difference
- Do NOT use a warning banner (research shows this backfires)

**No name at all:**
- Address only, no name displayed
- Standard wallet icon

### Recommended Scoring Model

Simple two-tier model, not PageRank:

```
Score = baseRelevance * sourceTrustMultiplier

sourceTrustMultiplier:
  - On-chain identity (Squid): 3.0
  - CesiumPlus name: 1.0

baseRelevance:
  - Exact match: 10
  - Starts-with match: 7
  - Contains match: 4

Final sort: score DESC, then alphabetical within same score
```

Within each trust tier, results are ordered by text relevance. Between tiers, on-chain results always appear first due to the 3x multiplier. This is simple, transparent, and matches user expectations from apps like Bluesky and Google (which visually section organic vs paid results).

In practice, since the two sources return separate lists, the simplest implementation is to display them in two sections rather than interleaving: "Identites verifiees" section first, then "Noms auto-declares" section. This avoids the score normalization problem entirely while providing clear trust communication.

## Feature Dependencies

```
Search by CesiumPlus name (new durt2 method)
  -> Hybrid search provider (merges Squid + CesiumPlus results)
    -> Search result UI with sectioned display
      -> Anti-usurpation visual badges

CesiumPlus profile fetch (existing cesiumProfileProvider)
  -> CesiumPlus name display in profile view
    -> "Self-declared name" label

Wallet rename (existing WalletNameDialogService)
  -> CesiumPlus name publish decision (isDefault check)
    -> CesiumPlus uploadProfile call with sign function
      -> PIN unlock flow (existing)

Persistent name cache (differentiator)
  -> CesiumPlus name display (offline support)
  -> Hybrid search results (faster repeat queries)
```

## MVP Recommendation

Prioritize for first deliverable:

1. **Search by CesiumPlus name** -- new `searchByName` method in durt2 CesiumPlusService using `/user/profile/_search?q=title:TERM` endpoint. This is the blocking dependency for everything else. The method must convert returned base58 pubkeys back to SS58 addresses.
2. **Hybrid search provider** -- merge Squid on-chain results + CesiumPlus results with dedup by address, on-chain results first. Follow Ginkgo's parallel `Future.wait` pattern from `contact_search_page.dart`.
3. **Anti-usurpation visual badges** -- shield/checkmark for on-chain identities, subtle "self-declared" label for CesiumPlus names. This is non-negotiable per ENS/Twitter research; shipping name search without trust indicators would be irresponsible.
4. **CesiumPlus name display** -- show CesiumPlus `title` on profile view and in contact lists for wallets without on-chain identity, using the existing `cesiumProfileProvider`.

Defer to follow-up phase:

- **Persistent Riverpod cache**: Can ship with in-memory caching first (existing `cesiumProfileProvider` already caches per session via Riverpod). Persistence is a polish feature for offline mode.
- **CesiumPlus name publish on rename**: Requires careful UX design for opt-in consent and PIN flow. Can ship in a second phase after core search works.
- **Search score transparency**: Nice-to-have; the sectioned display already communicates trust tiers visually.
- **Batch name lookup for contacts list**: Could be a v0.4 optimization if contacts with CesiumPlus names are common.

## Technical Notes

### CesiumPlus Search API (from Ginkgo reference + official docs)

The search endpoint is Elasticsearch-based:
```
GET /user/profile/_search?q=title:alice OR title:Alice OR issuer:alice
```

Response format:
```json
{
  "hits": {
    "hits": [
      {
        "_source": {
          "title": "Alice",
          "issuer": "<base58-pubkey>",
          "city": "Paris",
          "description": "...",
          "avatar": { "_content": "<base64>", "_content_type": "image/png" }
        }
      }
    ]
  }
}
```

Key implementation detail: The CesiumPlus API uses **base58 pubkeys**, not SS58 addresses. The existing `CesiumPlusService._addressToPubkeyBase58()` handles SS58-to-base58 conversion. The new `searchByName` method will return base58 pubkeys from the `issuer` field that must be converted back to SS58 addresses for Gecko's internal use.

### Rate Limits (from official Cesium+ pod docs)

- Profile creation: 5 per hour per IP
- Profile update: 5 per minute per IP
- Search queries: No documented rate limit, but debounce is still good practice (500ms, matching Ginkgo)

### Current Search Architecture Gap

Gecko's current search has two separate, disconnected paths:
1. **Address/pubkey search** (`searchResultsProvider` in `search_provider.dart`): validates input as SS58 address or v1 pubkey, returns single-result direct match
2. **Identity name search** (`searchIdentityProvider` in `identity_providers.dart`): queries Squid GraphQL `searchAddressByName` + `searchByAddress` for on-chain identity names

These two paths are not unified. The `SearchResult` widget (`search_result_list.dart`) tries address search first, falls back to `SearchIdentityQuery` if no address match. CesiumPlus results are not included at all.

The hybrid search needs to create a **unified provider** that runs both existing searches + a new CesiumPlus name search in parallel, merges with dedup by address, assigns trust tiers, and produces a sectioned result list.

### Ginkgo Reference Implementation Pattern

Ginkgo's `ContactSearchPage._search()` (line 69-256) demonstrates the target pattern:
1. Show local contacts immediately (no network wait)
2. Kick off `searchProfiles` (CesiumPlus) and `searchWot` (on-chain) in parallel via `Future.wait`
3. Deduplicate network results against each other and against local results
4. Display with section headers: local contacts first, then "Network results"
5. Cache network results in `ContactsCache`

Gecko's implementation should follow this but with Riverpod reactive patterns instead of `setState`.

## Sources

- [Bluesky Verification Blog Post (April 2025)](https://bsky.social/about/blog/04-21-2025-verification) -- Dual badge design, verification source transparency
- [Bluesky Verification UX Analysis](https://blog.adrianalacyconsulting.com/bluesky-verification-badge-apply/) -- Scalloped vs standard circle distinction
- [ENS Impersonation Warning - Cointelegraph](https://cointelegraph.com/news/wallet-impersonation-scam-ens-uniswap) -- ENS autocomplete dangers, Nick Johnson's recommendation
- [ENS Impersonation Details - DailyCoin](https://dailycoin.com/uniswaps-hayden-adams-exposes-ens-wallet-impersonation-scam/) -- $600K losses, Hayden Adams' warning
- [Twitter Verification Trust Erosion](https://www.trustsignals.com/blog/what-twitters-new-blue-verified-badge-can-teach-us-about-trust) -- Lessons from paid verification destroying trust signals
- [Twitter Verification - Wikipedia](https://en.wikipedia.org/wiki/Twitter_verification) -- Gold/gray checkmark multi-tier evolution
- [Federated Search Scoring - Searchcraft](https://www.searchcraft.io/academy/federated-search) -- Weight multipliers per index, score normalization
- [Federated Search Guide - Algolia](https://www.algolia.com/blog/ux/what-is-federated-search) -- Multi-source result merging patterns
- [Trust UX Badges Research](https://www.userintuition.ai/reference-guides/trust-ux-badges-proof-and-the-research-behind-them) -- Progressive trust layering, placement effectiveness, Baymard Institute data
- [Misinformation in Search Results - Nature](https://www.nature.com/articles/s41598-024-61645-8) -- Warning banners can backfire; peer-reviewed 2024 study
- [TrustRank Algorithm](https://en.wikipedia.org/wiki/TrustRank) -- Semi-automated trust propagation (considered but rejected as overkill)
- [Cesium+ Pod REST API](http://doc.e-is.pro/cesium-plus-pod/REST_API.html) -- Profile search, creation, update endpoints and rate limits
- [Cesium+ Pod GitHub](https://github.com/duniter/cesium-plus-pod) -- Duniter Java API for off-chain profile storage
- [Crypto Wallet UX Design - Alien Design](https://www.thealien.design/insights/crypto-wallet-ux-design) -- Trust through transparency principles
- [Security Principles for Crypto Wallets - ACM](https://cacm.acm.org/blogcacm/security-principles-for-designing-an-unhackable-crypto-wallet/) -- Impersonation prevention best practices
- Ginkgo reference implementation (`/Users/poka/dev/ginkgo/lib/ui/widgets/first_screen/contact_search_page.dart`) -- Parallel search, local/network sectioning, dedup pattern
- Ginkgo API layer (`/Users/poka/dev/ginkgo/lib/g1/api.dart` lines 1554-1581) -- CesiumPlus Elasticsearch search query format
- Gecko existing codebase: `search_provider.dart`, `identity_providers.dart`, `cesium_plus_service.dart`, `name_by_address.dart`, `wallet_management_service.dart`
