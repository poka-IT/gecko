---
phase: 04-hybrid-search
plan: 01
subsystem: api, providers
tags: [cesiumplus, elasticsearch, riverpod, search, durt2]

# Dependency graph
requires: []
provides:
  - CesiumPlusService.searchByName() method in durt2 (Elasticsearch query)
  - cesiumPlusSearchProvider (FutureProvider.family for search-by-name)
  - deduplicateCesiumPlusResults() utility function
  - selfDeclaredNamesSection and verifiedIdentitiesSection translation keys (en/fr/es/it)
affects: [04-hybrid-search plan 02, 04-hybrid-search plan 03]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Elasticsearch query via CesiumPlus pod REST API with input sanitization"
    - "Base58 pubkey to SS58 address conversion for CesiumPlus issuer results"
    - "FutureProvider.family with silent degradation (empty list on error)"

key-files:
  created:
    - lib/providers/cesium_plus_search_provider.dart
  modified:
    - ../durt2/lib/src/services/cesium_plus_service.dart
    - assets/translations/en.json
    - assets/translations/fr.json
    - assets/translations/es.json
    - assets/translations/it.json

key-decisions:
  - "Used Uri.replace(queryParameters:) for proper URL encoding of Elasticsearch query parameters"
  - "Used direct Address + base58BitcoinDecode for pubkey conversion instead of Utils instance method"

patterns-established:
  - "CesiumPlus search: sanitize input, query Elasticsearch, convert base58 issuers to SS58 addresses"
  - "Search provider graceful degradation: return empty list on any error (SRCH-04)"

requirements-completed: [SRCH-01, SRCH-04]

# Metrics
duration: 3min
completed: 2026-04-01
---

# Phase 04 Plan 01: CesiumPlus Search Foundation Summary

**Elasticsearch name search via durt2 searchByName() with Gecko FutureProvider and deduplication utility**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-01T10:32:26Z
- **Completed:** 2026-04-01T10:35:42Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Added searchByName() to CesiumPlusService in durt2 with Elasticsearch query, input sanitization, base58-to-SS58 conversion, 8s timeout, and graceful error handling
- Created cesiumPlusSearchProvider as FutureProvider.family with silent degradation and deduplicateCesiumPlusResults utility
- Added selfDeclaredNamesSection and verifiedIdentitiesSection translation keys in all 4 languages (en/fr/es/it) with proper UTF-8 accents

## Task Commits

Each task was committed atomically:

1. **Task 1: Add searchByName() to CesiumPlusService in durt2** - `6c0be3d` (feat)
2. **Task 2: Create cesiumPlusSearchProvider and add translation keys** - `c40a7966` (feat)

## Files Created/Modified
- `../durt2/lib/src/services/cesium_plus_service.dart` - Added searchByName() method (~77 LOC)
- `lib/providers/cesium_plus_search_provider.dart` - New file: CesiumPlusSearchResult class, cesiumPlusSearchProvider, deduplicateCesiumPlusResults
- `assets/translations/en.json` - Added selfDeclaredNamesSection, verifiedIdentitiesSection keys
- `assets/translations/fr.json` - Added selfDeclaredNamesSection, verifiedIdentitiesSection keys
- `assets/translations/es.json` - Added selfDeclaredNamesSection, verifiedIdentitiesSection keys
- `assets/translations/it.json` - Added selfDeclaredNamesSection, verifiedIdentitiesSection keys

## Decisions Made
- Used `Uri.replace(queryParameters:)` instead of string interpolation for Elasticsearch query URL to ensure proper encoding of special characters in search terms
- Used direct `Address` constructor + `base58BitcoinDecode` for pubkey-to-address conversion instead of `Utils.pubkeyV1ToAddress()` which requires a Utils instance -- the static approach is self-contained within the method

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- searchByName() and cesiumPlusSearchProvider are ready for UI integration in Plans 02 and 03
- deduplicateCesiumPlusResults() available for search result merging in Plan 02
- Translation keys ready for section headers in search results UI

## Self-Check: PASSED

- FOUND: durt2 cesium_plus_service.dart (searchByName method)
- FOUND: cesium_plus_search_provider.dart (provider + dedup utility)
- FOUND: 6c0be3d (durt2 commit)
- FOUND: c40a7966 (gecko commit)

---
*Phase: 04-hybrid-search*
*Completed: 2026-04-01*
