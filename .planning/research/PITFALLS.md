# Domain Pitfalls

**Domain:** Certification alerts + market analysis for Duniter v2s wallet
**Researched:** 2026-03-25

## Critical Pitfalls

Mistakes that cause rewrites or major issues.

### Pitfall 1: Block Height vs DateTime Confusion for Cert Expiration

**What goes wrong:** Using raw block heights for expiration calculations in UI code instead of converting to DateTime first. Block heights are chain-specific (6 seconds per block on Duniter) and depend on genesis time, which varies between networks (gdev, gtest, g1).

**Why it happens:** Ginkgo's `CertificationsPage` uses raw block arithmetic (`cert.expireOn - currentBlockHeight < limit` where `limit = 201600`). Copying this approach into Gecko would be wrong because Gecko already converts to DateTime.

**Consequences:** Wrong expiration times when switching networks. Inconsistent display between cert list (which already uses DateTime) and new alert providers.

**Prevention:** Gecko's `CertificationListNotifier._fetchCertifications()` already converts `expireOn` to `expireDate` via `Durt.i.storage.blocNumberToDate(cert.expireOn, genesisTime)`. The new alert provider MUST consume `CertDisplayItem.expireDate` (DateTime), never raw block heights. This is already the pattern in `CertTile._buildExpirationDisplay()`.

**Detection:** If you see `blockHeight` or `expireOn` (int) in any new alert or UI code, it is wrong. All expiration logic should use `DateTime` comparisons.

### Pitfall 2: Overwhelming Squid Indexer with Parallel Market Analysis Queries

**What goes wrong:** Launching all contact history queries in parallel (e.g., `Future.wait` for 10+ contacts) causes the Squid indexer to reject or timeout requests.

**Why it happens:** Natural instinct to parallelize for speed. Ginkgo explicitly avoids this with `_delay = Duration(milliseconds: 300)` between contacts.

**Consequences:** Failed queries, incomplete results, bad UX with error states, potential indexer rate limiting.

**Prevention:** Process contacts sequentially with 200-300ms delay between requests, exactly as Ginkgo does. Update UI progressively as each contact's results arrive. This also provides better UX (user sees progress).

**Detection:** If `Future.wait` or `Stream.fromIterable().asyncMap` appears in market analysis code for multiple contacts, it is likely wrong.

### Pitfall 3: Stale Cert Alert State After Network Reconnection

**What goes wrong:** Cert alert badges show outdated data after the app reconnects to the network, because the derived alert provider doesn't re-evaluate when the underlying cert list refreshes.

**Why it happens:** If the alert provider uses `.read()` instead of `.watch()` on the cert list, it won't react to updates. Or if the cert list provider doesn't invalidate on reconnection.

**Consequences:** Users see stale alerts (e.g., "2 expiring soon" when they've already renewed). Erodes trust in the alert system.

**Prevention:** The alert provider MUST use `ref.watch(certificationListProvider(...))` not `ref.read()`. Gecko's existing `certificationListProvider` already subscribes to cert activity changes and refreshes automatically. The derived alert provider inherits this reactivity through `watch`.

**Detection:** If the cert alert state does not update within a few seconds of a certification being renewed on-chain, this pitfall has been hit.

## Moderate Pitfalls

### Pitfall 4: Market Analysis Not Handling Pagination

**What goes wrong:** `getAccountHistoryFiltered` returns paginated results (default 20 items). If a contact has 100+ transactions in the selected period, only the first page is analyzed.

**Prevention:** The market analysis fetch loop must paginate until `hasNextPage` is false. Ginkgo uses `pageSize: 40` and does not paginate further, which means it misses transactions for active accounts. Gecko should do better: loop with cursor pagination until all transactions are fetched.

### Pitfall 5: Missing Currency Conversion in Market Analysis Totals

**What goes wrong:** Displaying raw amounts (in centimes, i.e., the blockchain's native unit) instead of human-readable amounts. Or forgetting to support UD (Unite de Dividende) display mode.

**Prevention:** Gecko has `settingsProvider` with `universalDividendsToggleProvider` for UD mode. Market analysis totals must use the same formatting functions already used in `TransactionTile`. The `intl` package's `NumberFormat` with locale support is already wired up.

### Pitfall 6: "Other Contacts" Discovery Creating Infinite Loops

**What goes wrong:** When discovering counterparty addresses from initial contacts' transactions, those "other contacts" might have transactions with yet more contacts, creating unbounded recursion.

**Prevention:** Ginkgo limits "other contacts" to one level: initial contacts are fetched with `collectOtherContacts: true`, but discovered contacts are fetched with `collectOtherContacts: false`. This is the correct approach. Never recurse more than one level.

### Pitfall 7: Alert Provider Watching Too Many Cert Lists

**What goes wrong:** The home screen alert aggregation provider watches cert lists for all owned wallets. If the user has 10+ wallets, this creates 10+ concurrent Squid subscriptions.

**Prevention:** Only compute alerts for wallets that have an identity (are members or pending members). Simple wallets without identity cannot have certifications. Check `IdtyStatus != none` before subscribing to cert data.

## Minor Pitfalls

### Pitfall 8: Date Range Off-by-One Errors

**What goes wrong:** The end date of the range excludes the last day's transactions because `endDate` is set to midnight (00:00:00) instead of end-of-day (23:59:59).

**Prevention:** When the user selects an end date, set it to the end of that day: `endDate.add(Duration(hours: 23, minutes: 59, seconds: 59))`. Or use `DateTime(endDate.year, endDate.month, endDate.day + 1)` for exclusive upper bound. Ginkgo handles this: if endDate is today, it uses `DateTime.now()` instead of midnight.

### Pitfall 9: Missing Locale Support in Date/Time Formatting

**What goes wrong:** Date formatting in market analysis uses hardcoded locale instead of the user's selected locale.

**Prevention:** Use Gecko's existing `safeLocale(Localizations.localeOf(context).languageCode)` pattern from `CertTile`. Use `DateFormat.yMMMd(locale)` not `DateFormat.yMMMd()`.

### Pitfall 10: Cert Alert Badge Flashing on App Start

**What goes wrong:** On app launch, cert data is loading (AsyncLoading), so the alert provider returns "no alerts". Then data arrives and the badge appears, causing a visible flash.

**Prevention:** Gecko's `certificationListProvider` already uses `persist()` to cache cert data in SQLite. On restart, cached data is available immediately before the network fetch. The alert provider should gracefully handle the `isLoading` state and show the last known alert state rather than "no alerts".

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Cert alert providers | Pitfall 1 (block height confusion), Pitfall 3 (stale state) | Always use DateTime from existing CertDisplayItem.expireDate; always use ref.watch |
| Cert alert UI on home screen | Pitfall 7 (too many subscriptions), Pitfall 10 (flash on start) | Filter to identity-holding wallets only; leverage persisted cache |
| Market analysis data fetching | Pitfall 2 (parallel queries), Pitfall 4 (missing pagination) | Sequential with delay; paginate until hasNextPage is false |
| Market analysis totals display | Pitfall 5 (currency conversion) | Reuse existing amount formatting functions |
| Market analysis "other contacts" | Pitfall 6 (infinite recursion) | One level only, matching Ginkgo's approach |
| Market analysis date picker | Pitfall 8 (off-by-one dates) | Set endDate to end-of-day or use exclusive upper bound |
| Localization | Pitfall 9 (missing locale) | Use Gecko's existing safeLocale pattern everywhere |

## Sources

- Ginkgo `CertificationsPage`: raw block height arithmetic pattern to avoid (line 24: `static const int limit = 201600`)
- Ginkgo `MarketAnalysisPage`: sequential processing with delay (line 109: `_delay = Duration(milliseconds: 300)`)
- Ginkgo `SimpleTransactionsPanel`: one-level "other contacts" discovery (line 106-112)
- Gecko `CertTile._buildExpirationDisplay()`: correct DateTime-based expiration pattern
- Gecko `CertificationListNotifier`: already converts block heights to DateTime via `blocNumberToDate()`
- Gecko `ServerFilteredHistoryNotifier`: pagination with cursor support already implemented
