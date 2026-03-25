# Phase 2: Market Analysis - Context

**Gathered:** 2026-03-25
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers a market analysis tool that lets users audit their transaction activity with selected contacts over a chosen period. Users see per-contact totals (sent/received amounts and counts), discover other contacts involved in those transactions, and export results as markdown.

**In scope:** Date range selection (max 365 days), contact multi-selection from favorites, per-contact aggregation (sent/received/count), other-contacts discovery from transaction data, markdown export to clipboard, new analysis screen with navigation entry point.

**Out of scope:** Charts/visualizations, CSV export, UD-specific analysis, recurring/scheduled analysis, push notifications for analysis events, transaction detail drill-down from analysis results.

</domain>

<decisions>
## Implementation Decisions

### Date Range Selection
- **D-01:** Use `calendar_date_picker2` package for range selection (same as Ginkgo). Provides a single widget for picking start and end dates with `CalendarDatePicker2Type.range`.
- **D-02:** Enforce a maximum 365-day range. If user selects a range exceeding this, show a validation message and prevent analysis.
- **D-03:** Include preset shortcuts (30 days, 90 days, 365 days) as quick-select buttons above the calendar, pre-filling the range from today backwards.

### Contact Selection
- **D-04:** Multi-select from the user's favorites/contacts list using checkboxes. Include a "Select All / Deselect All" toggle.
- **D-05:** Show contact avatar, name (or short pubkey), and address in each row. Leverage existing `allContactsProvider` and `ContactService`.
- **D-06:** At least one contact must be selected before analysis can run. Show a clear message if no contacts exist in favorites.

### Results Layout
- **D-07:** Display an aggregate summary card at the top showing total sent, total received, and total transaction count across all selected contacts.
- **D-08:** Below the summary, show one card per selected contact with: contact name/avatar, amount sent to them, amount received from them, and transaction count. Cards follow existing Gecko card patterns.
- **D-09:** Amounts displayed in G1 currency format (using existing formatting utilities).

### Other Contacts Discovery
- **D-10:** Show a separate "Other contacts" section below the selected-contact cards. These are addresses found in the analyzed transactions that were NOT in the initial selection.
- **D-11:** Display each discovered contact with name (if resolvable via Cesium+ or Squid), address, and their sent/received totals relative to the analyzed wallet.

### Markdown Export
- **D-12:** Generate a structured markdown report with: header (analysis period, wallet name), per-contact table (Name | Sent | Received | Count), aggregate totals row, and an "Other contacts" section.
- **D-13:** Copy to clipboard using `Clipboard.setData()`. Show a snackbar confirmation after copy. No file export needed.

### Navigation & Screen Structure
- **D-14:** Add a new screen accessible from the wallet options or home screen. Route registration follows existing `AppRoutes.getRoutes()` pattern.

### Claude's Discretion
- Provider architecture for the analysis aggregation (how to structure the analysis state, whether to use a single notifier or multiple providers)
- Exact UI layout, spacing, and card styling within Gecko's established design language
- Whether to use a bottom sheet or full screen for date/contact selection steps
- Loading state presentation during analysis (spinner, skeleton, progressive rendering)
- How to handle the analysis when Squid indexer is offline (graceful degradation)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Transaction Data Layer
- `lib/providers/transaction_history_providers.dart` — Transaction history providers with pagination and server-side filtering
- `lib/providers/server_filtered_history_provider.dart` — `ServerFilteredHistoryNotifier` with `TransactionFilters` support (date range, address, amount)
- `lib/providers/transaction_filters_provider.dart` — `TransactionFiltersNotifier` managing filter state
- `lib/models/transaction_display_item.dart` — `TransactionDisplayItem` with address, username, amount, isReceived, timestamp, type fields
- `lib/models/transaction_filters.dart` — `TransactionFilters` model with startDate, endDate, address, amount fields

### Squid Query Layer (durt2)
- `durt2/lib/src/services/squid/squid_account_queries.dart` — `getAccountHistoryFiltered()` method and `SquidFilterBuilder`

### Contacts & Favorites
- `lib/services/contact_service.dart` — `ContactService` with `getAllContacts()`, `isContact()`, `toggleContact()`
- `lib/providers/profile_view_providers.dart` — `allContactsProvider` returning unsorted contacts from Hive

### Ginkgo Reference Implementation
- `../ginkgo/lib/ui/widgets/market_analysis/market_analysis_page.dart` — Main market analysis UI (date range, contact selection, orchestration)
- `../ginkgo/lib/ui/widgets/market_analysis/simple_txs_panel.dart` — Per-contact aggregation and markdown generation

### UI Patterns
- `lib/widgets/transaction_filters.dart` — Existing date picker and filter UI pattern
- `lib/widgets/commons/text_markdown.dart` — `TextMarkDown` widget for markdown rendering
- `lib/models/scale_functions.dart` — `scaleSize()` / `scaleFontSize()` for responsive sizing
- `lib/models/responsive_breakpoints.dart` — `isDesktopLayout(context)` for layout branching

### Navigation
- `lib/routes.dart` — `RouteNames`, `AppRoutes.getRoutes()`, `RouteArguments` for route registration

### Theming
- `lib/extensions.dart` — `context.geckoColors` for semantic color tokens

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `TransactionFilters` + `ServerFilteredHistoryNotifier`: Full server-side filtering with date range, address, amount — can be reused or extended for market analysis queries
- `TransactionDisplayItem.fromFilteredGraphQLNode()`: Already parses filtered Squid results with sent/received direction
- `allContactsProvider`: Returns all favorites from Hive — direct input for contact selection
- `ContactService`: CRUD for favorites — can check if discovered contacts are already favorites
- `Clipboard.setData()` pattern: Used throughout app for address/diagnostic copying
- `BasePaginatedNotifier<T>`: Pagination base if analysis results need paging
- `scaleSize()` / `scaleFontSize()`: Responsive sizing utilities
- `context.geckoColors`: Semantic color tokens (danger, warning, success)

### Established Patterns
- Riverpod family providers with address parameter for per-wallet data
- `AsyncNotifier` / `FutureProvider.family` for async state
- `ConsumerStatefulWidget` for screens with local state
- Date picker via `showDatePicker()` — works but range picker needs `calendar_date_picker2`
- Server-side filtering via `SquidFilterBuilder` with UTC date conversion

### Integration Points
- New route in `AppRoutes.getRoutes()` for the analysis screen
- Entry point from wallet options screen or home screen
- `allContactsProvider` for contact list input
- `ServerFilteredHistoryNotifier` pattern for querying Squid with date+address filters
- `Clipboard.setData()` for markdown export

</code_context>

<specifics>
## Specific Ideas

- Reference Ginkgo's market analysis implementation for functional flow, but adapt to Gecko's Riverpod architecture and UI patterns
- Ma.aude's use case: managing an epicerie participative — needs to audit which contacts transacted and how much over a period
- The analysis should work per-wallet (the currently selected wallet is the analysis subject)
- Ginkgo uses progressive rendering (300ms delay per card) — consider for UX during analysis loading

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-market-analysis*
*Context gathered: 2026-03-25*
