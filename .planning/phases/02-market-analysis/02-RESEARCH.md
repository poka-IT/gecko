# Phase 2: Market Analysis - Research

**Researched:** 2026-03-25
**Domain:** Flutter/Riverpod state management, Squid GraphQL filtering, date range selection, clipboard export
**Confidence:** HIGH

## Summary

This phase delivers a transaction analysis tool for auditing activity with selected contacts over a configurable date range. The existing codebase provides nearly all the building blocks: `ServerFilteredHistoryNotifier` already queries Squid with date/address filters via `SquidFilterBuilder`, `allContactsProvider` provides the contacts list from Hive, and `TransactionDisplayItem` has all fields needed for aggregation (address, amount, isReceived, username). The Ginkgo reference implementation confirms the functional flow: date selection, contact selection, progressive per-contact analysis, other-contacts discovery, and markdown generation.

The primary technical challenge is designing the aggregation layer. For each selected contact, the system must query all transactions within the date range involving both the user's wallet and the contact's address, then aggregate sent/received totals. This requires multiple Squid queries (one per contact) using the existing `getAccountHistoryFiltered()` with date and address filters. The "other contacts" discovery comes from collecting unique addresses from all fetched transactions that are not in the initial selection.

**Primary recommendation:** Build a dedicated `MarketAnalysisNotifier` (AsyncNotifier) that orchestrates sequential per-contact queries using durt2's existing `SquidService.client.getAccountHistoryFiltered()`, accumulates results into an immutable state model, and exposes aggregated totals. Use `calendar_date_picker2` v2.x for date range selection (matching Ginkgo). Use `ConsumerStatefulWidget` for the screen with local selection state for contacts/dates before analysis submission.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- D-01: Use `calendar_date_picker2` package for range selection (same as Ginkgo). Provides a single widget for picking start and end dates with `CalendarDatePicker2Type.range`.
- D-02: Enforce a maximum 365-day range. If user selects a range exceeding this, show a validation message and prevent analysis.
- D-03: Include preset shortcuts (30 days, 90 days, 365 days) as quick-select buttons above the calendar, pre-filling the range from today backwards.
- D-04: Multi-select from the user's favorites/contacts list using checkboxes. Include a "Select All / Deselect All" toggle.
- D-05: Show contact avatar, name (or short pubkey), and address in each row. Leverage existing `allContactsProvider` and `ContactService`.
- D-06: At least one contact must be selected before analysis can run. Show a clear message if no contacts exist in favorites.
- D-07: Display an aggregate summary card at the top showing total sent, total received, and total transaction count across all selected contacts.
- D-08: Below the summary, show one card per selected contact with: contact name/avatar, amount sent to them, amount received from them, and transaction count. Cards follow existing Gecko card patterns.
- D-09: Amounts displayed in G1 currency format (using existing formatting utilities).
- D-10: Show a separate "Other contacts" section below the selected-contact cards. These are addresses found in the analyzed transactions that were NOT in the initial selection.
- D-11: Display each discovered contact with name (if resolvable via Cesium+ or Squid), address, and their sent/received totals relative to the analyzed wallet.
- D-12: Generate a structured markdown report with: header (analysis period, wallet name), per-contact table (Name | Sent | Received | Count), aggregate totals row, and an "Other contacts" section.
- D-13: Copy to clipboard using `Clipboard.setData()`. Show a snackbar confirmation after copy. No file export needed.
- D-14: Add a new screen accessible from the wallet options or home screen. Route registration follows existing `AppRoutes.getRoutes()` pattern.

### Claude's Discretion
- Provider architecture for the analysis aggregation (how to structure the analysis state, whether to use a single notifier or multiple providers)
- Exact UI layout, spacing, and card styling within Gecko's established design language
- Whether to use a bottom sheet or full screen for date/contact selection steps
- Loading state presentation during analysis (spinner, skeleton, progressive rendering)
- How to handle the analysis when Squid indexer is offline (graceful degradation)

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MARKET-01 | Analyse de marche : selection de periode (max 365 jours) | `calendar_date_picker2` v2.x with `CalendarDatePicker2Type.range`, max 365-day enforcement, preset shortcuts |
| MARKET-02 | Analyse de marche : selection de contacts a analyser | `allContactsProvider` returns `List<G1WalletsList>` from Hive; multi-select with checkboxes, select-all toggle |
| MARKET-03 | Analyse de marche : totaux envoyes/recus par contact | `getAccountHistoryFiltered()` with date+address filters, `TransactionDisplayItem.isReceived` and `.amount` for aggregation |
| MARKET-04 | Analyse de marche : decouverte des autres contacts impliques dans les transactions | Collect unique `fromAddress`/`toAddress` from all fetched `TransactionDisplayItem`s, exclude initial selection, resolve names via Squid/Cesium+ |
| MARKET-05 | Analyse de marche : export/resume markdown des resultats | `Clipboard.setData()` pattern used throughout app, `StringBuffer` for markdown generation, snackbar confirmation via `SnackbarService` |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **Never use codegen** (`@riverpod` syntax) -- write providers manually
- Separate business logic into `lib/services/`, state management in `lib/providers/`
- Prefer `AsyncNotifier` for async state, `FutureProvider` for cached async data
- Document providers in English with `///`
- Use `ConsumerWidget`/`ConsumerStatefulWidget` for new UI code
- Use `TextMarkDown` from `lib/widgets/commons/text_markdown.dart` for strings containing markdown
- Never use `Text` widget for translation strings containing markdown formatting
- Use `easy_localization` for all user-facing strings
- Amounts are `BigInt` (centimes); use `BalanceDisplay` widget for currency formatting
- Responsive sizing via `scaleSize()` / `scaledTextStyle()` from `lib/models/scale_functions.dart`
- Desktop layout detection via `isDesktopLayout(context)` (breakpoint 900px)
- Never run `flutter build`, `flutter run`, or compilation commands
- `flutter pub get` is allowed
- Git commits: subject line only, no Co-Authored-By signature
- Never use destructive git commands

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_riverpod | 3.2.1 | State management | Already in pubspec, project standard |
| durt2 | 1.1.1 | Blockchain/Squid queries | Already in pubspec, provides `getAccountHistoryFiltered()` |
| calendar_date_picker2 | ^2.0.1 | Date range picker | Locked decision D-01, same as Ginkgo, Flutter SDK >= 3.27 requirement met (project uses 3.8.1) |
| easy_localization | 3.0.8 | Translations | Already in pubspec, project standard |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| intl | 0.19.0 | Date formatting (DateFormat) | Already in pubspec, for date display in UI and markdown |
| flutter/services | (SDK) | Clipboard.setData | For markdown copy-to-clipboard |

### New Dependency to Add
| Package | Version | Purpose |
|---------|---------|---------|
| calendar_date_picker2 | ^2.0.1 | Date range picker with `CalendarDatePicker2Type.range` |

**Installation:**
```bash
# Add to pubspec.yaml dependencies section:
#   calendar_date_picker2: ^2.0.1
flutter pub get
```

## Architecture Patterns

### Recommended Project Structure
```
lib/
├── providers/
│   └── market_analysis_provider.dart    # MarketAnalysisNotifier + state model + providers
├── services/
│   └── market_analysis_service.dart     # Stateless: query orchestration, aggregation, markdown generation
├── screens/
│   └── market_analysis_screen.dart      # Main screen (ConsumerStatefulWidget)
├── widgets/
│   └── market_analysis/
│       ├── date_range_selector.dart      # Calendar + preset shortcuts
│       ├── contact_selector.dart         # Multi-select contact list
│       ├── analysis_summary_card.dart    # Aggregate totals card
│       ├── contact_result_card.dart      # Per-contact results card
│       └── other_contacts_section.dart   # Discovered contacts section
└── models/
    └── market_analysis_state.dart        # Immutable state model (or inline in provider file)
```

### Pattern 1: Analysis State Model
**What:** An immutable state class holding all analysis inputs and results
**When to use:** As the state type for the `MarketAnalysisNotifier`
**Example:**
```dart
/// State for market analysis feature
class MarketAnalysisState {
  final DateTime? startDate;
  final DateTime? endDate;
  final Set<String> selectedContactAddresses;
  final Map<String, ContactAnalysisResult> contactResults;
  final Map<String, ContactAnalysisResult> otherContactResults;
  final bool isAnalyzing;
  final int processedContacts;
  final int totalContacts;
  final String? error;

  const MarketAnalysisState({
    this.startDate,
    this.endDate,
    this.selectedContactAddresses = const {},
    this.contactResults = const {},
    this.otherContactResults = const {},
    this.isAnalyzing = false,
    this.processedContacts = 0,
    this.totalContacts = 0,
    this.error,
  });

  BigInt get totalSent => contactResults.values
      .fold(BigInt.zero, (sum, r) => sum + r.totalSent);
  BigInt get totalReceived => contactResults.values
      .fold(BigInt.zero, (sum, r) => sum + r.totalReceived);
  int get totalTransactionCount => contactResults.values
      .fold(0, (sum, r) => sum + r.transactionCount);

  bool get canAnalyze =>
      startDate != null && endDate != null && selectedContactAddresses.isNotEmpty;
}

class ContactAnalysisResult {
  final String address;
  final String? username;
  final BigInt totalSent;
  final BigInt totalReceived;
  final int sentCount;
  final int receivedCount;

  int get transactionCount => sentCount + receivedCount;
}
```

### Pattern 2: Sequential Per-Contact Query with Progressive State Updates
**What:** Process contacts one by one, updating state after each to show progressive results
**When to use:** During analysis execution -- matches Ginkgo's progressive rendering pattern
**Example:**
```dart
/// In MarketAnalysisNotifier (extends Notifier<MarketAnalysisState>)
Future<void> runAnalysis(String walletAddress) async {
  final contacts = state.selectedContactAddresses.toList();
  state = state.copyWith(
    isAnalyzing: true,
    processedContacts: 0,
    totalContacts: contacts.length,
    contactResults: {},
    otherContactResults: {},
  );

  final allDiscoveredAddresses = <String>{};
  final genesisTime = await ref.read(genesisTimeProvider.future);

  for (int i = 0; i < contacts.length; i++) {
    final contactAddress = contacts[i];

    // Build filters for this contact within date range
    final filters = TransactionFilters(
      addresses: [contactAddress],
      exactMatchAddress: true,
      startDate: state.startDate,
      endDate: state.endDate,
    );

    // Fetch ALL pages for this contact
    final allItems = await _fetchAllPages(walletAddress, filters, genesisTime!);

    // Aggregate
    final result = _aggregateTransactions(allItems, contactAddress);

    // Collect other addresses
    for (final item in allItems) {
      allDiscoveredAddresses.add(item.address);
    }

    // Update state progressively
    state = state.copyWith(
      contactResults: {...state.contactResults, contactAddress: result},
      processedContacts: i + 1,
    );
  }

  // Process "other contacts" -- addresses not in initial selection
  final otherAddresses = allDiscoveredAddresses
      .where((a) => !state.selectedContactAddresses.contains(a))
      .where((a) => a != walletAddress && a.isNotEmpty);

  // ... resolve names and compute their totals

  state = state.copyWith(isAnalyzing: false);
}
```

### Pattern 3: Fetching ALL Pages for a Contact (Pagination Exhaustion)
**What:** The Squid API returns paginated results. For accurate totals, we must fetch ALL pages for each contact within the date range.
**When to use:** Inside the analysis loop, for each contact
**Example:**
```dart
Future<List<TransactionDisplayItem>> _fetchAllPages(
  String walletAddress,
  TransactionFilters filters,
  DateTime genesisTime,
) async {
  final allItems = <TransactionDisplayItem>[];
  String? cursor;
  bool hasMore = true;

  while (hasMore) {
    final result = await SquidService.client.getAccountHistoryFiltered(
      walletAddress,
      number: 50, // Larger page size for bulk fetching
      cursor: cursor,
      filters: filters,
    );

    if (result == null || result.items.isEmpty) break;

    allItems.addAll(result.items.map(
      (node) => TransactionDisplayItem.fromFilteredGraphQLNode(
        node, walletAddress, genesisTime,
      ),
    ));

    hasMore = result.hasNextPage;
    cursor = result.endCursor;
  }

  return allItems;
}
```

### Pattern 4: Route Registration
**What:** Register the new screen in the routing system
**When to use:** Adding the market analysis screen to `AppRoutes`
**Example:**
```dart
// In lib/routes.dart

// Add to RouteNames:
static const String marketAnalysis = '/marketAnalysis';

// Add to AppRoutes.getRoutes():
RouteNames.marketAnalysis: (context) {
  final args = RouteUtils.getArguments<MarketAnalysisArguments>(context);
  return MarketAnalysisScreen(walletAddress: args.walletAddress);
},

// New argument class:
class MarketAnalysisArguments extends RouteArguments {
  final String walletAddress;
  MarketAnalysisArguments({required this.walletAddress});
}
```

### Pattern 5: Markdown Generation
**What:** Generate a structured markdown summary for clipboard export
**When to use:** When user taps "Copy" button
**Example:**
```dart
String generateMarkdownReport(MarketAnalysisState state, String walletName) {
  final buffer = StringBuffer();
  final dateFormat = DateFormat('yyyy-MM-dd');

  buffer.writeln('# Market Analysis');
  buffer.writeln('**Wallet:** $walletName');
  buffer.writeln('**Period:** ${dateFormat.format(state.startDate!)} - ${dateFormat.format(state.endDate!)}');
  buffer.writeln();

  buffer.writeln('## Summary');
  buffer.writeln('| Contact | Sent | Received | Transactions |');
  buffer.writeln('|---------|------|----------|-------------|');

  for (final entry in state.contactResults.entries) {
    final r = entry.value;
    final name = r.username ?? getShortPubkey(r.address);
    final sent = (r.totalSent.toDouble() / 100).toStringAsFixed(2);
    final received = (r.totalReceived.toDouble() / 100).toStringAsFixed(2);
    buffer.writeln('| $name | $sent | $received | ${r.transactionCount} |');
  }

  // Totals row
  final totalSent = (state.totalSent.toDouble() / 100).toStringAsFixed(2);
  final totalReceived = (state.totalReceived.toDouble() / 100).toStringAsFixed(2);
  buffer.writeln('| **Total** | **$totalSent** | **$totalReceived** | **${state.totalTransactionCount}** |');

  if (state.otherContactResults.isNotEmpty) {
    buffer.writeln();
    buffer.writeln('## Other Contacts');
    buffer.writeln('| Contact | Sent | Received | Transactions |');
    buffer.writeln('|---------|------|----------|-------------|');
    for (final entry in state.otherContactResults.entries) {
      // ... same format
    }
  }

  return buffer.toString();
}
```

### Anti-Patterns to Avoid
- **Do not reuse `ServerFilteredHistoryNotifier` directly:** It is designed for the transaction history view with debouncing and filter panel coupling. The market analysis needs its own dedicated provider with different semantics (batch processing, aggregation, progressive results).
- **Do not use local StatefulWidget state for analysis results:** Put results in Riverpod state so they survive widget rebuilds and can be accessed by child widgets without prop drilling.
- **Do not query all contacts in parallel:** The Squid indexer may rate-limit or fail under concurrent load. Sequential queries with progressive UI updates (like Ginkgo does) is the correct pattern.
- **Do not use `BigInt.toDouble() / 100` for display:** Use `BalanceDisplay` widget for rendering amounts in the UI, which handles DU/G1 modes, currency symbols, and large number formatting correctly. Only use raw division for the markdown export text.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Date range selection | Custom date pickers | `calendar_date_picker2` with `CalendarDatePicker2Type.range` | Handles locale, validation, range highlighting, accessibility |
| Currency formatting | Manual amount/100 display | `BalanceDisplay` widget | Handles DU mode, M/N mode, scientific notation, currency symbols, locale |
| Clipboard operations | Custom clipboard logic | `Clipboard.setData(ClipboardData(text: ...))` | Standard Flutter API, already used throughout app |
| Snackbar feedback | Manual ScaffoldMessenger | `SnackbarService.showMessage()` | Consistent styling and behavior across app |
| Contact name resolution | Manual Cesium+ API calls | `squidServiceProvider.walletNameIndexer[address]` | Already indexed and cached |
| Short pubkey display | Manual substring | `getShortPubkey(address)` from `utils.dart` | Standard 8-char truncation used everywhere |

**Key insight:** The existing codebase has rich infrastructure for transaction querying, contact management, and currency display. The market analysis feature is primarily an orchestration and aggregation layer on top of existing capabilities, not a new data pipeline.

## Common Pitfalls

### Pitfall 1: Pagination Truncation
**What goes wrong:** Only fetching the first page (20 items) of transactions for a contact and reporting incomplete totals.
**Why it happens:** `getAccountHistoryFiltered()` returns paginated results with `hasNextPage`/`endCursor`. If you only call it once, you miss subsequent pages.
**How to avoid:** Always loop through all pages until `hasNextPage` is false. Use a larger page size (50) to reduce round trips.
**Warning signs:** Totals look suspiciously low compared to what the user expects.

### Pitfall 2: Date Range UTC Conversion
**What goes wrong:** Dates selected in local timezone are sent to Squid without UTC conversion, causing transactions near midnight to be included/excluded incorrectly.
**Why it happens:** `SquidFilterBuilder` expects UTC dates; the calendar picker returns local dates.
**How to avoid:** Convert local dates to UTC before passing to filters. For end date, set time to 23:59:59 local before converting (or use start of next day). The existing `TransactionFilterSheetContent` pattern shows how dates are handled in the filter system.
**Warning signs:** Missing transactions at day boundaries, or getting transactions from outside the selected range.

### Pitfall 3: Squid Offline State
**What goes wrong:** Analysis crashes or hangs when the Squid indexer is disconnected.
**Why it happens:** `getAccountHistoryFiltered()` returns null when Squid is offline.
**How to avoid:** Check `squidConnectionStatusProvider` before starting analysis. Show a clear message that market analysis requires an active Squid connection. The feature inherently requires the indexer -- there is no offline fallback.
**Warning signs:** Null results from queries, analysis stuck in loading state.

### Pitfall 4: "Other Contacts" Includes the User's Own Wallet
**What goes wrong:** The user's own wallet address appears in the "Other contacts" list.
**Why it happens:** Every transaction has a fromAddress and toAddress; one of them is always the user's wallet.
**How to avoid:** Filter out the user's wallet address AND all initially selected contact addresses when computing the "other contacts" set.
**Warning signs:** User sees their own wallet in the "Other contacts" section.

### Pitfall 5: Empty Contacts List
**What goes wrong:** User reaches the analysis screen but has no contacts/favorites, resulting in a confusing blank state.
**Why it happens:** New users or users who haven't added favorites yet.
**How to avoid:** Check `allContactsProvider` length and show a clear empty-state message explaining that contacts must be added first (D-06).
**Warning signs:** Blank contact selection list with no guidance.

### Pitfall 6: Amount Aggregation Overflow
**What goes wrong:** Summing BigInt amounts causes incorrect values or crashes.
**Why it happens:** BigInt arithmetic is straightforward in Dart, but accidentally mixing BigInt with int or double creates type errors.
**How to avoid:** Keep all aggregation in BigInt space. Only convert to double for display or markdown export at the final rendering step.
**Warning signs:** Type errors in aggregation logic, or amounts displayed as 0.

## Code Examples

### Contact Selection from allContactsProvider
```dart
// Source: lib/providers/profile_view_providers.dart
final allContactsProvider = Provider<List<G1WalletsList>>((ref) {
  return contactsBox.toMap().values.toList();
});

// G1WalletsList fields available:
// - address (String)
// - username (String?)
// - csName (String?) -- Cesium+ name
// - balance (double?)
```

### Querying Filtered Transactions via durt2
```dart
// Source: durt2/lib/src/services/squid/squid_account_queries.dart
// getAccountHistoryFiltered() returns FilteredTransactionResult<...>

final filters = TransactionFilters(
  addresses: [contactAddress],
  exactMatchAddress: true,
  startDate: startDate.toUtc(),
  endDate: endDate.toUtc(),
);

final result = await SquidService.client.getAccountHistoryFiltered(
  walletAddress,
  number: 50,
  cursor: null,
  filters: filters,
);
// result.items -- list of GraphQL nodes
// result.hasNextPage -- pagination
// result.endCursor -- for next page
```

### TransactionDisplayItem Key Fields for Aggregation
```dart
// Source: lib/models/transaction_display_item.dart
// After calling TransactionDisplayItem.fromFilteredGraphQLNode():
// - item.isReceived -- true if this was received by the wallet
// - item.amount -- BigInt amount (in centimes)
// - item.address -- the OTHER party's address
// - item.username -- the OTHER party's name (if available)
// - item.fromAddress / item.toAddress -- explicit addresses
```

### Clipboard Pattern Used in Gecko
```dart
// Source: lib/widgets/wallet_header.dart (line 455)
Clipboard.setData(ClipboardData(text: address));

// With snackbar feedback:
// Source: lib/services/snackbar_service.dart
SnackbarService.showMessage(context, message: 'copiedToClipboard'.tr());
```

### Route Registration Pattern
```dart
// Source: lib/routes.dart
// In RouteNames class:
static const String marketAnalysis = '/marketAnalysis';

// In AppRoutes.getRoutes() map:
RouteNames.marketAnalysis: (context) {
  final args = RouteUtils.getArguments<MarketAnalysisArguments>(context);
  return MarketAnalysisScreen(walletAddress: args.walletAddress);
},
```

### Entry Point from Wallet Options
```dart
// Source: lib/screens/myWallets/wallet_options.dart
// Pattern: InkWell with icon + label row, same style as Cesium Profile button

InkWell(
  onTap: () {
    Navigator.pushNamed(
      context,
      RouteNames.marketAnalysis,
      arguments: MarketAnalysisArguments(walletAddress: widget.wallet.address),
    );
  },
  child: Container(
    padding: EdgeInsets.symmetric(
      horizontal: scaleSize(17),
      vertical: scaleSize(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.analytics_outlined,
          size: scaleSize(22),
          color: context.geckoColors.info.withValues(alpha: 0.8),
        ),
        ScaledSizedBox(width: 18),
        Expanded(
          child: Text(
            'marketAnalysis'.tr(),
            style: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSurface),
            softWrap: true,
          ),
        ),
      ],
    ),
  ),
),
```

### Calendar Date Picker 2 Usage (from Ginkgo reference)
```dart
// Source: ../ginkgo/lib/ui/widgets/market_analysis/market_analysis_page.dart
final List<DateTime?>? results = await showCalendarDatePicker2Dialog(
  context: context,
  config: CalendarDatePicker2WithActionButtonsConfig(
    calendarType: CalendarDatePicker2Type.range,
    firstDate: DateTime(2022),
    lastDate: DateTime.now(),
  ),
  dialogSize: const Size(325, 400),
  value: _selectedDates,
);

// Validation pattern:
if (startDate != null && endDate != null) {
  final int difference = endDate.difference(startDate).inDays;
  if (difference > 365) {
    _showInvalidRangeDialog();
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Ginkgo BLoC + direct API | Gecko Riverpod + durt2 SquidService | Phase 1 (2026-03) | Use Riverpod patterns, not BLoC from Ginkgo reference |
| calendar_date_picker2 v1.x | calendar_date_picker2 v2.0.1+ | Flutter 3.27+ | v2 API; project uses SDK 3.8.1 so v2 is correct |
| Manual GraphQL queries | `SquidFilterBuilder` + codegen types | durt2 1.1.x | Use `getAccountHistoryFiltered()` with `TransactionFilters`, not raw GraphQL |
| `showDatePicker()` single date | `showCalendarDatePicker2Dialog()` range | Decision D-01 | The existing filter sheet uses `showDatePicker()` for single dates; market analysis needs range picker |

**Deprecated/outdated:**
- Ginkgo uses `getHistoryAndBalance()` with `from`/`to` Unix timestamps -- this API is from the v1 Duniter stack. Gecko uses durt2's `getAccountHistoryFiltered()` with `TransactionFilters` which is the v2 equivalent.

## Open Questions

1. **How does `getAccountHistoryFiltered` handle the `addresses` filter combined with the account address?**
   - What we know: `SquidFilterBuilder.buildAccountTransferFilter()` creates an OR filter for `fromId`/`toId` matching the wallet address, then ANDs with additional filters.
   - What's unclear: Does the `addresses` filter in `TransactionFilters` create an additional AND condition that effectively filters transactions to only those involving both the wallet AND the specified address? This is the expected behavior.
   - Recommendation: Verify by reading `SquidFilterBuilder._buildTransferFilters()` during implementation. If `addresses` doesn't filter correctly for bilateral transactions, construct the filter manually using `fromAddress`/`toAddress` fields instead.

2. **Name resolution for "other contacts" addresses**
   - What we know: `squidServiceProvider.walletNameIndexer` caches known names. `SquidService.client.getIdentityName()` can look up individual addresses.
   - What's unclear: Whether bulk name resolution is efficient for many discovered addresses (could be 10-50+ unique addresses).
   - Recommendation: Batch resolve in groups, or resolve lazily as the UI renders. Show short pubkey as fallback while names load.

## Sources

### Primary (HIGH confidence)
- `/Users/poka/dev/gecko/lib/providers/server_filtered_history_provider.dart` -- ServerFilteredHistoryNotifier pattern and SquidService usage
- `/Users/poka/dev/durt2/lib/src/services/squid/squid_account_queries.dart` -- getAccountHistoryFiltered() API and pagination
- `/Users/poka/dev/durt2/lib/src/models/transaction_filters.dart` -- TransactionFilters model and FilteredTransactionResult
- `/Users/poka/dev/gecko/lib/models/transaction_display_item.dart` -- TransactionDisplayItem with fromFilteredGraphQLNode()
- `/Users/poka/dev/gecko/lib/services/contact_service.dart` -- ContactService and allContactsProvider
- `/Users/poka/dev/gecko/lib/routes.dart` -- Route registration pattern (RouteNames, AppRoutes, RouteArguments)
- `/Users/poka/dev/gecko/lib/widgets/balance_display.dart` -- BalanceDisplay widget for currency formatting
- `/Users/poka/dev/ginkgo/lib/ui/widgets/market_analysis/market_analysis_page.dart` -- Ginkgo reference implementation (flow, date picker, contact processing)
- `/Users/poka/dev/ginkgo/lib/ui/widgets/market_analysis/simple_txs_panel.dart` -- Ginkgo per-contact aggregation and markdown

### Secondary (MEDIUM confidence)
- [calendar_date_picker2 pub.dev](https://pub.dev/packages/calendar_date_picker2) -- v2.0.1 version, API documentation

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all libraries already in project or verified on pub.dev; `calendar_date_picker2` confirmed compatible with SDK 3.8.1
- Architecture: HIGH -- patterns directly derived from existing codebase (ServerFilteredHistoryNotifier, routes.dart, wallet_options.dart) and verified Ginkgo reference
- Pitfalls: HIGH -- identified from code reading of actual query layer, pagination mechanics, and UTC handling in existing filter code

**Research date:** 2026-03-25
**Valid until:** 2026-04-25 (stable domain, no fast-moving dependencies)
