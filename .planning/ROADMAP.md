# Roadmap: Gecko v0.2 -- Certification Alerts & Market Analysis

## Overview

Two community-requested features for the Gecko wallet: visual certification expiration alerts (surfaced on home screen and contact list) and a market analysis tool for auditing transaction activity over a period. Both features build on existing infrastructure -- cert alert providers derive from the existing cert list, and market analysis reuses the server-side filtered history already wired to durt2's Squid indexer. Phase 1 delivers cert alerts as a quick win; Phase 2 delivers the full market analysis feature.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Certification Alerts** - Expiration/renewal alert providers and UI indicators on home screen, contact list, and cert tiles
- [ ] **Phase 2: Market Analysis** - Period selection, contact selection, per-contact totals, other-contacts discovery, and markdown export

## Phase Details

### Phase 1: Certification Alerts
**Goal**: Users can see at a glance which certifications need attention (expired or expiring soon) without navigating to the certification detail screen
**Depends on**: Nothing (first phase)
**Requirements**: CERT-01, CERT-02
**Success Criteria** (what must be TRUE):
  1. User viewing a certification list sees distinct icons/badges for expired certs and certs expiring within 30 days
  2. User on the home screen sees an alert indicator on wallet tiles when any received certification is expired or expiring soon
  3. User browsing contacts sees an alert indicator on contact entries where sent certifications need renewal
  4. Alert indicators update automatically when a certification is renewed on-chain (no manual refresh needed)
**Plans:** 2 plans
Plans:
- [x] 01-01-PLAN.md -- Cert alert provider, dot widget, and CERT-01 verification
- [x] 01-02-PLAN.md -- Wire alert indicators into home wallet tiles and contact lists
**UI hint**: yes

### Phase 2: Market Analysis
**Goal**: Users can audit their transaction activity with selected contacts over a chosen period, see sent/received totals, discover other involved contacts, and export results as markdown
**Depends on**: Phase 1
**Requirements**: MARKET-01, MARKET-02, MARKET-03, MARKET-04, MARKET-05
**Success Criteria** (what must be TRUE):
  1. User can select a date range (up to 365 days) for analysis and the selection is enforced
  2. User can select one or more contacts from their favorites/contacts list to include in the analysis
  3. User sees per-contact totals (amount sent, amount received, transaction count) and aggregate totals across all selected contacts
  4. User sees a list of "other contacts" discovered from the analyzed transactions who were not in the initial selection
  5. User can copy a markdown summary of the analysis results to the clipboard
**Plans**: TBD
**UI hint**: yes

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Certification Alerts | 2/2 | Complete | 2026-03-25 |
| 2. Market Analysis | 0/TBD | Not started | - |
