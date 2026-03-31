# Domain Pitfalls

**Domain:** CesiumPlus wallet name integration, search, display, and anti-usurpation UX
**Researched:** 2026-03-31

## Critical Pitfalls

Mistakes that cause rewrites, security issues, or major trust violations.

### Pitfall 1: Identity Impersonation via CesiumPlus Names

**What goes wrong:** A malicious user registers a CesiumPlus name identical to an on-chain identity name (e.g., "MaAude") for a different wallet address. The app displays both names identically, and users send funds to the impostor.

**Why it happens:** CesiumPlus names are self-declared with no validation against on-chain identities. The `title` field in CesiumPlus profiles is free-form text. Unlike identity names which require web-of-trust certification, anyone can claim any name.

**Consequences:** Financial loss for users. Complete erosion of trust in the name display system. Potentially reputational damage to the Gecko project.

**Prevention:** Three-layer defense:
1. **Visual hierarchy:** Identity names must ALWAYS have a visually distinct, prominent trust indicator (e.g., a shield icon or checkmark badge) that cannot be confused with CesiumPlus names. CesiumPlus names must have a different, clearly lower-trust visual treatment (e.g., italic, muted color, no badge, or an explicit "self-declared" label).
2. **Conflict detection:** When displaying a CesiumPlus name, check if an on-chain identity with the same name exists (via `searchAddressByName`). If so, show a warning: "This name is also used by a verified identity at address X."
3. **Search priority:** In search results, verified identity matches MUST always appear above CesiumPlus matches. Never let CesiumPlus results push identity results below the fold.

**Detection:** Test by creating a CesiumPlus profile with a name matching an existing identity. If the two are visually indistinguishable in any screen (search, contacts, transactions, profile header), this pitfall has been hit.

**Phase:** Must be addressed in the very first phase that displays CesiumPlus names anywhere. The visual system must be designed before any name display code is written.

### Pitfall 2: `NameByAddress` Widget Assumes Names Only Come From Identities

**What goes wrong:** The current `NameByAddress` widget (`lib/widgets/name_by_address.dart`) uses `hybridIdentityNameProvider` which ONLY queries the Squid indexer for on-chain identity names. Adding CesiumPlus name resolution as a fallback in this widget without updating ALL its call sites creates inconsistent trust semantics: some screens will show CesiumPlus names with no visual distinction, because callers assume `NameByAddress` output = verified identity name.

**Why it happens:** `NameByAddress` is used in 6+ contexts with different trust expectations:
- `contacts_list.dart` line 181: subtitle in contact tiles
- `contacts_panel.dart` line 274: desktop contact name
- `search_result_list.dart` line 85: address search results
- `global_search_overlay.dart` line 397: desktop wallet results
- `drag_tule_action.dart` line 80: drag info
- Various desktop modals

All callers currently assume the name returned is a verified identity name and apply no trust indicator. If `NameByAddress` silently starts returning CesiumPlus names too, all these sites become trust-ambiguous.

**Consequences:** Users see CesiumPlus names in places where they expect identity names, creating confusion about trust level. Impersonation attacks succeed in these contexts.

**Prevention:** Do NOT modify `NameByAddress` to return CesiumPlus names. Instead:
1. Create a NEW widget (e.g., `ResolvedNameByAddress`) that handles the multi-source resolution with trust indicators.
2. OR add a `showCesiumPlusName` parameter to `NameByAddress` (defaulting to `false`) so existing call sites are unaffected, and opt-in sites get the CesiumPlus fallback WITH a visual trust distinction.
3. Audit every call site before enabling CesiumPlus names.

**Detection:** Search for all usages of `NameByAddress` and verify each one displays appropriate trust indicators when showing CesiumPlus names.

**Phase:** Phase 1 (name display). Must be resolved before CesiumPlus names appear in any widget.

### Pitfall 3: `walletNameIndexer` Cache Mixing Identity and CesiumPlus Names

**What goes wrong:** The `squidService.walletNameIndexer` is a `Map<String, String?>` that currently stores only identity names. It is read in 20+ locations across the codebase (see grep results). If CesiumPlus names are added to this same cache without a trust-level annotation, every location that reads from it loses the ability to distinguish verified from unverified names.

**Specific high-risk locations:**
- `wallet_app_bar.dart` line 54: Builds the app bar title from `walletNameIndexer[address]` -- would display CesiumPlus name as if verified
- `profile_view.dart` line 72: Sets `walletName` in profile header data
- `contacts_list.dart` line 197: Passes name as `username` to `NavigationService.openProfile()`
- `market_analysis_provider.dart` line 195: Resolves contact names for analysis results
- `my_contacts.dart` lines 50-51: Sorts contacts by resolved name
- `desktop_drag_info_bar.dart` line 28: Shows name during drag operations

**Why it happens:** The temptation to "just add CesiumPlus names to the existing cache" is strong because the cache is already wired everywhere. But the cache has no concept of name source or trust level.

**Consequences:** Complete loss of trust distinction across the entire app. Every name display becomes ambiguous. Reverting requires touching all 20+ call sites.

**Prevention:** Create a SEPARATE cache for CesiumPlus names (e.g., `cesiumPlusNameCache` as a Riverpod provider). At display points, query both caches and display with appropriate trust indicators. The identity name cache remains the authoritative source; CesiumPlus is the fallback.

Alternative: Wrap cached names in a `ResolvedName` type that carries `({String name, NameSource source})` where `NameSource` is `identity | cesiumPlus | walletLocal`. This is cleaner but requires migrating all 20+ read sites.

**Detection:** If `walletNameIndexer` returns a non-null value for an address that has no on-chain identity, CesiumPlus names have been mixed in.

**Phase:** Phase 1. Must be decided before any CesiumPlus name caching is implemented.

### Pitfall 4: Race Condition When Registering CesiumPlus Name During Wallet Rename

**What goes wrong:** `WalletManagementService.renameWallet()` (line 144) currently only updates the local ObjectBox database. The v0.3 feature adds CesiumPlus registration when the user renames. If the CesiumPlus API call fails but the local rename succeeds, the app shows a name locally that does not exist on CesiumPlus. Other users see no name for this wallet.

**Why it happens:** `renameWallet()` is synchronous for the local write. CesiumPlus upload is async and requires network + PIN-authenticated signing. These are fundamentally different operations with different failure modes.

**Consequences:** User thinks their name is published but it is not. Other Gecko/Ginkgo users see no name. Debugging is hard because the local state looks correct.

**Prevention:**
1. Treat local rename and CesiumPlus registration as two separate, visible operations. Save locally first (always succeeds), then attempt CesiumPlus upload with clear feedback.
2. If CesiumPlus upload fails, show a persistent indicator (e.g., a small warning icon next to the wallet name) indicating "name not yet published."
3. Provide a retry mechanism for failed CesiumPlus uploads.
4. Do NOT gate the local rename on CesiumPlus success -- the user should always be able to rename locally even when offline.

**Detection:** Rename a wallet while in airplane mode. The local name should update. On reconnection, the CesiumPlus upload should retry or the user should be prompted.

**Phase:** Phase 3 (name registration).

## Moderate Pitfalls

### Pitfall 5: CesiumPlus API Unavailability Blocking Name Display

**What goes wrong:** The CesiumPlus pod (`data-pod`) is a separate service from the Duniter node and Squid indexer. It can be down independently. If CesiumPlus name resolution is in the critical path for rendering search results or contact lists, the entire UI blocks or shows errors when the pod is unreachable.

**Why it happens:** The existing `cesiumProfileProvider` already has silent degradation (returns `null` on error). But search results may not apply the same pattern: if the search waits for CesiumPlus results before rendering, a slow or dead pod blocks the entire search.

**Prevention:**
1. **Never block identity results on CesiumPlus.** Show identity search results immediately, then append CesiumPlus results when they arrive.
2. **Timeout:** CesiumPlus search should timeout after 3-5 seconds. The Ginkgo reference (`contact_search_page.dart` line 151) runs both searches in parallel with `Future.wait` -- this is correct, but Gecko should also handle the case where one of the two futures throws or times out.
3. **Graceful fallback:** If CesiumPlus is down, the search still works with identity-only results. No error toast/banner for CesiumPlus failures in the search flow.

**Detection:** Kill the CesiumPlus pod endpoint and perform a search. If the search hangs or shows an error, this pitfall has been hit.

**Phase:** Phase 2 (hybrid search).

### Pitfall 6: CesiumPlus Name Cache Growing Unbounded

**What goes wrong:** Every address viewed in search results, transaction history, or contact lists triggers a CesiumPlus name lookup that gets cached. Over months of use, the cache accumulates thousands of entries for addresses the user has no ongoing relationship with.

**Why it happens:** `FutureProvider.family` with an address parameter creates a new cached entry per address. Unlike the identity name subscription (which self-invalidates), CesiumPlus names have no push notification mechanism -- they are pure REST queries.

**Current evidence:** `cesiumProfileProvider` (`lib/providers/cesium_profile_provider.dart`) is already a `FutureProvider.family<Map<String, dynamic>?, String>` that caches per address. This will grow unbounded as users browse.

**Consequences:** Memory bloat. On low-RAM devices (budget Android phones, common in the Duniter community), this causes OOM crashes or sluggish performance.

**Prevention:**
1. **LRU eviction:** Limit the CesiumPlus name cache to ~500 entries with LRU eviction.
2. **TTL:** CesiumPlus names can change at any time (user updates their profile). Use a TTL of 5-10 minutes for cached names. After TTL, re-fetch on next display.
3. **Persistence with expiry:** For the persisted Hive/ObjectBox cache, store a `fetchedAt` timestamp and re-fetch if older than 1 hour.
4. **Riverpod `autoDispose`:** Use `autoDispose` on the CesiumPlus name provider so entries are cleaned up when no widget is watching them.

**Detection:** After browsing 100+ profiles over a week, check memory usage. If it grows monotonically, the cache is leaking.

**Phase:** Phase 1 (caching strategy). Must be designed upfront.

### Pitfall 7: Stale CesiumPlus Name After Identity Name Change

**What goes wrong:** A wallet has a CesiumPlus name "Alice's Shop". Later, the owner registers an on-chain identity with name "AliceShop". The cache still holds the CesiumPlus name. Depending on display logic, the user might see the CesiumPlus name when they should see the identity name (which takes precedence).

**Why it happens:** CesiumPlus names are fetched once and cached. Identity names arrive via subscription (WebSocket) or polling. If the identity name provider updates but the display logic checks CesiumPlus cache first (wrong priority order), the stale CesiumPlus name persists.

**Consequences:** Name inconsistency across the app. Users see different names for the same address on different screens.

**Prevention:** Name resolution priority must be strict and enforced everywhere:
1. On-chain identity name (from `hybridIdentityNameProvider`) -- always wins
2. CesiumPlus name (from CesiumPlus cache) -- only if no identity name
3. Local wallet name (from ObjectBox `wallet.name`) -- only for owned wallets with no identity/CesiumPlus name

When an identity name subscription fires a new value, invalidate the CesiumPlus name cache for that address. The `HybridIdentityNameNotifier._startNameSubscription()` already fires on name changes -- hook cache invalidation there.

**Detection:** Create a CesiumPlus profile for an address, then register an identity on that address. The identity name should replace the CesiumPlus name everywhere within seconds.

**Phase:** Phase 1 (name resolution architecture).

### Pitfall 8: `G1WalletsList.username` and `G1WalletsList.csName` Confusion

**What goes wrong:** The `G1WalletsList` model (`lib/models/g1_wallets_list.dart`) already has both `username` (field 3) and `csName` (field 4) Hive fields. But the codebase only uses `csName` in one place (`contact_selector.dart` line 71). The `username` field is set from identity names in `NameByAddress` line 52: `g1WalletsBox.put(wallet.address, G1WalletsList(address: wallet.address, username: name))`. If CesiumPlus names get stored in `username` too, the Hive cache conflates verified and unverified names.

**Why it happens:** `csName` exists but is unused. Developers might assume `username` is for "any display name" rather than specifically identity names.

**Consequences:** Contacts list shows CesiumPlus names with no way to distinguish them. The `isMember` field (field 5) is also rarely set, so there is no reliable way to determine trust level from the cached data alone.

**Prevention:** Use `csName` for CesiumPlus names and `username` exclusively for identity names, as was presumably the original intent. Add a helper method to `G1WalletsList` that returns the display name with trust metadata:
```dart
({String name, bool isVerified}) get displayInfo {
  if (username != null) return (name: username!, isVerified: true);
  if (csName != null) return (name: csName!, isVerified: false);
  return (name: '', isVerified: false);
}
```

**Detection:** After browsing CesiumPlus profiles, check `g1WalletsBox` entries. If `username` contains CesiumPlus names, the fields are being confused.

**Phase:** Phase 1 (data model decisions).

### Pitfall 9: Search Scoring Lets Unverified Results Drown Verified Ones

**What goes wrong:** The hybrid search returns both identity matches and CesiumPlus matches. If CesiumPlus has many profiles with common words (e.g., "wallet", "mon portefeuille"), a search for "Jean" might return 20 CesiumPlus results pushing the 2 verified identity results off the visible area.

**Why it happens:** The Ginkgo reference (`contact_search_page.dart` line 161-199) adds CesiumPlus results first, then WoT results with deduplication. This means CesiumPlus results appear ABOVE identity results in Ginkgo -- the opposite of the correct trust order.

**Consequences:** Users see unverified names first, may tap on an unverified result without scrolling to find the verified one. Impersonation risk.

**Prevention:**
1. **Strict section separation:** Show identity results in a labeled "Verified identities" section, CesiumPlus results in a separate "Wallet names (self-declared)" section below. Never interleave.
2. **Identity results always first:** Even if CesiumPlus API responds faster, hold the layout and show identity results at the top.
3. **Result count limit:** Cap CesiumPlus results at 5-10 per search query. Identity results have no cap.
4. **Exact match boosting:** If a CesiumPlus name exactly matches a search term AND an identity with the same name exists, suppress the CesiumPlus result or show it with a prominent usurpation warning.

**Detection:** Search for a name that exists as both an identity and a CesiumPlus profile. The identity result must appear first, prominently.

**Phase:** Phase 2 (search integration).

### Pitfall 10: CesiumPlus Name Registration Without Understanding Default Names

**What goes wrong:** `WalletNameService.isDefault(name)` checks for the `#` prefix convention (e.g., `#main`, `#2`, `#legacy`). If the CesiumPlus registration triggers on every rename including resets to default names, the app publishes "#main" or "Portefeuille principal" to CesiumPlus -- a meaningless name that wastes API calls and confuses other users.

**Why it happens:** The wallet rename dialog (`wallet_name_dialog_service.dart`) pre-fills with `WalletNameService.displayName(wallet.name)`, which translates `#main` to the locale-specific name. A user could "rename" their wallet to exactly the default translated name, triggering a CesiumPlus publish of that default name.

**Consequences:** CesiumPlus gets polluted with generic names like "Portefeuille principal", "Root Wallet", etc. Other users searching CesiumPlus see meaningless results.

**Prevention:**
1. Only publish to CesiumPlus when the name is NOT a default. Check `WalletNameService.isDefault(newName)` before triggering CesiumPlus upload. But since the dialog shows translated names (not `#main`), also check if the new name matches any known default display name via `_knownDefaults` or `_walletNPatterns`.
2. Show a confirmation step: "Publish this name so other users can find your wallet?" Only after explicit confirmation.
3. Never auto-publish. The PROJECT.md says "Enregistrement CesiumPlus quand l'utilisateur renomme un portefeuille (pas le nom par defaut)" -- this is correct but easy to get wrong in implementation.

**Detection:** Rename a wallet to the default name (accept the pre-filled text without changing it). If a CesiumPlus upload is triggered, this pitfall has been hit.

**Phase:** Phase 3 (name registration).

## Minor Pitfalls

### Pitfall 11: Missing Escaping in CesiumPlus Search Queries

**What goes wrong:** User searches for a string containing special characters (quotes, backslashes, Elasticsearch special chars). The CesiumPlus pod uses Elasticsearch. Unescaped queries cause 400 errors or unexpected results.

**Prevention:** Sanitize search input before sending to CesiumPlus API. At minimum, escape `+ - = && || > < ! ( ) { } [ ] ^ " ~ * ? : \ /` characters. The Ginkgo reference builds queries like `title:$searchTermLower OR issuer:$searchTerm` (`api.dart` line 1560) -- this is directly injected into Elasticsearch query syntax without escaping, which is a known Ginkgo bug to not replicate.

**Phase:** Phase 2 (search).

### Pitfall 12: CesiumPlus Profile `title` Field vs Wallet Name Confusion

**What goes wrong:** The CesiumPlus profile schema has a `title` field (used as the display name) and also `description`, `city`, etc. The existing `CesiumProfileScreen` (`cesium_profile_screen.dart` line 122) uses `title` from the existing profile or defaults to `'Duniter Wallet'`. If wallet name registration publishes to `title` but the user later edits their CesiumPlus profile (description, city, etc.), the `title` might get overwritten with a stale wallet name.

**Prevention:** When the user renames a wallet and publishes to CesiumPlus, update ONLY the `title` field. When the user edits their CesiumPlus profile (description, etc.), preserve the current `title` unless they explicitly change it. Use read-then-merge on profile saves, not blind overwrites.

**Phase:** Phase 3 (name registration).

### Pitfall 13: Visual Fatigue From Too Many Trust Indicators

**What goes wrong:** Adding badges, icons, and color coding for every name instance across the app creates visual noise. Users stop paying attention to trust indicators when they appear on every single name in every list.

**Prevention:** Apply trust indicators strategically:
1. **Search results:** Full trust indicator (icon + label) because this is where impersonation risk is highest.
2. **Profile header:** Full trust indicator.
3. **Transaction tiles:** Subtle indicator (color only, or small icon) because the user has already identified the counterparty.
4. **Contact list:** Medium indicator (icon only, no label) because these are saved contacts the user chose.
5. **Never show trust indicators for owned wallets** -- the user knows their own wallets.

**Phase:** Phase 1 (UI design). Must establish the visual system before implementing name display.

### Pitfall 14: Desktop Global Search Overlay Not Updated for CesiumPlus

**What goes wrong:** The `GlobalSearchOverlay` (`lib/widgets/global_search_overlay.dart`) currently shows two sections: "Wallets" (address matches) and "Identities" (name matches from Squid). Adding CesiumPlus results requires a third section, but the overlay has a fixed `maxHeight: 640` constraint. Three sections of results might not fit, especially on smaller desktop windows.

**Also:** The `_openFirstResult()` method (line 231) tries wallet results first, then identity results. If CesiumPlus results are added, the "first result on Enter" behavior needs to respect the trust hierarchy (identity > CesiumPlus).

**Prevention:** Add CesiumPlus as a distinct section below identities. Make the overlay scrollable (it already is via `ListView`). Update `_openFirstResult()` to prefer identity matches over CesiumPlus matches when multiple result types exist.

**Phase:** Phase 2 (search).

### Pitfall 15: Offline Mode Shows No Name At All

**What goes wrong:** `NameByAddress` (line 38-41) returns `WalletName(wallet: wallet)` when offline, which shows the local wallet name. But for non-owned wallets that only have CesiumPlus names, offline mode will show nothing (no identity name, no CesiumPlus name fetched). The `g1WalletsBox` Hive cache might have a stale `csName` from a previous session, but this field is currently unused.

**Prevention:** Populate `g1WalletsBox.csName` when CesiumPlus names are fetched. In offline mode, fall back to `g1WalletsBox.get(address)?.csName` for non-identity wallets. This provides a last-known-good name display even when both the indexer and CesiumPlus pod are unreachable.

**Phase:** Phase 1 (caching).

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Name display widget & visual system | Pitfall 1 (impersonation), Pitfall 2 (NameByAddress assumptions), Pitfall 13 (visual fatigue) | Design trust visual system first; create new widget or add opt-in parameter; strategic indicator placement |
| Cache architecture | Pitfall 3 (walletNameIndexer mixing), Pitfall 6 (unbounded cache), Pitfall 7 (stale after identity change), Pitfall 8 (G1WalletsList field confusion) | Separate caches by trust level; LRU + TTL; invalidate on identity subscription; use csName field correctly |
| Hybrid search | Pitfall 5 (API unavailability), Pitfall 9 (search scoring), Pitfall 11 (query escaping), Pitfall 14 (desktop overlay) | Non-blocking CesiumPlus search with timeout; strict section separation; sanitize input; scrollable overlay |
| Name registration | Pitfall 4 (race condition), Pitfall 10 (default name publishing), Pitfall 12 (title field overwrite) | Separate local/remote operations with retry; check isDefault before publishing; read-then-merge on saves |
| Offline mode | Pitfall 15 (no name at all) | Persist CesiumPlus names to Hive g1WalletsBox.csName for offline fallback |

## Sources

- **Gecko codebase analysis (HIGH confidence):**
  - `lib/widgets/name_by_address.dart`: Current name resolution chain (identity only)
  - `lib/providers/identity_providers.dart`: `hybridIdentityNameProvider` and `searchIdentityProvider` (Squid-only)
  - `lib/providers/cesium_profile_provider.dart`: Existing CesiumPlus profile fetch (no name-specific provider)
  - `lib/models/g1_wallets_list.dart`: `username` (field 3) and `csName` (field 4) Hive fields
  - `lib/services/wallet_name_service.dart`: Default name convention with `#` prefix
  - `lib/services/wallet_name_dialog_service.dart`: Rename dialog pre-fills with translated default
  - `lib/services/wallet_management_service.dart`: `renameWallet()` local-only; `uploadAvatarToCesiumPlus()` pattern for remote upload
  - `lib/widgets/global_search_overlay.dart`: Desktop search with wallet + identity sections
  - `lib/widgets/search_identity_query.dart`: Identity-only search results
  - `lib/screens/myWallets/cesium_profile_screen.dart`: CesiumPlus profile editor with `title` field usage
  - `squidService.walletNameIndexer`: 20+ read sites across the codebase (grep confirmed)

- **Ginkgo reference (MEDIUM confidence):**
  - `lib/ui/widgets/first_screen/contact_search_page.dart` lines 151-199: Parallel search with CesiumPlus first (wrong trust order to avoid)
  - `lib/g1/api.dart` line 1560: Unescaped Elasticsearch query injection (bug to not replicate)
