# Phase 1: Certification Alerts - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-25
**Phase:** 01-certification-alerts
**Areas discussed:** Alert indicator style, Expiration thresholds, Alert aggregation, Contact alert scope
**Mode:** --auto (all decisions auto-selected with recommended defaults)

---

## Alert Indicator Style (Home Wallet Tiles)

| Option | Description | Selected |
|--------|-------------|----------|
| Colored dot on medal icon | Small notification dot overlaid on the medal, worst-status color | ✓ |
| Badge with count | Numeric badge showing count of expiring certs | |
| Icon overlay | Replace/overlay the medal icon with a warning icon | |
| Color-coded tile border | Change the wallet tile border color | |

**User's choice:** [auto] Colored dot on medal icon (recommended default)
**Notes:** Minimal, consistent with mobile notification patterns, doesn't crowd the compact tile

---

## Expiration Thresholds

| Option | Description | Selected |
|--------|-------------|----------|
| Same as cert list (30d/90d) | Reuse existing CertTile thresholds for consistency | ✓ |
| More aggressive (60d only) | Single threshold at 60 days | |
| User-configurable | Let user set their own threshold in settings | |

**User's choice:** [auto] Same as cert list thresholds (recommended default)
**Notes:** Consistency with existing UI. Home/contact indicators trigger on expired and ≤30d only (most actionable)

---

## Alert Aggregation

| Option | Description | Selected |
|--------|-------------|----------|
| Worst-status indicator | Show single dot with the most urgent status color | ✓ |
| Count of alerts | Show numeric count of certs needing attention | |
| Status + count | Both worst color and numeric count | |

**User's choice:** [auto] Worst-status indicator (recommended default)
**Notes:** Simple, clear at a glance, avoids clutter on compact tiles

---

## Contact Alert Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Sent certs expiring | Alert when MY sent cert to contact is expiring (I can renew) | ✓ |
| Received certs expiring | Alert when contact's cert to me is expiring | |
| Both directions | Show alerts for both sent and received | |

**User's choice:** [auto] Sent certs expiring (recommended default)
**Notes:** Aligns with roadmap: "contacts sees an alert indicator where sent certifications need renewal"

---

## Claude's Discretion

- Provider architecture for alert status computation
- Exact positioning/sizing of dot indicator
- Widget composition approach (extend existing vs create new)

## Deferred Ideas

None
