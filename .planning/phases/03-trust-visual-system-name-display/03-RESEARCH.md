# Phase 3: Trust Visual System & Name Display - Research

**Researched:** 2026-03-31
**Domain:** CesiumPlus name integration with trust-tier visual distinction in Flutter wallet UI
**Confidence:** HIGH

## Summary

Phase 3 adds CesiumPlus name display for wallets without on-chain identity, with clear visual separation between verified (on-chain identity) and self-declared (CesiumPlus) names. This phase delivers the trust foundation that all subsequent phases (search, registration) depend on. The architecture must be correct before any CesiumPlus name appears anywhere in the app.

All required infrastructure already exists. The `durt2` CesiumPlusService has `getProfileByAddress()` which returns a profile map including the `title` field (the CesiumPlus name). The `G1WalletsList` Hive model already has a `csName` field (HiveField 4) that exists but is unused except in one place (`contact_selector.dart`). The `NameByAddress` widget has a clean fallback chain (identity name -> local wallet name) where CesiumPlus name insertion is a well-defined step. The `cesiumProfileProvider` already caches full profiles per address.

**Primary recommendation:** Add a `cesiumNameProvider(address)` that extracts `title` from the existing `cesiumProfileProvider`, modify `NameByAddress` with an opt-in `showCesiumPlusName` parameter, create a `NameSourceBadge` widget for trust indicators, and persist CesiumPlus names to `G1WalletsList.csName` for offline fallback.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DISP-01 | User sees CesiumPlus name for wallet without on-chain identity | `cesiumNameProvider` extracts title from existing `cesiumProfileProvider`; `NameByAddress` gets CesiumPlus fallback step |
| DISP-02 | Verified vs self-declared names visually distinct via badge/indicator | `NameSourceBadge` widget: shield icon for verified identity, muted italic + "self-declared" label for CesiumPlus |
| DISP-03 | Profile view shows "self-declared name" label for CesiumPlus profiles | `CesiumProfileViewScreen` and `WalletHeader` augmented with trust label when name source is CesiumPlus |
| DISP-04 | CesiumPlus names persisted in Hive for offline display | `G1WalletsList.csName` (HiveField 4) already exists, currently unused -- populate on first CesiumPlus name fetch |
| TRUST-01 | On-chain identity name never replaced/masked by CesiumPlus name | `hybridIdentityNameProvider` remains identity-only; CesiumPlus fallback only fires when identity name is null |
| TRUST-03 | Warning when CesiumPlus name matches existing on-chain identity | Conflict detection via `searchAddressByName(csName)` on Squid; if match found for different address, show warning |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **Never run `flutter build`, `flutter run`** -- only `flutter pub get` and `flutter analyze` allowed
- **Never use destructive git commands** -- no stash, checkout ., reset --hard, etc.
- **Git commits**: subject line only, no body, no Co-Authored-By
- **Riverpod conventions**: never use codegen (`@riverpod`), write providers manually
- **Desktop/mobile dual layout**: every new screen must support both via `embeddedMode` parameter
- **UTF-8 accented characters**: always proper diacritics in all translation strings
- **UI text**: never use plain `Text` widget for markdown-containing translation strings; use `TextMarkDown`
- **Localization**: `easy_localization` with translations in `assets/translations/` (en, fr, es, it)

## Standard Stack

### Core

No new packages needed. Everything is already installed:

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `durt2` | local `../durt2` | CesiumPlus REST API (`getProfileByAddress`, `getNameByAddress`) | Already provides all CesiumPlus HTTP logic |
| `flutter_riverpod` | ^3.2.1 | `FutureProvider.family` for per-address CesiumPlus name cache | Existing project pattern for all async state |
| `easy_localization` | ^3.0.8 | Trust badge labels, "self-declared name" strings | Existing i18n system |
| `hive_flutter` | existing | `G1WalletsList.csName` persistence for offline fallback | Existing persistence layer |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Flutter Material (`Icon`, `Tooltip`, `Chip`) | SDK | Visual trust indicators (shield icon, warning chips) | Badge/indicator widgets |
| `truncate` | existing | Name truncation in display widgets | Already used in `NameByAddress` |

### Alternatives Considered

None. All required capabilities exist in the current stack.

## Architecture Patterns

### Recommended Project Structure (new/modified files)

```
lib/
  providers/
    cesium_name_provider.dart       # NEW: CesiumPlus name + conflict detection
  widgets/
    name_by_address.dart            # MODIFY: add showCesiumPlusName opt-in
    name_source_badge.dart          # NEW: trust indicator widget
    wallet_header.dart              # MODIFY: add trust badge in identity section
  screens/
    cesium_profile_view_screen.dart # MODIFY: add "self-declared name" label
    profile_view.dart               # MODIFY: add trust context to profile
  models/
    g1_wallets_list.dart            # MODIFY: add displayInfo helper
  utils/
    identity_utils.dart             # MODIFY: add CesiumPlus conflict check helper
assets/
  translations/
    en.json, fr.json, es.json, it.json  # ADD: trust-related translation keys
```

### Pattern 1: CesiumPlus Name Provider (NEW)

**What:** A `FutureProvider.family` that extracts the `title` field from the existing `cesiumProfileProvider`, filters out meaningless defaults, and returns a displayable CesiumPlus name.

**When to use:** Whenever a widget needs to display a name for an address that may not have an on-chain identity.

**Example:**
```dart
// Source: existing cesiumProfileProvider pattern in lib/providers/cesium_profile_provider.dart
/// CesiumPlus name provider: cached per-address, auto-disposed when unused.
/// Returns null if no CesiumPlus profile or no title set.
/// CRITICAL: Does NOT replace identity names. Only used as fallback.
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

**Rationale:** Reuses the exact same pattern as `cesiumProfileProvider`. Riverpod auto-caches per address and auto-disposes. No manual TTL or separate persistent cache needed for v0.3.

### Pattern 2: NameByAddress CesiumPlus Fallback (MODIFY)

**What:** Add an opt-in `showCesiumPlusName` parameter (defaults `false`) to `NameByAddress`. When enabled, if `hybridIdentityNameProvider` returns null, try `cesiumNameProvider` before falling through to local wallet name.

**When to use:** Call sites that want CesiumPlus names displayed (contacts list, wallet tiles, search results). Payment-related screens should NOT enable it (anti-usurpation).

**Example:**
```dart
// Source: existing NameByAddress in lib/widgets/name_by_address.dart
class NameByAddress extends ConsumerWidget {
  const NameByAddress({
    super.key,
    required this.wallet,
    this.size = 20,
    this.color,
    this.fontWeight = FontWeight.w400,
    this.fontStyle = FontStyle.normal,
    this.showCesiumPlusName = false,  // NEW: opt-in
  });

  final bool showCesiumPlusName;  // NEW
  // ... existing fields ...

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ... existing identity name resolution ...

    // NEW: CesiumPlus fallback when identity name is null
    if (name == null && showCesiumPlusName) {
      final csNameAsync = ref.watch(cesiumNameProvider(wallet.address));
      // Display CesiumPlus name with distinct visual treatment (italic, muted color)
      // Also persist to g1WalletsBox.csName for offline fallback
    }

    // Existing: fall through to WalletName
  }
}
```

### Pattern 3: NameSourceBadge Widget (NEW)

**What:** A small, reusable widget showing trust level: verified shield for identity names, muted "self-declared" indicator for CesiumPlus names.

**When to use:** Alongside any name display where the trust source matters.

**Example:**
```dart
// NEW: lib/widgets/name_source_badge.dart
enum NameSource { identity, cesiumPlus }

class NameSourceBadge extends StatelessWidget {
  const NameSourceBadge({super.key, required this.source});
  final NameSource source;

  @override
  Widget build(BuildContext context) {
    return switch (source) {
      NameSource.identity => Tooltip(
        message: 'verifiedIdentity'.tr(),
        child: Icon(Icons.verified, size: 16, color: context.geckoColors.statusMember),
      ),
      NameSource.cesiumPlus => Tooltip(
        message: 'selfDeclaredName'.tr(),
        child: Text(
          'selfDeclared'.tr(),
          style: scaledTextStyle(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ),
    };
  }
}
```

### Pattern 4: G1WalletsList.displayInfo Helper (MODIFY)

**What:** Add a helper method to `G1WalletsList` that returns the best available name with trust metadata.

**Example:**
```dart
// Source: PITFALLS.md pitfall 8 recommendation
// In lib/models/g1_wallets_list.dart
({String name, bool isVerified}) get displayInfo {
  if (username != null) return (name: username!, isVerified: true);
  if (csName != null) return (name: csName!, isVerified: false);
  return (name: '', isVerified: false);
}
```

### Pattern 5: CesiumPlus Name Conflict Detection (TRUST-03)

**What:** Check whether a CesiumPlus name matches an existing on-chain identity name. Uses `searchAddressByName()` on the Squid indexer (already exists in durt2) to detect exact matches.

**When to use:** When displaying a CesiumPlus name, run conflict check once and cache result.

**Example:**
```dart
/// Provider that checks if a CesiumPlus name conflicts with an on-chain identity.
/// Returns the conflicting identity address if found, null otherwise.
final cesiumNameConflictProvider = FutureProvider.family<String?, String>((ref, address) async {
  final csName = await ref.watch(cesiumNameProvider(address).future);
  if (csName == null) return null;

  try {
    final squid = d.SquidService.client;
    final identities = await squid.searchAddressByName(csName);
    // Check for exact case-insensitive match on a DIFFERENT address
    for (final identity in identities) {
      if (identity.name.toLowerCase() == csName.toLowerCase() && identity.address != address) {
        return identity.address; // Conflict found
      }
    }
    return null;
  } catch (_) {
    return null; // Graceful degradation: no conflict check if Squid unavailable
  }
});
```

### Anti-Patterns to Avoid

- **Injecting CesiumPlus names into `walletNameIndexer`:** This in-memory map (20+ read sites in Gecko, defined in `durt2/squid_client_manager.dart`) carries implicit "verified" semantics. Mixing CesiumPlus names into it would silently show self-declared names everywhere as if they were identity names. Keep `walletNameIndexer` identity-only. Use the separate `cesiumNameProvider`.

- **Storing CesiumPlus names in `G1WalletsList.username`:** The `username` field (HiveField 3) is set from identity names in `NameByAddress` line 52. It must remain identity-only. CesiumPlus names go exclusively in `csName` (HiveField 4).

- **Making `showCesiumPlusName` default to `true`:** This would show CesiumPlus names in payment-related contexts (payment popup, transfer confirmation), creating an impersonation vector. It defaults to `false`; each call site must opt in deliberately.

- **Fetching CesiumPlus names during the identity subscription:** The `HybridIdentityNameNotifier` must remain identity-only. Adding CesiumPlus logic there conflates trust levels in the provider's semantics.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| CesiumPlus name lookup | Custom HTTP client in Gecko | `cesiumPlusServiceProvider.getProfileByAddress()` | All CesiumPlus HTTP logic belongs in durt2, already handles SSL, timeouts, error recovery |
| Per-address name cache | Manual Map<String, String> cache | `FutureProvider.family` with `autoDispose` | Riverpod handles lifecycle, deduplication, and disposal automatically |
| SS58<->base58 conversion | Custom pubkey encoding | `Utils.pubkeyV1ToAddress()` and `Address.decode()` in durt2 | Already handles network prefix, checksum, edge cases |
| Identity name conflict check | Manual on-chain name scan | `SquidService.searchAddressByName()` | Three-tier ranked search (exact, startsWith, contains) already implemented |
| Offline name persistence | Custom SQLite/ObjectBox store | `g1WalletsBox` (Hive) with `csName` field | Model already has the field (HiveField 4), just unused |

## Common Pitfalls

### Pitfall 1: CesiumPlus Name Overwrites Identity Name

**What goes wrong:** A CesiumPlus name is displayed for an address that actually has an on-chain identity, because the CesiumPlus fetch resolves before or alongside the identity fetch.
**Why it happens:** Race condition between `hybridIdentityNameProvider` and `cesiumNameProvider` if both are watched simultaneously.
**How to avoid:** The fallback chain in `NameByAddress` must be strictly sequential: check identity name first, ONLY fall through to CesiumPlus if identity name is definitively null (not loading). The CesiumPlus check should be inside the `identityNameAsync.when(data: ...)` branch, not at the widget top level.
**Warning signs:** Seeing a CesiumPlus name for a known member address.

### Pitfall 2: "Duniter Wallet" Default Title Displayed as CesiumPlus Name

**What goes wrong:** CesiumPlus profiles created for certification queue storage have `title: "Duniter Wallet"` (set in `saveCertificationQueue` line 666). This meaningless default gets displayed as a CesiumPlus name.
**Why it happens:** `cesiumNameProvider` returns the raw `title` without filtering defaults.
**How to avoid:** Filter out `"Duniter Wallet"` (and empty strings) in `cesiumNameProvider`. Also consider filtering titles that are just whitespace.
**Warning signs:** Many addresses showing "Duniter Wallet" as their name.

### Pitfall 3: Offline Mode Shows No Name at All

**What goes wrong:** `NameByAddress` returns `SizedBox.shrink()` for non-owner wallets when offline (no identity name, no CesiumPlus fetch possible). The wallet tile shows only a truncated address.
**Why it happens:** The CesiumPlus name is only in-memory (Riverpod cache). When offline, the Riverpod provider cannot fetch.
**How to avoid:** Populate `g1WalletsBox.csName` the first time a CesiumPlus name is fetched for an address. In offline mode, check `g1WalletsBox.get(address)?.csName` as a last-resort fallback. This provides a last-known-good name.
**Warning signs:** Going airplane mode and seeing addresses revert to truncated format.

### Pitfall 4: G1WalletsList.csName Not Populated on First Fetch

**What goes wrong:** `csName` field exists but is never written to, so offline fallback returns null even for previously-viewed addresses.
**Why it happens:** The existing code only writes `username` to `g1WalletsBox` (line 52 of `name_by_address.dart`). Nobody writes `csName`.
**How to avoid:** When `cesiumNameProvider` resolves a non-null name, also write it to `g1WalletsBox`:
```dart
final existing = g1WalletsBox.get(address) ?? G1WalletsList(address: address);
existing.csName = csName;
g1WalletsBox.put(address, existing);
```
**Warning signs:** `g1WalletsBox` entries with `csName == null` for addresses known to have CesiumPlus profiles.

### Pitfall 5: Stale CesiumPlus Name After Identity Creation

**What goes wrong:** A wallet had a CesiumPlus name "Bob's Shop". Then Bob creates an on-chain identity "BobMember". The CesiumPlus name still shows in some places because the `cesiumNameProvider` cache is still warm.
**Why it happens:** `cesiumNameProvider` is independent of identity subscription events.
**How to avoid:** When `hybridIdentityNameProvider._startNameSubscription()` receives a non-null identity name for an address, invalidate `cesiumNameProvider(address)`. The identity name will then take priority everywhere.
**Warning signs:** Both "BobMember" (identity) and "Bob's Shop" (CesiumPlus) appearing in different parts of the UI for the same address.

### Pitfall 6: Conflict Detection False Positives on Case Differences

**What goes wrong:** A CesiumPlus name "alice" triggers a conflict warning because on-chain identity "Alice" exists. The case-insensitive match is correct for security, but the warning text must explain why.
**Why it happens:** `searchAddressByName` does case-insensitive matching.
**How to avoid:** The conflict warning must show the exact on-chain identity name for comparison, not just a generic warning. "This name is similar to verified identity Alice (address 5xxx...)" gives the user useful context.
**Warning signs:** Users confused by warnings when names are only partially similar.

### Pitfall 7: Visual Badge Fatigue

**What goes wrong:** Shield icons on every single name make the UI noisy and users ignore them.
**Why it happens:** Adding trust badges to ALL names including verified ones creates visual clutter.
**How to avoid:** Research from Baymard Institute shows 1-3 trust signal types are optimal. Use positive indicator for verified names (shield/checkmark) and text label for self-declared names. Do NOT add badges to local wallet names (own wallets). Only show badges when there is ambiguity about trust level.
**Warning signs:** User testing shows badge blindness (users stop noticing the distinction).

## Code Examples

### Existing: How `NameByAddress` Currently Works

```dart
// Source: lib/widgets/name_by_address.dart (lines 32-87)
// 1. Watch hybridIdentityNameProvider(address) for on-chain identity name
// 2. If name found: display with optional "Infinite Name" substitution for created status
// 3. If name null: fall through to WalletName (local name from ObjectBox)
// 4. When offline: skip identity check entirely, show WalletName directly
```

**Key line (52):** When identity name is found, it's cached to Hive:
```dart
g1WalletsBox.put(wallet.address, G1WalletsList(address: wallet.address, username: name));
```
This must NOT be changed to include CesiumPlus names. CesiumPlus names go to `csName`.

### Existing: CesiumPlusService.getProfileByAddress()

```dart
// Source: durt2/lib/src/services/cesium_plus_service.dart (lines 116-154)
// Returns Map<String, dynamic>? with keys: title, description, city, socials, tags, avatar
// Returns null on 404 (no profile) or error
// The 'title' field is the CesiumPlus self-declared name
```

### Existing: Address Conversion Utilities

```dart
// Source: durt2/lib/src/services/utils.dart
// SS58 -> base58 pubkey (for CesiumPlus API calls):
//   Address.decode(address).pubkey -> base58BitcoinEncode(pubkeyBytes)
//   Already used in CesiumPlusService._addressToPubkeyBase58()

// base58 pubkey -> SS58 (for search results from CesiumPlus):
//   pubkeyV1ToAddress(pubkeyV1) in Utils class
//   Uses: base58Bitcoin.decode(pubkey) -> ss58.Address(prefix: Durt.i.network.ss58, pubkey: bytes).encode()
```

### Existing: Squid searchAddressByName (for conflict detection)

```dart
// Source: durt2/lib/src/services/squid/squid_account_queries.dart (lines 161-235)
// Three-tier ranked search: exact match, startsWith, contains
// Returns List<IdentitySuggestion> with {name, address}
// Use for TRUST-03: check if CesiumPlus name matches any on-chain identity
```

### Existing: CesiumProfileViewScreen (profile view)

```dart
// Source: lib/screens/cesium_profile_view_screen.dart
// Already supports embeddedMode parameter for desktop modals
// Currently shows: avatar, displayName (from hybridIdentityNameProvider), description, city, tags, socials
// MODIFICATION NEEDED: Add "self-declared name" label when name source is CesiumPlus
```

### Existing: NameByAddress Call Sites (10+ locations)

```
// All NameByAddress usage (must decide opt-in per call site):
// ENABLE showCesiumPlusName (safe contexts):
//   - wallet_tile.dart (contacts list)
//   - wallet_tile_membre.dart (member wallet tiles)
//   - contacts_list.dart (contact list display)
//   - search_result_list.dart (search results)
//   - global_search_overlay.dart (desktop search)
//   - global_search_palette_dialog.dart (desktop search palette)
//   - desktop_wallet_overview.dart (desktop wallet list)
//   - contacts_panel.dart (desktop contacts)
//
// KEEP showCesiumPlusName=false (payment/trust-sensitive contexts):
//   - payment_popup.dart (transfer confirmation)
//   - idty_status.dart (identity status display)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Names only from on-chain identity | CesiumPlus name fallback for non-identity wallets | Phase 3 (this phase) | Addresses without identity now show a name |
| `csName` field unused | `csName` populated on CesiumPlus fetch | Phase 3 (this phase) | Offline name display for previously-viewed profiles |
| No visual distinction for name sources | Shield badge (verified) vs text label (self-declared) | Phase 3 (this phase) | Users can tell verified from unverified names |

## Open Questions

1. **"self-declared" label placement in WalletHeader**
   - What we know: The `WalletHeaderIdentitySection` only renders when `hasIdentity` is true. For non-identity wallets, no identity section appears at all.
   - What's unclear: Should CesiumPlus names appear in the header section (currently identity-only) or in a new area? The header architecture assumes identity = member status line + certifications.
   - Recommendation: Add CesiumPlus name display in `WalletHeaderContent` where `identityName` is currently shown, with a conditional "self-declared" label below it. Do NOT show the identity status section (member/confirmed/etc.) since there is no identity.

2. **Exact visual treatment for the trust badge**
   - What we know: Bluesky uses dual badge (blue = verified, generic = self-declared). Baymard says 1-3 indicators optimal. Gecko already uses `Icons.verified` in zero places currently.
   - What's unclear: Exact icon choice, color, and size that fits the existing Gecko design language.
   - Recommendation: Use `Icons.verified` (Material, filled) in `geckoColors.statusMember` color (existing green) for verified identity names. Use italic text + `selfDeclared` translation string for CesiumPlus names. No icon for self-declared (text label is clearer per research).

3. **getNameByAddress vs reuse cesiumProfileProvider**
   - What we know: `cesiumProfileProvider` already fetches the full profile including `title`. A separate `getNameByAddress()` in durt2 would be a thinner call.
   - What's unclear: Is the overhead of fetching the full profile (including avatar base64) meaningful?
   - Recommendation: Reuse `cesiumProfileProvider` and extract `title` in `cesiumNameProvider`. This avoids a second HTTP call for addresses where the full profile is also viewed (e.g., profile screen). The full profile is already cached by Riverpod. Adding a separate `getNameByAddress()` to durt2 is NOT needed for this phase.

## Sources

### Primary (HIGH confidence)
- `lib/widgets/name_by_address.dart` -- NameByAddress widget: full fallback chain, 10+ call sites identified
- `lib/providers/identity_providers.dart` -- HybridIdentityNameNotifier: identity name subscription and cache
- `lib/providers/cesium_profile_provider.dart` -- cesiumProfileProvider: existing FutureProvider.family pattern
- `durt2/lib/src/services/cesium_plus_service.dart` -- getProfileByAddress, uploadProfile, all API patterns
- `durt2/lib/src/services/utils.dart` -- pubkeyV1ToAddress (base58 -> SS58 reverse conversion)
- `durt2/lib/src/services/squid/squid_account_queries.dart` -- searchAddressByName (conflict detection for TRUST-03)
- `lib/models/g1_wallets_list.dart` -- G1WalletsList model with unused csName (HiveField 4)
- `lib/screens/cesium_profile_view_screen.dart` -- CesiumPlus profile display, embeddedMode support
- `lib/widgets/wallet_header.dart` -- WalletHeaderContent, _IdentityStatusDisplay, _AvatarWithProfileLink
- `lib/screens/profile_view.dart` -- ProfileViewScreen, WalletAppBar title resolution
- `.planning/research/ARCHITECTURE.md` -- Recommended provider/service architecture
- `.planning/research/PITFALLS.md` -- 15 identified pitfalls with file/line references

### Secondary (MEDIUM confidence)
- `ginkgo/lib/ui/widgets/first_screen/contact_search_page.dart` -- Ginkgo search pattern (CesiumPlus + WoT parallel search, wrong trust order to avoid)
- `ginkgo/lib/g1/api.dart` (line 1560) -- Elasticsearch query format: `/user/profile/_search?q=title:{term}`
- `.planning/research/SUMMARY.md` -- Bluesky dual-badge system, ENS impersonation losses ($600K/month), Twitter Blue degradation

### Tertiary (LOW confidence)
- Baymard Institute trust badge research (via SUMMARY.md reference) -- 1-3 trust signal types optimal

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all components verified present in codebase, no new packages needed
- Architecture: HIGH - provider patterns directly read from existing code, component boundaries verified with grep across all call sites
- Pitfalls: HIGH - all 7 pitfalls identified from concrete code analysis with specific file/line references
- Trust model: HIGH - backed by Bluesky, ENS, and Twitter precedent research from project-level summary

**Research date:** 2026-03-31
**Valid until:** 2026-04-30 (stable domain, no external API changes expected)
