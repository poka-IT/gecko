# Milestones

## v0.3 Noms CesiumPlus & Recherche (Shipped: 2026-04-01)

**Phases completed:** 3 phases, 7 plans, 14 tasks

**Key accomplishments:**

- cesiumNameProvider for CesiumPlus name lookup with impersonation detection, NameSourceBadge widget with verified/self-declared visual distinction, and trust translation keys in 4 languages
- NameByAddress widget gains opt-in CesiumPlus name fallback with Hive persistence, enabled at 8 safe call sites while keeping payment/identity contexts CesiumPlus-free
- Trust indicators in profile view (verified/self-declared badges, conflict warning) and wallet header (CesiumPlus name with self-declared label for non-identity wallets, verified badge for members)
- Elasticsearch name search via durt2 searchByName() with Gecko FutureProvider and deduplication utility
- CesiumPlus search results integrated into mobile and desktop search with labeled trust-tier sections, deduplication, and italic styling
- CesiumPlus search integrated into GlobalSearchPaletteDialog and DesktopSearchSection with keyboard navigation, italic styling, and TRUST-02 compliance verified
- Fire-and-forget CesiumPlus name publication on wallet rename with retry indicator on failure

---

## v0.2 Certification Alerts & Market Analysis (Shipped: 2026-03-25)

**Phases completed:** 2 phases, 4 plans, 11 tasks

**Key accomplishments:**

- CertAlertStatus enum with two derived providers (per-address and per-contact across all wallets) plus CertAlertDot overlay widget, with CERT-01 verified complete in existing CertTile code
- CertAlertDot wired into home wallet medal icon, mobile contacts, and desktop contacts for at-a-glance certification health
- Stateless MarketAnalysisService with paginated Squid queries, per-contact aggregation, other-contacts discovery, and markdown report generation; MarketAnalysisNotifier with progressive state updates, 365-day date validation, and contact selection management
- Complete market analysis screen with date range presets/calendar picker, contact multi-selector with avatars, progressive analysis results with per-contact and aggregate cards, other-contacts discovery section, and markdown clipboard export, wired into wallet options via route registration and 4-language translations

---
