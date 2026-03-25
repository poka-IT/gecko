# Technology Stack

**Project:** Gecko v0.2 -- Certification Alerts + Market Analysis
**Researched:** 2026-03-25

## Recommended Stack

### No New Core Frameworks Needed

The existing Gecko stack already contains everything required for both features. The key insight from analyzing both Gecko's codebase and Ginkgo's reference implementation is that the infrastructure (durt2 Squid GraphQL queries, Riverpod providers, certification data with `expireOn`, server-side filtered history) is already in place. The work is assembling existing primitives into new UI and provider compositions.

### Core Framework (Already Present -- No Changes)

| Technology | Version | Purpose | Status |
|------------|---------|---------|--------|
| `flutter_riverpod` | ^3.2.1 | State management for new providers | Already installed |
| `durt2` | ^1.1.1 (local override) | Blockchain SDK: cert data, filtered history, Squid GraphQL | Already installed |
| `easy_localization` | ^3.0.8 | i18n for new UI strings | Already installed |
| `intl` | ^0.20.0 (override) | Date formatting (DateFormat.yMMMd, etc.) | Already installed |
| `timeago` | ^3.7.1 | Human-readable expiration countdowns | Already installed |

### New Package: Date Range Picker for Market Analysis

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **None -- use Flutter's built-in `showDateRangePicker`** | Flutter SDK | Date range selection for market analysis period | See rationale below |

**Rationale: Use `showDateRangePicker` instead of `calendar_date_picker2`.**

Ginkgo uses `calendar_date_picker2: ^2.0.1` for its market analysis date picker. Gecko should NOT follow this choice because:

1. **Gecko already uses `showDatePicker` in its transaction filters** (`lib/widgets/transaction_filters.dart`). Using the built-in Material `showDateRangePicker` maintains UI consistency with the existing filter system.
2. **Zero new dependencies.** `showDateRangePicker` is part of Flutter's Material library. Adding `calendar_date_picker2` would add an unnecessary third-party dependency for a widget that Flutter already provides natively.
3. **Material 3 compliance.** Flutter's built-in date range picker follows Material 3 design guidelines, which Gecko uses throughout.
4. **Gecko's transaction filters already have `DateRangeFilter` with `startDate`/`endDate` in `TransactionFilterCriteria`.** The infrastructure for passing date ranges to `durt2`'s `TransactionFilters` is already wired up via `ServerFilteredHistoryNotifier._convertToServerFilters()`.

**Confidence:** HIGH -- verified by reading both codebases.

### New Package: Share/Export for Market Analysis Results

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **None -- use Flutter's built-in `Clipboard`** | Flutter SDK | Copy markdown summary to clipboard | Already used throughout Gecko for address copying |

**Rationale: Clipboard copy instead of `share_plus`.**

The PROJECT.md requirement says "export/resume markdown des resultats". The simplest approach that matches Gecko's existing patterns:

1. **Clipboard copy** -- Gecko already uses `Clipboard.setData()` in 5+ places (wallet headers, drawer, QR screens). Generate a markdown string and copy to clipboard with a snackbar confirmation. No new dependency.
2. **`share_plus` is overkill** for this use case. The markdown output is text, not a file. Clipboard is the lightest path.
3. If true native sharing is needed later, `share_plus` (^10.x) can be added in a future iteration. But for MVP, clipboard suffices.

**Confidence:** MEDIUM -- the exact UX for "export" is not fully specified. Clipboard is the minimal viable approach. If platform share sheet is explicitly requested, `share_plus` would be added.

### Supporting Libraries (Already Present -- No Changes)

| Library | Version | Purpose | Used For |
|---------|---------|---------|----------|
| `markdown` | ^7.3.0 | Markdown string generation | Market analysis summary export |
| `flutter_markdown` | ^0.7.7+1 | Markdown rendering in UI | Displaying analysis results |
| `responsive_framework` | ^1.5.1 | Layout breakpoints | Market analysis responsive layout |
| `riverpod_sqflite` | ^0.4.2 | Riverpod persistence | Caching cert expiration state |

## durt2 APIs Already Available

These durt2 APIs are the foundation. No changes to durt2 are needed.

### For Certification Alerts

| API | Location | What It Provides |
|-----|----------|-----------------|
| `SquidService.client.getCertsReceived(address)` | squid_account_queries.dart | List of received certs with `expireOn` block height and `isActive` flag |
| `SquidService.client.getCertsSent(address)` | squid_account_queries.dart | List of sent certs with `expireOn` block height and `isActive` flag |
| `SquidService.client.subscribeCertActivity(address)` | squid subscriptions | Real-time cert change notifications |
| `Durt.i.storage.blocNumberToDate(expireOn, genesisTime)` | duniter_storage_service.dart | Convert block number to DateTime for expiration display |
| `storageService.blockHeightNotifier` | duniter_storage_service.dart | Current block height for expiration calculations |

### For Market Analysis

| API | Location | What It Provides |
|-----|----------|-----------------|
| `SquidService.client.getAccountHistoryFiltered(address, filters: TransactionFilters(...))` | squid_account_queries.dart | Server-side filtered transactions with date range, amount, direction |
| `TransactionFilters(startDate, endDate, fromAddress, toAddress, ...)` | transaction_filters.dart | Filter criteria model with full date range support |
| `SquidFilterBuilder.buildFilterFromCriteria(address, filters)` | squid_filter_builder.dart | Converts TransactionFilters to GraphQL Input$TransferFilter |

## Gecko Providers Already Available

### For Certification Alerts

| Provider | File | What It Does |
|----------|------|-------------|
| `certificationListProvider` | certification_list_providers.dart | Fetches cert list with `expireDate` (DateTime) via `blocNumberToDate()`. Already uses Squid GraphQL + real-time subscriptions. |
| `blockHeightProvider` | block_height_provider.dart | Current block height for expiration math |
| `genesisTimeProvider` | providers.dart | Genesis time for block-to-date conversion |
| `hybridCertificationProvider` | stream_providers.dart | Cert count (received/sent) with real-time updates |

### For Market Analysis

| Provider | File | What It Does |
|----------|------|-------------|
| `serverFilteredHistoryProvider` | server_filtered_history_provider.dart | Server-side filtered transaction history with pagination |
| `transactionFiltersProvider` | transaction_filters_provider.dart | Filter state management with date range, amount, address, comment |
| `transactionHistoryProvider` | transaction_history_providers.dart | Base transaction history with pagination |

## What Needs to Be Built (Providers, Not Packages)

### Certification Alert Providers (New)

```dart
// 1. Cert expiration status provider -- derives alert state from existing cert list
final certExpirationAlertProvider = Provider.family<CertExpirationAlert, ({String address, CertDirection direction})>((ref, params) {
  final certState = ref.watch(certificationListProvider(params));
  // Compute: how many expired, how many expiring soon (< 30 days)
  // Return: alert level (none/warning/critical) + counts
});

// 2. Aggregate alert for home screen badge -- watches all owned wallet certs
final homeCertAlertProvider = Provider<HomeCertAlert>((ref) {
  // For each owned wallet address, watch certExpirationAlertProvider
  // Return: worst alert level across all wallets + summary
});
```

### Market Analysis Providers (New)

```dart
// 1. Market analysis state -- manages selected contacts, date range, results
class MarketAnalysisNotifier extends Notifier<MarketAnalysisState> {
  // Uses existing durt2 TransactionFilters + getAccountHistoryFiltered
  // Per-contact: fetch filtered history, compute totals
  // Aggregate: sum across contacts, collect "other contacts"
}

// 2. Market analysis results -- per contact transaction summary
// Reuses TransactionDisplayItem.fromFilteredGraphQLNode() already in Gecko
```

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Date range picker | Flutter `showDateRangePicker` | `calendar_date_picker2` ^2.0.1 | Unnecessary dependency; Gecko already uses Material pickers; Ginkgo uses it but Gecko has different UI patterns |
| Sharing/export | `Clipboard.setData()` | `share_plus` ^10.x | Overkill for text-only markdown export; can add later if needed |
| Cert expiration time display | `timeago` ^3.7.1 (already installed) | Manual date diff formatting | `timeago` already used by Ginkgo for cert expiry, and already in Gecko's pubspec |
| Transaction aggregation | In-provider Dart computation | External analytics package | Aggregation is simple (sum amounts, count transactions); no library needed |
| Local notifications for cert expiry | Not recommended for MVP | `flutter_local_notifications` | Adds platform complexity; visual in-app alerts are sufficient first; can add later |

## Installation

```bash
# No new packages required.
# All dependencies are already in pubspec.yaml.
flutter pub get
```

If native sharing is later requested:
```bash
# Only if clipboard export proves insufficient
flutter pub add share_plus
```

## Confidence Assessment

| Decision | Confidence | Rationale |
|----------|------------|-----------|
| No new packages needed | HIGH | Verified by reading both codebases: all APIs exist in durt2, all UI primitives exist in Flutter SDK + Gecko's existing dependencies |
| `showDateRangePicker` over `calendar_date_picker2` | HIGH | Gecko already uses Material date pickers in transaction filters; consistency matters |
| Clipboard over `share_plus` | MEDIUM | "Export/resume markdown" could mean share sheet; clipboard is MVP; share_plus can be added later |
| `timeago` for cert expiry display | HIGH | Already in Gecko pubspec; Ginkgo uses it for same purpose; verified in code |
| No local notifications for cert alerts | MEDIUM | Visual alerts are the stated requirement; push notifications are a natural follow-up but not in scope |

## Sources

- Gecko codebase: `lib/providers/certification_list_providers.dart`, `lib/widgets/cert_tile.dart`, `lib/providers/server_filtered_history_provider.dart`, `lib/widgets/transaction_filters.dart`
- Ginkgo codebase: `lib/ui/widgets/certifications_page.dart`, `lib/ui/widgets/market_analysis/market_analysis_page.dart`, `lib/ui/widgets/market_analysis/simple_txs_panel.dart`, `lib/ui/ui_helpers.dart`
- durt2 codebase: `lib/src/models/transaction_filters.dart`, `lib/src/services/squid/squid_account_queries.dart`
- [Flutter showDateRangePicker API](https://api.flutter.dev/flutter/material/showDateRangePicker.html)
- [calendar_date_picker2 on pub.dev](https://pub.dev/packages/calendar_date_picker2)
- [share_plus on pub.dev](https://pub.dev/packages/share_plus)
- [Riverpod 3.0 what's new](https://riverpod.dev/docs/whats_new)
