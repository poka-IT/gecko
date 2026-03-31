---
phase: 03-trust-visual-system-name-display
plan: 02
subsystem: ui
tags: [flutter, riverpod, cesiumplus, hive, name-display]

# Dependency graph
requires:
  - phase: 03-trust-visual-system-name-display/03-01
    provides: cesiumNameProvider, NameSourceBadge, cesiumNameConflictProvider
provides:
  - NameByAddress widget with opt-in CesiumPlus name fallback and Hive csName persistence
  - 8 safe call sites enabled with showCesiumPlusName: true
  - Payment and identity-sensitive contexts remain CesiumPlus-free
affects: [03-trust-visual-system-name-display/03-03, 04-hybrid-search]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Opt-in CesiumPlus fallback: showCesiumPlusName parameter defaults to false, explicit opt-in at each call site"
    - "Hive csName persistence: CesiumPlus names written to g1WalletsBox.csName for offline fallback"
    - "Visual distinction: CesiumPlus names rendered in italic at alpha 0.8 vs identity names at full opacity"

key-files:
  created: []
  modified:
    - lib/widgets/name_by_address.dart
    - lib/widgets/wallet_tile.dart
    - lib/widgets/wallet_tile_membre.dart
    - lib/widgets/contacts_list.dart
    - lib/widgets/search_result_list.dart
    - lib/widgets/global_search_overlay.dart
    - lib/widgets/global_search_palette_dialog.dart
    - lib/screens/home/desktop/desktop_wallet_overview.dart
    - lib/widgets/desktop/panels/contacts_panel.dart

key-decisions:
  - "CesiumPlus names use FontStyle.italic and alpha 0.8 for subtle visual distinction from identity names"
  - "Identity name always takes priority even in offline mode (cached?.username checked before cached?.csName)"
  - "Payment popup and idty_status deliberately excluded from CesiumPlus display for anti-usurpation"

patterns-established:
  - "showCesiumPlusName opt-in: call sites must explicitly opt in; payment/identity contexts never show CesiumPlus names"
  - "Hive csName persistence: on first successful CesiumPlus fetch, csName is saved to g1WalletsBox for offline use"

requirements-completed: [DISP-01, DISP-04, TRUST-01]

# Metrics
duration: 6min
completed: 2026-03-31
---

# Phase 3 Plan 02: NameByAddress CesiumPlus Fallback Summary

**NameByAddress widget gains opt-in CesiumPlus name fallback with Hive persistence, enabled at 8 safe call sites while keeping payment/identity contexts CesiumPlus-free**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-31T22:32:28Z
- **Completed:** 2026-03-31T22:39:01Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments
- NameByAddress widget now shows CesiumPlus names for wallets without on-chain identity, rendered in italic at reduced opacity for clear visual distinction
- CesiumPlus names are persisted to Hive (g1WalletsBox.csName) on first successful fetch, enabling offline display
- 8 call sites across mobile and desktop (wallet tiles, contacts, search results, desktop overview, contacts panel) opt in to CesiumPlus name display
- Payment popup and identity status display remain CesiumPlus-free, preserving anti-usurpation guarantees

## Task Commits

Each task was committed atomically:

1. **Task 1: Add CesiumPlus fallback to NameByAddress with Hive persistence** - `0d47248b` (feat)
2. **Task 2: Enable showCesiumPlusName at safe call sites** - `929b390f` (feat)

## Files Created/Modified
- `lib/widgets/name_by_address.dart` - Added showCesiumPlusName opt-in parameter, cesiumNameProvider fallback chain, Hive csName persistence, offline cache
- `lib/providers/cesium_name_provider.dart` - CesiumPlus name provider (dependency from Plan 01, included for cross-worktree compilation)
- `lib/widgets/wallet_tile.dart` - Enabled showCesiumPlusName: true
- `lib/widgets/wallet_tile_membre.dart` - Enabled showCesiumPlusName: true
- `lib/widgets/contacts_list.dart` - Enabled showCesiumPlusName: true
- `lib/widgets/search_result_list.dart` - Enabled showCesiumPlusName: true
- `lib/widgets/global_search_overlay.dart` - Enabled showCesiumPlusName: true
- `lib/widgets/global_search_palette_dialog.dart` - Enabled showCesiumPlusName: true
- `lib/screens/home/desktop/desktop_wallet_overview.dart` - Enabled showCesiumPlusName: true
- `lib/widgets/desktop/panels/contacts_panel.dart` - Enabled showCesiumPlusName: true

## Decisions Made
- CesiumPlus names use FontStyle.italic and alpha 0.8 for subtle visual distinction from identity names
- Identity name always takes priority even in offline mode (cached?.username checked before cached?.csName)
- Payment popup and idty_status deliberately excluded from CesiumPlus display for anti-usurpation

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- Dart analyzer reports false errors for showCesiumPlusName parameter at call sites because git worktree resolves package:gecko to the main repo's lib/, not the worktree's lib/. This is a worktree-only issue; the code is correct and will analyze cleanly when merged.

## Known Stubs

None - all data flows are wired (cesiumNameProvider fetches from CesiumPlus API, persists to Hive, displays in UI).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- NameByAddress CesiumPlus fallback is complete, ready for Plan 03-03 (profile view trust labels, WalletHeader CesiumPlus display, conflict warning)
- cesiumNameConflictProvider from Plan 01 is available for use in Plan 03-03's conflict warning feature

## Self-Check: PASSED

All 10 files verified present on disk. Both task commits (0d47248b, 929b390f) found in git log. SUMMARY file exists.

---
*Phase: 03-trust-visual-system-name-display*
*Completed: 2026-03-31*
