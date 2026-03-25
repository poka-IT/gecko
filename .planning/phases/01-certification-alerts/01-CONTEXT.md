# Phase 1: Certification Alerts - Context

**Gathered:** 2026-03-25
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase adds visual certification expiration/renewal alerts visible from the home screen wallet tiles and contact entries, complementing the existing expiration badges already shown in the certification list (`CertTile`).

**In scope:** Alert indicators on wallet tiles (home) and contact entries; provider logic to compute alert status from existing cert data; real-time updates via existing subscriptions.

**Out of scope:** New certification list features, notification system, push notifications, certification renewal action from the alert itself.

</domain>

<decisions>
## Implementation Decisions

### Alert Indicator Style (Home Wallet Tiles)
- **D-01:** Use a small colored dot indicator overlaid on the medal icon (`assets/medal.png`) in `WalletTileMembre`. Red dot for expired certs, orange/warning dot for expiring-soon certs. No count — just worst-status color.
- **D-02:** The dot should be subtle but visible — similar to notification badge patterns on mobile (small circle, positioned top-right of the medal icon).

### Expiration Thresholds
- **D-03:** Use the same thresholds as `CertTile._buildExpirationDisplay()`: expired (past date), expiring-soon (≤30 days), moderate (≤90 days). The home/contact indicators trigger on expired and ≤30 days only (the most actionable states).

### Alert Aggregation
- **D-04:** Show worst-status indicator only (not counts). If any received cert is expired → red dot. If none expired but some expiring-soon → orange dot. Otherwise no indicator.

### Contact Alert Scope
- **D-05:** On contact entries, show alert when the user's SENT certification to that contact is expiring or expired (the user can take action to renew). This aligns with the roadmap success criterion: "User browsing contacts sees an alert indicator on contact entries where sent certifications need renewal."

### CERT-01 Coverage
- **D-06:** The existing `CertTile._buildExpirationDisplay()` already implements CERT-01 (colored badges with countdown in the cert list). Verify it covers all cases and adjust if needed, but no major new work expected here.

### Auto-Update Behavior
- **D-07:** Alert indicators must react to real-time cert changes via existing `CertificationListNotifier` subscriptions and `hybridCertificationProvider`. No manual refresh needed — leverages existing reactive infrastructure.

### Claude's Discretion
- Provider architecture for the new alert status computation (how to aggregate cert expiration data into a simple alert status enum)
- Exact positioning and sizing of the dot indicator on the medal icon
- Whether to add the alert to `Certifications` widget or create a separate alert widget

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Certification Data Layer
- `lib/providers/certification_list_providers.dart` — CertificationListNotifier fetches cert data with `expireDate`; the provider to derive alert status from
- `lib/widgets/certs_list.dart` — CertDisplayItem model with `expireDate`; CertsList widget with CertDirection enum
- `lib/models/certification_display_item.dart` — Full CertificationDisplayItem with `isExpired`, `expirationText` helper methods

### Existing Expiration UI (CERT-01 reference)
- `lib/widgets/cert_tile.dart` — `_buildExpirationDisplay()` method — the existing colored badge logic for cert list items

### Home Screen Integration Points
- `lib/widgets/wallet_tile_membre.dart` — WalletTileMembre: where the home alert indicator needs to be added (near the medal icon and `Certifications` widget)
- `lib/widgets/certifications.dart` — Certifications widget showing received/sent counts via `hybridCertificationProvider`

### Alert Pattern Reference
- `lib/widgets/membership_alert_card.dart` — MembershipAlertCard: existing pattern for membership expiration alerts (reference for threshold logic)

### Stream/Subscription Infrastructure
- `lib/providers/stream_providers.dart` — `hybridCertificationProvider` providing real-time cert counts
- `lib/providers/connection_providers.dart` — Connection state management, squid availability

### Contacts Integration
- `lib/widgets/desktop/panels/` — ContactsPanel (desktop contacts view)
- `lib/screens/profile_view.dart` — Profile view where contacts are shown

### Theming
- `lib/extensions.dart` — `context.geckoColors` for semantic color tokens (danger, warning, success)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `CertTile._buildExpirationDisplay()`: Complete expiration badge rendering with 4-tier color coding — can be referenced for threshold constants
- `CertificationListNotifier`: Already fetches and caches cert data with `expireDate` per cert — no new data fetching needed
- `hybridCertificationProvider`: Provides real-time cert counts per address — could be extended or a parallel provider created for alert status
- `context.geckoColors`: Semantic color tokens (`.warning`, `.danger`, `.success`) already used throughout the app
- `MembershipAlertCard`: Pattern for computing alert urgency from expiration dates

### Established Patterns
- Riverpod family providers with address parameter (e.g., `certificationListProvider((address: addr, direction: dir))`)
- `AsyncNotifier` / `FutureProvider.family` for address-parameterized async data
- `ConsumerWidget` for stateless reactive widgets
- `scaleSize()` / `scaledTextStyle()` for responsive sizing

### Integration Points
- `WalletTileMembre.build()` — Insert alert indicator in the `Stack` around the medal icon or alongside the `Certifications` widget
- Contact list widgets — Add alert indicator alongside existing contact display
- New provider needed: aggregate cert expiration status per address → simple enum (none, expiringSoon, expired)

</code_context>

<specifics>
## Specific Ideas

- Reference Ginkgo's implementation (`../ginkgo`) for the cert alert concept, but adapt to Gecko's existing UI patterns
- Ma.aude's feedback emphasized "s'entraider" — the alerts should make it obvious when someone needs certification renewal help

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-certification-alerts*
*Context gathered: 2026-03-25*
