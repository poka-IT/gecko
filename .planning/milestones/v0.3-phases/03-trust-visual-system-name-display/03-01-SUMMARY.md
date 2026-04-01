---
phase: 03-trust-visual-system-name-display
plan: 01
subsystem: ui, providers
tags: [riverpod, cesiumplus, trust-visual, anti-usurpation, i18n]

# Dependency graph
requires:
  - phase: none
    provides: existing cesiumProfileProvider and SquidService
provides:
  - cesiumNameProvider (CesiumPlus name lookup by address)
  - cesiumNameConflictProvider (impersonation detection)
  - NameSource enum and NameSourceBadge widget (verified vs self-declared indicator)
  - Trust-related translation keys in en/fr/es/it
affects: [03-02, 03-03, profile-view, search, wallet-display]

# Tech tracking
tech-stack:
  added: []
  patterns: [FutureProvider.family for derived name extraction, case-insensitive conflict detection via Squid]

key-files:
  created:
    - lib/providers/cesium_name_provider.dart
    - lib/widgets/name_source_badge.dart
  modified:
    - assets/translations/en.json
    - assets/translations/fr.json
    - assets/translations/es.json
    - assets/translations/it.json

key-decisions:
  - "cesiumNameProvider watches cesiumProfileProvider to reuse cached HTTP fetch, no extra network call"
  - "Conflict detection uses case-insensitive comparison for name matching"
  - "NameSourceBadge uses StatelessWidget (not ConsumerWidget) since it receives NameSource enum, no provider access needed"

patterns-established:
  - "Trust visual pattern: NameSource.identity = green verified icon, NameSource.cesiumPlus = italic muted text"
  - "CesiumPlus name filtering: null, empty, and 'Duniter Wallet' default are all treated as no-name"

requirements-completed: [DISP-02, TRUST-01, TRUST-03]

# Metrics
duration: 5min
completed: 2026-03-31
---

# Phase 03 Plan 01: Trust Visual System Foundations Summary

**cesiumNameProvider for CesiumPlus name lookup with impersonation detection, NameSourceBadge widget with verified/self-declared visual distinction, and trust translation keys in 4 languages**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-31T22:23:40Z
- **Completed:** 2026-03-31T22:28:49Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- cesiumNameProvider extracts CesiumPlus title from cached profile, filtering out meaningless defaults
- cesiumNameConflictProvider detects when a CesiumPlus name matches an on-chain identity on a different address (case-insensitive)
- NameSourceBadge widget renders green verified icon for identity names, italic muted text for self-declared CesiumPlus names
- 5 new translation keys (selfDeclaredName, selfDeclaredNameLabel, selfDeclaredNameTooltip, verifiedIdentity, nameConflictWarning) in en/fr/es/it with proper UTF-8 accents

## Task Commits

Each task was committed atomically:

1. **Task 1: Create cesiumNameProvider and cesiumNameConflictProvider** - `7a059c25` (feat)
2. **Task 2: Create NameSourceBadge widget and add translation keys** - `7d99fba9` (feat)

## Files Created/Modified
- `lib/providers/cesium_name_provider.dart` - cesiumNameProvider and cesiumNameConflictProvider
- `lib/widgets/name_source_badge.dart` - NameSource enum and NameSourceBadge widget
- `assets/translations/en.json` - 5 new trust-related translation keys
- `assets/translations/fr.json` - 5 new trust-related translation keys (French)
- `assets/translations/es.json` - 5 new trust-related translation keys (Spanish)
- `assets/translations/it.json` - 5 new trust-related translation keys (Italian)

## Decisions Made
- cesiumNameProvider watches cesiumProfileProvider to reuse cached HTTP fetch (no extra network call)
- Conflict detection uses case-insensitive string comparison for name matching
- NameSourceBadge uses StatelessWidget since it receives NameSource enum and needs no provider access

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Known Stubs
None - all providers return real data from existing services, widget is fully functional.

## Next Phase Readiness
- cesiumNameProvider and cesiumNameConflictProvider ready for consumption by profile view and search screens
- NameSourceBadge ready for integration wherever wallet names are displayed
- Translation keys available for trust-related UI across all supported languages

## Self-Check: PASSED

All files exist, all commits verified.

---
*Phase: 03-trust-visual-system-name-display*
*Completed: 2026-03-31*
