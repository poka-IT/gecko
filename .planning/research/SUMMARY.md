# Research Summary: Gecko v0.2 -- Certification Alerts & Market Analysis

**Domain:** Blockchain wallet features -- certification monitoring and transaction analysis
**Researched:** 2026-03-25
**Overall confidence:** HIGH

## Executive Summary

Both features (certification expiration alerts and market transaction analysis) can be built entirely with Gecko's existing technology stack. No new packages are needed. The durt2 blockchain SDK already provides all required APIs: cert data with `expireOn` conversion to DateTime, server-side filtered transaction history with date range support, and real-time WebSocket subscriptions for cert activity changes.

The Ginkgo reference implementation (`../ginkgo`) was analyzed in detail. Its market analysis uses `calendar_date_picker2` for date picking and BLoC/Cubit for state management. Gecko should diverge from both choices: use Flutter's built-in `showDateRangePicker` (for consistency with existing transaction filters) and Riverpod Notifier (for consistency with existing architecture). The core algorithmic pattern from Ginkgo -- sequential per-contact fetching with 300ms delay and one-level "other contacts" discovery -- is sound and should be adopted.

For certification alerts, Gecko is ahead of Ginkgo. The existing `CertificationListNotifier` already fetches cert data, converts block heights to DateTime via `blocNumberToDate()`, subscribes to real-time cert activity, and persists state to SQLite. The `CertTile` widget already displays color-coded expiration badges. What remains is creating a derived provider that aggregates alert state across wallets and surfacing it on the home screen and contact list.

The market analysis requires more new code but is architecturally straightforward. Gecko already has `ServerFilteredHistoryNotifier` with full server-side filtering (including date range) wired to durt2's `getAccountHistoryFiltered()`. The new feature needs a `MarketAnalysisNotifier` that manages the workflow (contact selection, date range, sequential fetching, aggregation) and a new screen to display results.

## Key Findings

**Stack:** Zero new packages. All dependencies (durt2, flutter_riverpod, timeago, intl, flutter_markdown) already installed.
**Architecture:** Derived providers for cert alerts; new Notifier for market analysis. Both follow existing Gecko patterns.
**Critical pitfall:** Never use raw block heights for cert expiration -- always use DateTime from `CertDisplayItem.expireDate`. Ginkgo uses block arithmetic, but Gecko already does the right thing.

## Implications for Roadmap

Based on research, suggested phase structure:

1. **Phase 1: Certification Alert Providers + Home Screen Integration**
   - Addresses: cert alert indicators on home/contacts (FEATURES.md table stakes)
   - Avoids: Pitfall 7 (only watch certs for identity-holding wallets)
   - Rationale: Highest user value (Ma.aude's primary request). Infrastructure is 90% done. Small surface area.
   - Deliverables: `CertExpirationAlertProvider`, `HomeCertAlertProvider`, badge on wallet tiles, alert icon on contacts

2. **Phase 2: Market Analysis Core (Date Range + Contact Selection + Totals)**
   - Addresses: date range, contact selection, per-contact and aggregate totals
   - Avoids: Pitfall 2 (sequential fetching), Pitfall 4 (full pagination), Pitfall 8 (off-by-one dates)
   - Rationale: Requires new screen, new Notifier, contact multi-select. More code but well-scoped.
   - Deliverables: `MarketAnalysisNotifier`, new screen, date picker, contact selector, results display

3. **Phase 3: Market Analysis Enhancements (Other Contacts + Export)**
   - Addresses: "other contacts" discovery, markdown export
   - Avoids: Pitfall 6 (one-level recursion only)
   - Rationale: Enhancement layer on Phase 2. Can be deferred if Phase 2 takes longer.
   - Deliverables: Other contacts section, markdown generation, clipboard copy

**Phase ordering rationale:**
- Phase 1 before Phase 2 because cert alerts have smaller scope and higher perceived value. Quick win.
- Phase 2 before Phase 3 because core market analysis is useful without "other contacts" or export.
- Phase 3 is enhancement, not core. If timeline is tight, it can ship in a follow-up.

**Research flags for phases:**
- Phase 1: Standard patterns, unlikely to need deeper research. All APIs verified.
- Phase 2: May need phase-specific research on contact multi-select UX (how to present favorites vs. search vs. all contacts). The data layer is clear.
- Phase 3: "Other contacts" discovery needs careful testing with real Squid data to verify counterparty extraction from `TransactionDisplayItem`.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Verified by reading both codebases; all APIs exist and are already used |
| Features | HIGH | Based on community feedback (Ma.aude), Ginkgo reference, existing Gecko capabilities |
| Architecture | HIGH | Follows established Gecko patterns; derived providers + Notifier are standard Riverpod |
| Pitfalls | HIGH | Based on direct code analysis of both Ginkgo pitfalls and Gecko's existing solutions |

## Gaps to Address

- **Contact multi-select UX**: How should the market analysis contact picker work? Gecko has a contacts list and favorites but no multi-select component. This needs design decision during Phase 2.
- **Max date range enforcement**: PROJECT.md says "max 365 jours". Ginkgo enforces this with a dialog. Gecko needs the same validation. Trivial to implement but should not be forgotten.
- **Offline mode behavior**: What happens when the user is offline and tries to run market analysis? Need graceful degradation. Cert alerts should work from cache (persisted state).
- **UD vs. G1 amount display in market analysis**: Need to verify that `universalDividendsToggleProvider` is accessible from the market analysis context.
