# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v0.2 — Certification Alerts & Market Analysis

**Shipped:** 2026-03-25
**Phases:** 2 | **Plans:** 4

### What Was Built
- CertAlertStatus providers + CertAlertDot overlay for at-a-glance cert health on home, contacts, and cert list
- MarketAnalysisService with paginated Squid queries, per-contact aggregation, other-contacts discovery, markdown generation
- MarketAnalysisScreen with date range picker (presets), contact multi-selector, progressive results, clipboard export
- 4-language translations (en, fr, es, it)

### What Worked
- Ginkgo as reference implementation accelerated design decisions — no ambiguity on UX flow
- Existing Squid query infrastructure (server-side filtering, pagination) was directly reusable
- Phase 1 was a clean quick win — small scope, clear providers, immediate user value
- Progressive analysis rendering (like Ginkgo) gives good UX feedback during long queries

### What Was Inefficient
- Phase 2 plans were large (3 tasks each with many files) — could have been split into 3 smaller plans for finer granularity

### Patterns Established
- Synchronous Provider.family for derived state from already-loaded data (cert alerts)
- MarketAnalysisService as stateless service with paginated query pattern (fetchAllPages loop)
- calendar_date_picker2 for date range selection in Flutter

### Key Lessons
- Server-side filtering via Squid is powerful — future analysis features should build on this
- BigInt amounts require careful handling in markdown export (manual division vs BalanceDisplay widget)
- Contact list from Hive is the natural input for user-facing selection UIs

### Cost Observations
- Model mix: 100% opus (researcher, planner, executor), sonnet for checker/verifier
- Sessions: 1 (full auto pipeline)
- Notable: End-to-end auto pipeline (discuss → plan → execute) completed both phases in a single session

---

## Cross-Milestone Trends

| Milestone | Phases | Plans | Timeline | Key Pattern |
|-----------|--------|-------|----------|-------------|
| v0.2 | 2 | 4 | 1 day | Ginkgo-referenced features, Squid query reuse |
