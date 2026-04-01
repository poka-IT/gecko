---
phase: 03-trust-visual-system-name-display
verified: 2026-03-31T23:00:00Z
status: passed
score: 14/14 must-haves verified
re_verification: false
---

# Phase 03: Trust Visual System / Name Display Verification Report

**Phase Goal:** Users see CesiumPlus names for wallets without on-chain identity, with clear visual distinction between verified and self-declared names
**Verified:** 2026-03-31
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | cesiumNameProvider returns the CesiumPlus title for an address, or null if none | VERIFIED | `lib/providers/cesium_name_provider.dart` line 10: `FutureProvider.family<String?, String>` watches `cesiumProfileProvider` and extracts `profile['title']` |
| 2 | cesiumNameProvider filters out 'Duniter Wallet' default title | VERIFIED | Line 16: `if (title == null \|\| title.isEmpty \|\| title == 'Duniter Wallet')` |
| 3 | NameSourceBadge shows a verified shield icon for identity names | VERIFIED | `lib/widgets/name_source_badge.dart` line 29-36: `NameSource.identity` renders `Icons.verified` with `statusMember` color |
| 4 | NameSourceBadge shows italic 'self-declared' text for CesiumPlus names | VERIFIED | Line 37-47: `NameSource.cesiumPlus` renders `'selfDeclaredName'.tr()` with `FontStyle.italic` |
| 5 | cesiumNameConflictProvider detects when a CesiumPlus name matches an on-chain identity on a different address | VERIFIED | `cesium_name_provider.dart` line 31-48: watches cesiumNameProvider, calls `searchAddressByName`, checks `result.address != address` with case-insensitive comparison |
| 6 | Translation keys exist in all 4 languages for trust-related strings | VERIFIED | All 5 keys (selfDeclaredName, selfDeclaredNameLabel, selfDeclaredNameTooltip, verifiedIdentity, nameConflictWarning) present with proper UTF-8 accents in en/fr/es/it |
| 7 | User sees a CesiumPlus name instead of a truncated address for a wallet without on-chain identity | VERIFIED | `lib/widgets/name_by_address.dart`: when `name == null` and `showCesiumPlusName == true`, renders CesiumPlus name in italic at alpha 0.8 |
| 8 | On-chain identity name is NEVER replaced by a CesiumPlus name | VERIFIED | CesiumPlus path fires only inside `if (name == null)` block (line 81); identity check at line 76 is always evaluated first |
| 9 | CesiumPlus names are persisted in g1WalletsBox.csName on first fetch for offline fallback | VERIFIED | Lines 89-96: existing entry updated via `existing.csName = csName`; new entry created with `G1WalletsList(address:..., csName: csName)` |
| 10 | Payment popup and idty_status do NOT show CesiumPlus names | VERIFIED | grep confirms zero occurrences of `showCesiumPlusName` in `payment_popup.dart` and `idty_status.dart` |
| 11 | Profile view for a CesiumPlus-only wallet shows an explicit 'self-declared name' label | VERIFIED | `cesium_profile_view_screen.dart` line 101: `'selfDeclaredNameLabel'.tr()` displayed when `!hasIdentityName && effectiveDisplayName != null` |
| 12 | Profile view for a wallet with on-chain identity shows a verified badge next to the name | VERIFIED | Line 94: `NameSourceBadge(source: hasIdentityName ? NameSource.identity : NameSource.cesiumPlus)` |
| 13 | WalletHeader shows a CesiumPlus name with self-declared label for wallets without identity | VERIFIED | `wallet_header.dart` line 115-117: `csName` fetched via `cesiumNameProvider` when `idtyStatus == IdtyStatus.none`; rendered with `NameSourceBadge(source: NameSource.cesiumPlus)` at line 185 |
| 14 | A CesiumPlus name matching an on-chain identity triggers a visible warning chip | VERIFIED | `cesium_profile_view_screen.dart` lines 118-140: conflict warning container with `errorContainer` background, `Icons.warning_amber_rounded`, and `nameConflictWarning.tr(args:...)` |

**Score:** 14/14 truths verified

---

### Required Artifacts

| Artifact | Provides | Status | Details |
|----------|----------|--------|---------|
| `lib/providers/cesium_name_provider.dart` | cesiumNameProvider and cesiumNameConflictProvider | VERIFIED | 49 lines, both providers defined with doc comments, filters 'Duniter Wallet', calls searchAddressByName |
| `lib/widgets/name_source_badge.dart` | NameSource enum and NameSourceBadge widget | VERIFIED | 51 lines, enum with identity/cesiumPlus variants, widget uses switch expression |
| `assets/translations/en.json` | English trust-related translation keys | VERIFIED | 5 keys present: selfDeclaredName, selfDeclaredNameLabel, selfDeclaredNameTooltip, verifiedIdentity, nameConflictWarning |
| `assets/translations/fr.json` | French translations with proper accents | VERIFIED | "auto-déclaré", "Identité vérifiée", proper UTF-8 throughout |
| `assets/translations/es.json` | Spanish translations | VERIFIED | "autodeclarado", "idéntico", "dirección" — proper UTF-8 |
| `assets/translations/it.json` | Italian translations | VERIFIED | "autodichiarato", "è identico", "Identità verificata" — proper UTF-8 |
| `lib/widgets/name_by_address.dart` | NameByAddress with showCesiumPlusName opt-in | VERIFIED | `showCesiumPlusName = false` default, opt-in path fully wired with Hive persistence and offline cache |
| `lib/widgets/wallet_tile.dart` | Wallet tile with CesiumPlus name enabled | VERIFIED | `showCesiumPlusName: true` at line 129 |
| `lib/widgets/wallet_tile_membre.dart` | Member tile with CesiumPlus name enabled | VERIFIED | `showCesiumPlusName: true` at line 131 |
| `lib/widgets/contacts_list.dart` | Contacts list with CesiumPlus name enabled | VERIFIED | `showCesiumPlusName: true` at line 188 |
| `lib/widgets/search_result_list.dart` | Search result with CesiumPlus name enabled | VERIFIED | `showCesiumPlusName: true` at line 92 |
| `lib/widgets/global_search_overlay.dart` | Search overlay with CesiumPlus name enabled | VERIFIED | `showCesiumPlusName: true` at line 403 |
| `lib/widgets/global_search_palette_dialog.dart` | Search palette with CesiumPlus name enabled | VERIFIED | `showCesiumPlusName: true` at line 494 |
| `lib/screens/home/desktop/desktop_wallet_overview.dart` | Desktop overview with CesiumPlus name enabled | VERIFIED | `showCesiumPlusName: true` at line 534 |
| `lib/widgets/desktop/panels/contacts_panel.dart` | Desktop contacts panel with CesiumPlus name enabled | VERIFIED | `showCesiumPlusName: true` at line 279 |
| `lib/screens/cesium_profile_view_screen.dart` | Trust-annotated profile display | VERIFIED | NameSourceBadge, selfDeclaredNameLabel, cesiumNameConflictProvider, nameConflictWarning all present |
| `lib/widgets/wallet_header.dart` | WalletHeader with CesiumPlus name for non-identity wallets | VERIFIED | WalletHeaderContent is ConsumerWidget, watches cesiumNameProvider, NameSourceBadge on both identity and cesiumPlus |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `cesium_name_provider.dart` | `cesium_profile_provider.dart` | `ref.watch(cesiumProfileProvider(address).future)` | WIRED | Line 12: direct watch confirmed |
| `cesium_name_provider.dart` | `durt2 SquidService.searchAddressByName` | conflict detection query | WIRED | Line 36: `d.SquidService.client.searchAddressByName(csName)` confirmed |
| `name_source_badge.dart` | `assets/translations/` | `easy_localization .tr()` | WIRED | `'selfDeclaredName'.tr()`, `'selfDeclaredNameTooltip'.tr()`, `'verifiedIdentity'.tr()` all present; keys exist in all 4 translation files |
| `name_by_address.dart` | `cesium_name_provider.dart` | `ref.watch(cesiumNameProvider(wallet.address))` | WIRED | Line 84: confirmed |
| `name_by_address.dart` | `lib/globals.dart` (g1WalletsBox) | `g1WalletsBox.put` for csName persistence | WIRED | Lines 92-96: `existing.csName = csName` and new entry creation confirmed |
| `cesium_profile_view_screen.dart` | `cesium_name_provider.dart` | `ref.watch(cesiumNameConflictProvider(address))` | WIRED | Line 37 confirmed |
| `cesium_profile_view_screen.dart` | `name_source_badge.dart` | `NameSourceBadge(source: ...)` | WIRED | Line 94 confirmed |
| `wallet_header.dart` | `cesium_name_provider.dart` | `ref.watch(cesiumNameProvider(address)).asData?.value` | WIRED | Line 116 confirmed |

---

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `name_by_address.dart` | `csNameAsync` / `csName` | `cesiumNameProvider` → `cesiumProfileProvider` → `cesiumPlus.getProfileByAddress(address)` | Yes — live HTTP API call | FLOWING |
| `cesium_profile_view_screen.dart` | `effectiveDisplayName` | `cesiumNameProvider` → same chain | Yes | FLOWING |
| `cesium_profile_view_screen.dart` | `conflictAddress` | `cesiumNameConflictProvider` → `SquidService.searchAddressByName` | Yes — live Squid query | FLOWING |
| `wallet_header.dart` | `csName` | `cesiumNameProvider` → same chain | Yes | FLOWING |
| `name_by_address.dart` | offline `cached?.csName` | `g1WalletsBox.get(wallet.address)` | Yes — Hive persistence, populated on first online fetch | FLOWING |

---

### Behavioral Spot-Checks

Step 7b: SKIPPED — no runnable entry points without `flutter run` (prohibited by CLAUDE.md). Static analysis passed (`dart analyze` reports no issues on all 5 modified/created Dart files).

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| DISP-01 | 03-02 | User sees CesiumPlus name for wallet without on-chain identity | SATISFIED | `name_by_address.dart`: CesiumPlus fallback renders name in italic; 8 safe call sites opt in |
| DISP-02 | 03-01, 03-03 | Identity names and CesiumPlus names are visually distinct via badge/indicator | SATISFIED | `NameSourceBadge`: verified shield (green icon) vs italic "self-declared" text; italic + alpha 0.8 in `NameByAddress`; `NameSourceBadge` in wallet_header and profile view |
| DISP-03 | 03-03 | Profile view shows "self-declared name" label for CesiumPlus profiles without identity | SATISFIED | `cesium_profile_view_screen.dart` line 101: `'selfDeclaredNameLabel'.tr()` shown when `!hasIdentityName && effectiveDisplayName != null` |
| DISP-04 | 03-02 | CesiumPlus names persisted in Hive (csName) for offline display | SATISFIED | `name_by_address.dart` lines 89-96: Hive write on first fetch; offline path at lines 46-65 reads cache; G1WalletsList.csName field confirmed at `lib/models/g1_wallets_list.dart` line 20 |
| TRUST-01 | 03-01, 03-02 | On-chain identity name never replaced or hidden by CesiumPlus name | SATISFIED | CesiumPlus path gated inside `if (name == null)` in `name_by_address.dart`; `payment_popup.dart` and `idty_status.dart` have zero `showCesiumPlusName` usage |
| TRUST-03 | 03-01, 03-03 | Warning shown when CesiumPlus name matches existing on-chain identity | SATISFIED | `cesiumNameConflictProvider` performs case-insensitive Squid search; profile view shows error-styled warning chip with `nameConflictWarning.tr()` |

**No orphaned requirements:** REQUIREMENTS.md maps DISP-01, DISP-02, DISP-03, DISP-04, TRUST-01, TRUST-03 to Phase 3 — all 6 are claimed by plans 03-01, 03-02, 03-03 and verified above.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `name_by_address.dart` | 75 | Comment uses word "placeholder" | Info | Comment text only: "not the placeholder" — describes legacy behavior, not a code stub |
| `wallet_header.dart` | 81, 148 | Comments use word "placeholder" | Info | Refer to loading shimmer containers — intentional UX pattern, not unimplemented code |

No blockers. No warnings. The `return null` occurrences in `cesium_name_provider.dart` are all legitimate conditional guards (null profile, absent title, absent csName, error fallback) — not stubs.

---

### Human Verification Required

**Task 3 of Plan 03-03 was a blocking human-verify checkpoint that remains pending.** The executor documented it as "pending human verification (checkpoint)" in the summary.

#### 1. Visual Trust Indicators End-to-End

**Test:** Launch the app. Navigate to a wallet without on-chain identity that has a CesiumPlus profile.
**Expected:** Wallet tile in contacts list shows CesiumPlus name in italic (not truncated address). Profile view shows name with "self-declared" badge and explicit "Self-declared name" label below the name.
**Why human:** Visual rendering, font style, and badge appearance cannot be verified programmatically without running the app.

#### 2. Verified Badge for Identity Members

**Test:** Open a wallet with a validated on-chain identity (member). View the wallet header and profile view.
**Expected:** Identity name displayed with green shield icon (verified badge). No "self-declared" label shown.
**Why human:** Visual rendering of the `Icons.verified` icon with `statusMember` color requires running the app.

#### 3. Conflict Warning Display

**Test:** If a test wallet exists with a CesiumPlus name matching an on-chain identity on a different address, open its profile view.
**Expected:** Warning chip with error background color, amber warning icon, and conflict message appears below the short pubkey.
**Why human:** Requires specific test data (a CesiumPlus name that collides with an on-chain identity) and live network connectivity.

#### 4. Offline Cache Fallback

**Test:** View a wallet that has a CesiumPlus name while online. Then enable airplane mode and return to that wallet.
**Expected:** The CesiumPlus name still displays in italic (served from Hive cache, not from network).
**Why human:** Requires device manipulation (airplane mode toggle) and visual confirmation.

#### 5. Payment Popup Safety

**Test:** Open the payment popup for any wallet. Verify the recipient name display.
**Expected:** Only identity name or truncated address shown. No CesiumPlus name appears in payment contexts.
**Why human:** Requires interaction with the payment flow UI.

---

### Gaps Summary

No gaps found. All must-haves are verified at all four levels (exists, substantive, wired, data-flowing). All 6 phase requirements are satisfied. All 6 commits documented in the summaries exist in git history.

The only pending item is Task 3 of Plan 03-03 (human visual verification checkpoint), which is expected and intentional — it cannot be automated.

---

_Verified: 2026-03-31_
_Verifier: Claude (gsd-verifier)_
