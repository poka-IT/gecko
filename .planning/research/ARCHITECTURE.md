# Architecture Patterns

**Domain:** Certification monitoring and market analysis for Duniter v2s wallet
**Researched:** 2026-03-25

## Recommended Architecture

Both features follow Gecko's established provider hierarchy pattern: data flows from `durt2` (blockchain/indexer) through Riverpod providers to ConsumerWidget UI. No architectural changes to the existing system are needed.

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| `CertExpirationAlertProvider` (new) | Derives alert level (none/warning/critical) from cert list expiration data | Watches `certificationListProvider`, reads `blockHeightProvider` |
| `HomeCertAlertProvider` (new) | Aggregates cert alerts across all owned wallets for home screen | Watches `certExpirationAlertProvider` for each wallet in `walletsListProvider` |
| `MarketAnalysisNotifier` (new) | Manages market analysis workflow: contacts, date range, fetch, aggregate | Uses `durt2.SquidService.client.getAccountHistoryFiltered()` directly |
| `MarketAnalysisResultProvider` (new) | Per-contact transaction summary with totals | Created by `MarketAnalysisNotifier`, consumes `TransactionDisplayItem` |
| Cert alert UI widgets (new) | Badge/icon overlays on wallet tiles and contact entries | Watches `certExpirationAlertProvider` or `homeCertAlertProvider` |
| Market analysis screen (new) | Full screen with date picker, contact selector, results list | Watches `MarketAnalysisNotifier`, uses `showDateRangePicker` |

### Data Flow

#### Certification Alerts

```
durt2 Squid GraphQL (getCertsReceived/getCertsSent)
  |
  v
CertificationListNotifier (existing, in certification_list_providers.dart)
  | already fetches expireDate via blocNumberToDate()
  | already subscribes to real-time cert activity
  v
CertExpirationAlertProvider (new, derived/computed)
  | watches cert list, computes: expired count, expiring-soon count, alert level
  v
HomeCertAlertProvider (new, aggregates across wallets)
  | watches all owned wallet cert alerts
  v
UI: Badge on WalletTileMembre, indicator on CertTile, alert on contacts
```

#### Market Analysis

```
User selects contacts + date range
  |
  v
MarketAnalysisNotifier.analyze()
  | for each contact:
  |   builds TransactionFilters(startDate, endDate, addresses: [contact])
  |   calls durt2 SquidService.client.getAccountHistoryFiltered(ownerAddress, filters)
  |   computes per-contact totals (received/sent amounts and counts)
  |   extracts counterparty addresses for "other contacts" discovery
  v
MarketAnalysisState
  | contactResults: List<ContactAnalysisResult>
  | aggregateTotals: (totalReceived, totalSent, totalReceivedCount, totalSentCount)
  | otherContacts: Set<String> (discovered counterparties)
  | markdownSummary: String
  v
UI: MarketAnalysisScreen
  | Date range button -> showDateRangePicker
  | Contact selector -> multi-select from contacts/favorites
  | Results list -> per-contact ExpansionTile with totals
  | Aggregate totals card at top
  | Copy markdown button
```

## Patterns to Follow

### Pattern 1: Derived Provider for Alert State

**What:** Use a simple `Provider` (not `AsyncNotifier`) that watches the existing async cert list provider and derives a synchronous alert state from it.

**When:** The cert list is already fetched and cached; the alert is a pure computation (no I/O).

**Why:** Avoids redundant network calls. The cert list provider already handles fetching, caching, subscriptions, and persistence. The alert provider just reads and computes.

**Example:**
```dart
/// Alert levels for certification expiration
enum CertAlertLevel { none, warning, critical }

/// Alert state derived from certification list
class CertExpirationAlert {
  final CertAlertLevel level;
  final int expiredCount;
  final int expiringSoonCount;
  final int totalActive;

  const CertExpirationAlert({
    this.level = CertAlertLevel.none,
    this.expiredCount = 0,
    this.expiringSoonCount = 0,
    this.totalActive = 0,
  });
}

/// Derives alert state from the existing cert list provider
final certExpirationAlertProvider = Provider.family<
  CertExpirationAlert,
  ({String address, CertDirection direction})
>((ref, params) {
  final certState = ref.watch(certificationListProvider(params));

  if (certState.isLoading || certState.certifications.isEmpty) {
    return const CertExpirationAlert();
  }

  final now = DateTime.now();
  int expired = 0;
  int expiringSoon = 0;

  for (final cert in certState.certifications) {
    if (cert.expireDate == null) continue;
    if (now.isAfter(cert.expireDate!)) {
      expired++;
    } else if (cert.expireDate!.difference(now).inDays <= 30) {
      expiringSoon++;
    }
  }

  final level = expired > 0
    ? CertAlertLevel.critical
    : expiringSoon > 0
      ? CertAlertLevel.warning
      : CertAlertLevel.none;

  return CertExpirationAlert(
    level: level,
    expiredCount: expired,
    expiringSoonCount: expiringSoon,
    totalActive: certState.certifications.length,
  );
});
```

### Pattern 2: Sequential Per-Contact Fetching with Progress

**What:** Process contacts one at a time with a delay between requests, updating UI progressively.

**When:** Market analysis fetches filtered history for multiple contacts. Parallel fetching would overwhelm the Squid indexer.

**Why:** Ginkgo uses exactly this pattern (`_delay = Duration(milliseconds: 300)` between contacts). It provides visual feedback as each contact's results appear and avoids rate limiting.

**Example:**
```dart
class MarketAnalysisNotifier extends Notifier<MarketAnalysisState> {
  Future<void> analyze() async {
    state = state.copyWith(isAnalyzing: true, processedCount: 0);

    for (final contact in state.selectedContacts) {
      final result = await _fetchContactTransactions(contact);
      state = state.addContactResult(result);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // Phase 2: discover and process "other contacts"
    if (state.otherContacts.isNotEmpty) {
      for (final otherContact in state.otherContacts) {
        final result = await _fetchContactTransactions(otherContact);
        state = state.addOtherContactResult(result);
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }

    state = state.copyWith(isAnalyzing: false, isComplete: true);
  }
}
```

### Pattern 3: Reuse Existing TransactionDisplayItem

**What:** Use `TransactionDisplayItem.fromFilteredGraphQLNode()` which already handles parsing the Squid GraphQL response into display-ready items.

**When:** Processing market analysis results from `getAccountHistoryFiltered`.

**Why:** Avoids duplicating parsing logic. The display item already computes signed amounts (positive for received, negative for sent), formats timestamps, extracts counterparty info.

## Anti-Patterns to Avoid

### Anti-Pattern 1: Separate Network Calls for Cert Expiration

**What:** Making additional Squid/Duniter calls specifically for expiration alerts.

**Why bad:** The `certificationListProvider` already fetches cert data including `expireOn` and converts it to `expireDate`. Making duplicate calls wastes bandwidth and creates race conditions.

**Instead:** Derive alert state from the existing cert list provider. Zero additional network cost.

### Anti-Pattern 2: Stateful Widget for Market Analysis State

**What:** Managing analysis state (contacts, date range, results, progress) in a `StatefulWidget` like Ginkgo does.

**Why bad:** Gecko uses Riverpod 3 throughout. Putting business logic in StatefulWidget breaks the established pattern, makes testing harder, and loses persistence/caching benefits.

**Instead:** Use a `Notifier<MarketAnalysisState>` that manages the full workflow. The widget just watches and displays.

### Anti-Pattern 3: Client-Side Date Filtering

**What:** Fetching all transactions and filtering by date in Dart code.

**Why bad:** The Squid indexer supports server-side date filtering via `TransactionFilters(startDate, endDate)`. Client-side filtering wastes bandwidth and memory, especially for accounts with large transaction histories.

**Instead:** Always use `getAccountHistoryFiltered` with server-side filters. Gecko already has this infrastructure wired up in `ServerFilteredHistoryNotifier`.

### Anti-Pattern 4: Polling for Cert Changes

**What:** Using `Timer.periodic` to poll for certification changes.

**Why bad:** Gecko already has WebSocket subscriptions via `subscribeCertActivity()` and block height listeners. Polling is wasteful and creates unnecessary load.

**Instead:** Use the existing real-time subscription infrastructure. The `CertificationListNotifier` already auto-refreshes on cert activity events.

## Scalability Considerations

| Concern | At 5 certs | At 50 certs | At 500 certs |
|---------|------------|-------------|--------------|
| Cert alert computation | Instant (loop over 5 items) | Instant (loop over 50 items) | Still instant; O(n) iteration is negligible |
| Market analysis contacts | Sequential fetch, ~1.5s total | Sequential fetch, ~15s total | Would need pagination/batching UI; unlikely scenario |
| GraphQL query size | Single small query per contact | 50 queries with 300ms delay = 15s | Would need query batching or parallel with throttle |

The realistic scenario for Duniter G1 is 5-20 certifications per identity and 2-10 contacts in market analysis. The sequential approach handles this well.

## Sources

- Gecko: `lib/providers/certification_list_providers.dart` (existing cert list with expireDate)
- Gecko: `lib/widgets/cert_tile.dart` (existing expiration display with color coding)
- Gecko: `lib/providers/server_filtered_history_provider.dart` (existing server-side filtered history)
- Gecko: `lib/providers/stream_providers.dart` (existing real-time cert subscriptions)
- Ginkgo: `lib/ui/widgets/certifications_page.dart` (cert expiration UI reference)
- Ginkgo: `lib/ui/widgets/market_analysis/market_analysis_page.dart` (market analysis flow reference)
- Ginkgo: `lib/ui/widgets/market_analysis/simple_txs_panel.dart` (per-contact fetch pattern)
