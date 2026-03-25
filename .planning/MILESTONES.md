# Milestones

## v0.2 Certification Alerts & Market Analysis (Shipped: 2026-03-25)

**Phases completed:** 2 phases, 4 plans, 11 tasks

**Key accomplishments:**

- CertAlertStatus enum with two derived providers (per-address and per-contact across all wallets) plus CertAlertDot overlay widget, with CERT-01 verified complete in existing CertTile code
- CertAlertDot wired into home wallet medal icon, mobile contacts, and desktop contacts for at-a-glance certification health
- Stateless MarketAnalysisService with paginated Squid queries, per-contact aggregation, other-contacts discovery, and markdown report generation; MarketAnalysisNotifier with progressive state updates, 365-day date validation, and contact selection management
- Complete market analysis screen with date range presets/calendar picker, contact multi-selector with avatars, progressive analysis results with per-contact and aggregate cards, other-contacts discovery section, and markdown clipboard export, wired into wallet options via route registration and 4-language translations

---
