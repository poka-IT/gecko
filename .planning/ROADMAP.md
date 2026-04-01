# Roadmap: Gecko

## Milestones

- ✅ **v0.2 Certification Alerts & Market Analysis** — Phases 1-2 (shipped 2026-03-25)
- 🚧 **v0.3 Noms CesiumPlus & Recherche** — Phases 3-5 (in progress)

## Phases

<details>
<summary>✅ v0.2 Certification Alerts & Market Analysis (Phases 1-2) — SHIPPED 2026-03-25</summary>

- [x] Phase 1: Certification Alerts (2/2 plans) — completed 2026-03-25
- [x] Phase 2: Market Analysis (2/2 plans) — completed 2026-03-25

</details>

### 🚧 v0.3 Noms CesiumPlus & Recherche (In Progress)

**Milestone Goal:** Intégrer les noms CesiumPlus dans la recherche et l'affichage, avec une UX anti-usurpation qui distingue clairement les identités on-chain des noms auto-déclarés.

- [ ] **Phase 3: Trust Visual System & Name Display** - Foundation: CesiumPlus name providers, trust badges, NameByAddress update, Hive persistence, anti-usurpation display rules
- [ ] **Phase 4: Hybrid Search** - Federated search merging identities and CesiumPlus names with sectioned results on mobile and desktop
- [ ] **Phase 5: CesiumPlus Name Registration** - Publish wallet name as CesiumPlus profile on rename, with retry on failure

## Phase Details

### Phase 3: Trust Visual System & Name Display
**Goal**: Users see CesiumPlus names for wallets without on-chain identity, with clear visual distinction between verified and self-declared names
**Depends on**: Phase 2 (v0.2 complete)
**Requirements**: DISP-01, DISP-02, DISP-03, DISP-04, TRUST-01, TRUST-03
**Success Criteria** (what must be TRUE):
  1. User sees a CesiumPlus name instead of a truncated address for a wallet that has no on-chain identity
  2. Verified identity names display a distinct visual indicator (badge/icon) that CesiumPlus names do not have, making the trust level obvious at a glance
  3. Profile view for a CesiumPlus-only wallet shows an explicit "self-declared name" label
  4. CesiumPlus names remain visible when the app is offline (persisted in Hive)
  5. A CesiumPlus name that exactly matches an existing on-chain identity name triggers a visible warning
**Plans**: 3 plans

Plans:
- [x] 03-01-PLAN.md — Foundation: cesiumNameProvider, NameSourceBadge widget, conflict detection provider, translation keys
- [ ] 03-02-PLAN.md — NameByAddress CesiumPlus fallback with Hive persistence + call site opt-in
- [ ] 03-03-PLAN.md — Profile view trust labels, WalletHeader CesiumPlus display, conflict warning, visual verification

**UI hint**: yes

### Phase 4: Hybrid Search
**Goal**: Users can search for wallets by CesiumPlus name alongside on-chain identities, with results clearly separated by trust level
**Depends on**: Phase 3
**Requirements**: SRCH-01, SRCH-02, SRCH-03, SRCH-04, TRUST-02
**Success Criteria** (what must be TRUE):
  1. User can type a name in the search field and see matching CesiumPlus wallets in addition to on-chain identities
  2. Search results are displayed in labeled sections with verified identities always above self-declared CesiumPlus names
  3. If the CesiumPlus pod is unreachable, identity search still works normally with no error shown to the user
  4. CesiumPlus names do not appear as autocomplete suggestions in payment/transfer address fields
**Plans**: 3 plans

Plans:
- [x] 04-01-PLAN.md — durt2 searchByName() method, cesiumPlusSearchProvider, section header translations
- [ ] 04-02-PLAN.md — Mobile search + desktop overlay CesiumPlus section integration
- [x] 04-03-PLAN.md — Desktop palette + inline search CesiumPlus integration, TRUST-02 verification

**UI hint**: yes

### Phase 5: CesiumPlus Name Registration
**Goal**: Users can make their wallet discoverable by publishing a custom name to CesiumPlus when they rename it
**Depends on**: Phase 3
**Requirements**: REG-01, REG-02
**Success Criteria** (what must be TRUE):
  1. When user renames a wallet to a custom name (not the default), the name is published to CesiumPlus automatically
  2. If CesiumPlus upload fails, the local rename still succeeds and a retry indicator is visible
  3. Default wallet names are never published to CesiumPlus
**Plans**: 1 plan

Plans:
- [ ] 05-01-PLAN.md — csPublishStatusProvider, publishNameToCesiumPlus service method, wallet_options.dart rename flow integration + retry indicator

**UI hint**: yes

## Progress

**Execution Order:**
Phases execute in numeric order: 3 → 4 → 5

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Certification Alerts | v0.2 | 2/2 | Complete | 2026-03-25 |
| 2. Market Analysis | v0.2 | 2/2 | Complete | 2026-03-25 |
| 3. Trust Visual System & Name Display | v0.3 | 0/3 | Not started | - |
| 4. Hybrid Search | v0.3 | 0/3 | Not started | - |
| 5. CesiumPlus Name Registration | v0.3 | 0/1 | Planned    |  |
