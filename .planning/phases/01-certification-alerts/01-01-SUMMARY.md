---
phase: 01-certification-alerts
plan: 01
subsystem: providers, ui
tags: [riverpod, certification, expiration, alert-dot, flutter-widget]

# Dependency graph
requires: []
provides:
  - CertAlertStatus enum (none, expiringSoon, expired)
  - certAlertStatusProvider (address+direction -> worst-case alert status)
  - contactCertAlertProvider (contactAddress -> alert status across all owned wallets)
  - CertAlertDot widget (colored circle overlay for wallet tiles and contact avatars)
affects: [01-02-PLAN, home-wallet-tiles, contact-list]

# Tech tracking
tech-stack:
  added: []
  patterns: [synchronous Provider.family for derived alert state, switch expression for color mapping]

key-files:
  created:
    - lib/providers/cert_alert_provider.dart
    - lib/widgets/cert_alert_dot.dart
  modified: []

key-decisions:
  - "Used synchronous Provider.family (not AsyncNotifier) since certAlertStatusProvider derives from already-loaded certificationListProvider state"
  - "Short-circuit on expired status for performance -- no need to check remaining certs once worst status is found"
  - "CERT-01 verified complete in existing CertTile._buildExpirationDisplay() -- 4-tier expiration display already covers all cases"

patterns-established:
  - "Alert dot pattern: ConsumerWidget that watches a status provider and renders colored circle or SizedBox.shrink"
  - "Worst-case aggregation: iterate certs, short-circuit on worst status, track intermediate worst"

requirements-completed: [CERT-01]

# Metrics
duration: 3min
completed: 2026-03-25
---

# Phase 01 Plan 01: Cert Alert Provider & Dot Widget Summary

**CertAlertStatus enum with two derived providers (per-address and per-contact across all wallets) plus CertAlertDot overlay widget, with CERT-01 verified complete in existing CertTile code**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-25T08:38:31Z
- **Completed:** 2026-03-25T08:42:10Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Created CertAlertStatus enum with three values (none, expiringSoon, expired) and two Riverpod providers for computing worst-case certification alert status
- Created CertAlertDot widget that renders a colored notification badge (red for expired, orange for expiring soon) or nothing for healthy certs
- Verified CERT-01 completeness: existing CertTile._buildExpirationDisplay() already covers all 4 tiers (expired red, <=30d orange, <=90d amber, >90d green) plus null fallback

## Task Commits

Each task was committed atomically:

1. **Task 1: Create cert alert provider with status enum and two providers** - `64b6c229` (feat)
2. **Task 2: Create CertAlertDot widget and verify CERT-01 completeness** - `07c04a02` (feat)

## Files Created/Modified
- `lib/providers/cert_alert_provider.dart` - CertAlertStatus enum, certAlertStatusProvider (address+direction -> status), contactCertAlertProvider (contactAddress -> status across all owned wallets)
- `lib/widgets/cert_alert_dot.dart` - CertAlertDot ConsumerWidget with colored circle overlay for alert indicators

## Decisions Made
- Used synchronous `Provider.family` (not AsyncNotifier) since the provider derives from already-loaded certificationListProvider state -- no async needed
- Short-circuit on expired status: once any cert is found expired, immediately return `CertAlertStatus.expired` without checking remaining certs
- CERT-01 verified complete in existing code -- no modifications needed to cert_tile.dart

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- dart analyze cannot resolve `package:gecko/` imports in the worktree because `.dart_tool` is missing (path dependency `durt2` at `../durt2` doesn't resolve from worktree). Verified by copying files to the main repo and running dart analyze there -- both files pass with no issues.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- cert_alert_provider.dart and cert_alert_dot.dart are ready for consumption by Plan 01-02
- Plan 01-02 will wire CertAlertDot into WalletTileMembre (home screen) and contact list widgets
- contactCertAlertProvider is ready to be used for contact entries where sent certifications need renewal alerts

## Self-Check: PASSED

- lib/providers/cert_alert_provider.dart: FOUND
- lib/widgets/cert_alert_dot.dart: FOUND
- 01-01-SUMMARY.md: FOUND
- commit 64b6c229: FOUND
- commit 07c04a02: FOUND

---
*Phase: 01-certification-alerts*
*Completed: 2026-03-25*
