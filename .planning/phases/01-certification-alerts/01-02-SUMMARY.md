---
phase: 01-certification-alerts
plan: 02
subsystem: ui
tags: [flutter, riverpod, certification, alert-dot, widget]

# Dependency graph
requires:
  - phase: 01-certification-alerts/01
    provides: CertAlertDot widget, certAlertStatusProvider, contactCertAlertProvider
provides:
  - CertAlertDot overlay on home wallet tile medal icon (received certs)
  - Cert alert dot in mobile contacts list trailing section (sent certs)
  - Cert alert dot in desktop contacts panel row (sent certs)
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Stack overlay with Clip.none for dot indicators on existing icons"
    - "Inline Builder pattern for consuming Riverpod providers in Row children"
    - "contactCertAlertProvider for cross-wallet sent cert aggregation"

key-files:
  created: []
  modified:
    - lib/widgets/wallet_tile_membre.dart
    - lib/widgets/contacts_list.dart
    - lib/widgets/desktop/panels/contacts_panel.dart

key-decisions:
  - "Removed unused certs_list.dart import from contacts_list.dart (plan specified it but contactCertAlertProvider does not require CertDirection)"
  - "Used Builder widget for inline provider consumption in desktop panel to keep changes minimal"

patterns-established:
  - "Stack(clipBehavior: Clip.none) for overlaying alert dots on existing icons"
  - "contactCertAlertProvider aggregates across all owned wallets for contact cert status"

requirements-completed: [CERT-02]

# Metrics
duration: 3min
completed: 2026-03-25
---

# Phase 01 Plan 02: UI Integration Summary

**CertAlertDot wired into home wallet medal icon, mobile contacts, and desktop contacts for at-a-glance certification health**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-25T08:45:19Z
- **Completed:** 2026-03-25T08:48:33Z
- **Tasks:** 3 (2 auto + 1 checkpoint auto-approved)
- **Files modified:** 3

## Accomplishments
- Home wallet tiles show red/orange dot on medal icon when received certifications are expired or expiring within 30 days
- Mobile contacts list shows a small colored alert dot next to the balance for contacts with expiring/expired sent certifications
- Desktop contacts panel shows a cert alert dot between the name column and balance for contacts needing cert renewal
- All indicators use semantic theme colors (geckoColors.danger for expired, geckoColors.warning for expiring soon)
- Updates are automatic via Riverpod provider subscriptions (no manual refresh needed)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add CertAlertDot overlay to medal icon in WalletTileMembre** - `58b06d9b` (feat)
2. **Task 2: Add cert alert indicators to mobile ContactsList and desktop DesktopContactsPanel** - `f9e260e2` (feat)
3. **Task 3: Visual verification of cert alert indicators** - auto-approved checkpoint (no commit)

## Files Created/Modified
- `lib/widgets/wallet_tile_membre.dart` - Medal icon wrapped in Stack with CertAlertDot overlay using CertDirection.received
- `lib/widgets/contacts_list.dart` - Added _buildContactAlert helper using contactCertAlertProvider, 8px dot before balance
- `lib/widgets/desktop/panels/contacts_panel.dart` - Added inline Builder with contactCertAlertProvider, 7px dot before balance

## Decisions Made
- Removed `certs_list.dart` import from contacts_list.dart: the plan specified adding it but `contactCertAlertProvider` takes a plain String address (not CertDirection), so the import was unused and caused a lint warning
- Used inline Builder in desktop panel rather than extracting a separate method, keeping the change minimal and localized

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed unused import of certs_list.dart in contacts_list.dart**
- **Found during:** Task 2 (mobile contacts list)
- **Issue:** Plan specified importing `certs_list.dart` but `contactCertAlertProvider` does not use `CertDirection`, causing `dart analyze` warning
- **Fix:** Removed the unused import
- **Files modified:** lib/widgets/contacts_list.dart
- **Verification:** `dart analyze` reports no issues
- **Committed in:** f9e260e2 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Trivial import correction. No scope creep.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- CERT-01 and CERT-02 are both complete, finalizing Phase 01 (certification-alerts)
- All cert alert infrastructure (providers, widgets, UI integration) is in place
- Ready for Phase 02 or any follow-up work

## Self-Check: PASSED

- All 3 modified files exist on disk
- Both task commits (58b06d9b, f9e260e2) verified in git log

---
*Phase: 01-certification-alerts*
*Completed: 2026-03-25*
