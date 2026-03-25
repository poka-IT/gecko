# Feature Landscape

**Domain:** Blockchain wallet -- certification monitoring + transaction analysis
**Researched:** 2026-03-25

## Table Stakes

Features users expect based on the community feedback (Ma.aude) and Ginkgo reference.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Cert expiration icons in cert list | Ginkgo has this; users need visual cues to know which certs need renewal | Low | Gecko's `CertTile._buildExpirationDisplay()` already implements color-coded expiration badges (expired/30d/90d/green). This is **already done**. |
| Cert alert indicator on home/contacts | Ma.aude's core request: "see at a glance which contacts need re-certification" | Medium | New: aggregate cert alerts across owned wallets, show badge on wallet tiles and contact entries |
| Market analysis: date range selection | Core feature -- select period to analyze | Low | Reuse `showDateRangePicker` + existing `DateRangeFilter` model |
| Market analysis: contact selection | Must pick which contacts to analyze | Medium | Reuse existing contact/favorite system + multi-select UI |
| Market analysis: per-contact totals | Sent/received amounts and counts per contact | Medium | New provider that calls `getAccountHistoryFiltered` per contact with date filters |
| Market analysis: aggregate totals | Total sent/received across all selected contacts | Low | Sum per-contact results in provider |

## Differentiators

Features that set Gecko apart from Ginkgo's implementation.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Real-time cert alert updates | Gecko already has `subscribeCertActivity` wired up; alerts update without manual refresh | Low | Ginkgo does not have real-time cert subscription; Gecko does via `CertificationListNotifier._subscribeToCertActivity()` |
| "Other contacts" discovery in market analysis | Discover contacts involved in transactions that weren't in the initial selection | Medium | Ginkgo implements this; Gecko should too. Extract counterparty addresses from transaction results |
| Markdown export/clipboard | Copy analysis results as markdown text | Low | Simple string generation, clipboard copy with snackbar |
| Desktop-optimized market analysis layout | Gecko supports desktop (responsive_framework breakpoints); Ginkgo is mobile-focused | Medium | Use `responsive_framework` breakpoints for wider layouts on desktop |
| Cert alert persistence | Cache alert state in SQLite via `riverpod_sqflite` so alerts show immediately on app restart | Low | Gecko already uses `persist()` in cert list providers; extend to alert state |

## Anti-Features

Features to explicitly NOT build in this milestone.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Push/local notifications for cert expiry | Platform-specific complexity (Android channels, iOS permissions, background execution); not in stated requirements | Visual in-app alerts (badges, icons, colored indicators) visible from home screen |
| PDF export of market analysis | Ginkgo commented out PDF export for WASM compatibility; `pdf` package adds weight | Markdown text export via clipboard. PDF can be added later if requested |
| Historical cert change tracking | Tracking when certs were renewed over time adds data model complexity with little user value | Show current state only: active, expiring soon, expired |
| Automatic re-certification prompts | Would need to auto-navigate to certification flow; too aggressive UX | Show alert, let user tap to navigate to cert screen manually |
| Transaction graph/chart visualization | Charting libraries (fl_chart, syncfusion) are heavy; text summaries are clearer for the accounting use case (Ma.aude: epicerie participative) | Text-based totals with clear sent/received breakdown |

## Feature Dependencies

```
showDateRangePicker (Flutter SDK)
  -> MarketAnalysisState (date range selection stored)
    -> Per-contact filtered history fetch (durt2 getAccountHistoryFiltered)
      -> Aggregate totals computation
        -> "Other contacts" discovery
          -> Markdown summary generation

Cert list with expireDate (already working)
  -> CertExpirationAlertProvider (derives alert level per wallet)
    -> HomeCertAlertProvider (aggregates across owned wallets)
      -> Home screen badge display
      -> Contact list alert indicators
```

## MVP Recommendation

Prioritize:
1. **Cert alert indicators on home/contacts** -- highest user value (Ma.aude's primary request), leverages existing cert list infrastructure that already computes `expireDate`
2. **Market analysis with date range + contact selection + totals** -- second priority, requires new screen but reuses existing filter/history infrastructure
3. **Markdown export** -- quick win once analysis results exist, clipboard copy is trivial

Defer:
- **"Other contacts" discovery** -- can be Phase 2 enhancement; core analysis works without it
- **Desktop layout optimization** -- responsive_framework handles basic layout; polish can come later
- **Push notifications** -- out of scope, natural follow-up milestone
