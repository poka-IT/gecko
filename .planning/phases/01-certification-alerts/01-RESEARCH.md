# Phase 1: Certification Alerts - Research

**Researched:** 2026-03-25
**Domain:** Flutter/Riverpod UI feature -- certification expiration indicators on home screen and contacts
**Confidence:** HIGH

## Summary

This phase adds visual alert indicators (colored dots) to wallet tiles on the home screen and contact entries, showing when certifications are expired or expiring soon. The existing codebase already contains the complete data layer (`CertificationListNotifier` with `expireDate` per cert), the expiration display logic (`CertTile._buildExpirationDisplay()` with 4-tier color thresholds), and the reactive subscription infrastructure (`hybridCertificationProvider` + Squid cert activity subscriptions). The work is purely about (1) creating a new Riverpod provider that aggregates cert expiration status into a simple enum per address, and (2) adding small dot indicator widgets to two UI surfaces.

The risk profile is low. No new data fetching, no new subscriptions, no new dependencies. The pattern for expiration thresholds is already established in `CertTile`, and the pattern for alert cards with threshold logic is established in `MembershipAlertCard`. The Riverpod family provider pattern is well-established throughout the codebase.

**Primary recommendation:** Create a `certAlertStatusProvider` (FutureProvider.family) that watches `certificationListProvider` for the relevant direction and computes worst-status from cert expiration dates, then consume it from `WalletTileMembre` (received certs) and contact list widgets (sent certs) to render a small colored dot overlay.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Use a small colored dot indicator overlaid on the medal icon (`assets/medal.png`) in `WalletTileMembre`. Red dot for expired certs, orange/warning dot for expiring-soon certs. No count -- just worst-status color.
- **D-02:** The dot should be subtle but visible -- similar to notification badge patterns on mobile (small circle, positioned top-right of the medal icon).
- **D-03:** Use the same thresholds as `CertTile._buildExpirationDisplay()`: expired (past date), expiring-soon (<=30 days), moderate (<=90 days). The home/contact indicators trigger on expired and <=30 days only (the most actionable states).
- **D-04:** Show worst-status indicator only (not counts). If any received cert is expired -> red dot. If none expired but some expiring-soon -> orange dot. Otherwise no indicator.
- **D-05:** On contact entries, show alert when the user's SENT certification to that contact is expiring or expired (the user can take action to renew).
- **D-06:** The existing `CertTile._buildExpirationDisplay()` already implements CERT-01 (colored badges with countdown in the cert list). Verify it covers all cases and adjust if needed, but no major new work expected here.
- **D-07:** Alert indicators must react to real-time cert changes via existing `CertificationListNotifier` subscriptions and `hybridCertificationProvider`. No manual refresh needed.

### Claude's Discretion
- Provider architecture for the new alert status computation (how to aggregate cert expiration data into a simple alert status enum)
- Exact positioning and sizing of the dot indicator on the medal icon
- Whether to add the alert to `Certifications` widget or create a separate alert widget

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CERT-01 | Alertes de certification dans la liste des certifications (icones expiree/bientot expiree) | Already implemented in `CertTile._buildExpirationDisplay()` (lines 138-223 of cert_tile.dart). Four-tier color coding: expired (red), <=30 days (orange/warning), <=90 days (amber), >90 days (green). Verify completeness only. |
| CERT-02 | Indicateur d'alerte certification visible depuis l'accueil et les contacts | Requires new `certAlertStatusProvider` + dot indicator widget in `WalletTileMembre` and contact list widgets. All data already available via `certificationListProvider`. |
</phase_requirements>

## Architecture Patterns

### Recommended New File Structure
```
lib/
  providers/
    cert_alert_provider.dart          # New: CertAlertStatus enum + certAlertStatusProvider
  widgets/
    cert_alert_dot.dart               # New: Small dot indicator widget
```

### Pattern 1: Alert Status Provider (FutureProvider.family)

**What:** A derived provider that watches `certificationListProvider` and computes an aggregated alert status enum from the cert list's expiration dates.

**When to use:** Whenever a UI surface needs to know "does this address have cert alerts?" without caring about individual cert details.

**Design:**

```dart
/// Alert status for certification health of a given address + direction.
enum CertAlertStatus {
  /// No alerts -- all certs are healthy (>30 days or no certs).
  none,
  /// At least one cert is expiring within 30 days, but none are expired.
  expiringSoon,
  /// At least one cert is expired.
  expired,
}

/// Computes worst-case cert alert status for an address.
///
/// For home wallet tiles: use CertDirection.received (received certs expiring).
/// For contact entries: use CertDirection.sent (sent certs needing renewal).
final certAlertStatusProvider = Provider.family<CertAlertStatus,
    ({String address, CertDirection direction})>((ref, params) {
  final certState = ref.watch(
    certificationListProvider((address: params.address, direction: params.direction)),
  );

  if (certState.isLoading || certState.certifications.isEmpty) {
    return CertAlertStatus.none;
  }

  final now = DateTime.now();
  bool hasExpired = false;
  bool hasExpiringSoon = false;

  for (final cert in certState.certifications) {
    if (cert.expireDate == null) continue;
    if (now.isAfter(cert.expireDate!)) {
      hasExpired = true;
      break; // Worst status found, no need to continue
    }
    if (cert.expireDate!.difference(now).inDays <= 30) {
      hasExpiringSoon = true;
    }
  }

  if (hasExpired) return CertAlertStatus.expired;
  if (hasExpiringSoon) return CertAlertStatus.expiringSoon;
  return CertAlertStatus.none;
});
```

**Key design choices:**
- Uses synchronous `Provider.family` (not `FutureProvider`) because `certificationListProvider` is a `NotifierProvider` that already manages its own async loading. The provider reads `CertificationListState` synchronously.
- Returns `CertAlertStatus.none` during loading or when no certs exist -- the dot simply won't show.
- Short-circuits on `expired` since it's the worst status (no need to check remaining certs).

### Pattern 2: Dot Indicator Widget

**What:** A small colored circle widget positioned as an overlay on the medal icon.

**When to use:** On `WalletTileMembre` (overlay on the medal `Image.asset`) and contact list entries (inline indicator).

**Design:**

```dart
class CertAlertDot extends ConsumerWidget {
  const CertAlertDot({
    super.key,
    required this.address,
    required this.direction,
    this.size = 10,
  });

  final String address;
  final CertDirection direction;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertStatus = ref.watch(
      certAlertStatusProvider((address: address, direction: direction)),
    );

    if (alertStatus == CertAlertStatus.none) {
      return const SizedBox.shrink();
    }

    final color = alertStatus == CertAlertStatus.expired
        ? context.geckoColors.danger
        : context.geckoColors.warning;

    return Container(
      width: scaleSize(size),
      height: scaleSize(size),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }
}
```

### Pattern 3: Integration into WalletTileMembre (Home Screen)

**What:** Wrap the medal icon in a `Stack` to overlay the dot.

**Where:** `lib/widgets/wallet_tile_membre.dart`, lines 86-94 (the `Positioned` widget containing the medal image).

**Current code:**
```dart
Positioned(
  left: scaleSize(16),
  top: scaleSize(16),
  child: Image.asset(
    'assets/medal.png',
    color: context.colorScheme.primary.withValues(alpha: 0.8),
    height: scaleSize(28),
  ),
),
```

**Modified to:**
```dart
Positioned(
  left: scaleSize(16),
  top: scaleSize(16),
  child: Stack(
    clipBehavior: Clip.none,
    children: [
      Image.asset(
        'assets/medal.png',
        color: context.colorScheme.primary.withValues(alpha: 0.8),
        height: scaleSize(28),
      ),
      Positioned(
        right: -scaleSize(3),
        top: -scaleSize(3),
        child: CertAlertDot(
          address: freshWallet.address,
          direction: CertDirection.received,
        ),
      ),
    ],
  ),
),
```

### Pattern 4: Integration into Contact Lists

**Where:** Two surfaces need modification:
1. `lib/widgets/contacts_list.dart` -- mobile contacts `ListTile`
2. `lib/widgets/desktop/panels/contacts_panel.dart` -- desktop `_buildContactTile()`

**Approach for contacts:** The alert is about the user's SENT certification to each contact. This requires knowing which wallet(s) the user owns. The simplest approach: for each contact address, check `certAlertStatusProvider` with `CertDirection.sent` from the user's primary wallet address.

**Challenge:** The current contact list receives `G1WalletsList` items. To compute sent cert alerts, we need the *current user's* address (the issuer). The provider needs to be parameterized with BOTH the user's address and the contact's address, OR the provider can be designed to check sent certs from all owned wallets.

**Recommended approach:** Create a higher-level provider that takes the contact address and internally looks up the user's owned wallet addresses to find any sent cert that's expiring/expired.

```dart
/// For contacts: checks if the current user has sent any cert to [contactAddress]
/// that is expired or expiring soon, across all owned wallets.
final contactCertAlertProvider = Provider.family<CertAlertStatus, String>((ref, contactAddress) {
  final wallets = ref.watch(walletsListProvider).wallets;

  CertAlertStatus worstStatus = CertAlertStatus.none;

  for (final wallet in wallets) {
    final certState = ref.watch(
      certificationListProvider((address: wallet.address, direction: CertDirection.sent)),
    );

    if (certState.isLoading || certState.certifications.isEmpty) continue;

    final now = DateTime.now();
    for (final cert in certState.certifications) {
      if (cert.address != contactAddress) continue;
      if (cert.expireDate == null) continue;

      if (now.isAfter(cert.expireDate!)) return CertAlertStatus.expired;
      if (cert.expireDate!.difference(now).inDays <= 30) {
        worstStatus = CertAlertStatus.expiringSoon;
      }
    }
  }

  return worstStatus;
});
```

**Placement in contact tiles:** Add `CertAlertDot` or equivalent inline icon next to the contact's name or balance area. Since contact tiles are simpler than wallet tiles, a small icon or dot before/after the contact name works well.

### Anti-Patterns to Avoid
- **Creating new subscriptions or data fetching:** All cert data with `expireDate` already flows through `CertificationListNotifier`. Do NOT create new Squid queries or WebSocket subscriptions for alert status.
- **Polling/timers for threshold updates:** The thresholds (30 days, expired) change slowly. The provider re-evaluates when cert data changes via existing subscriptions. No timer needed. If a cert crosses the 30-day boundary while the app is open (extremely rare), the next cert activity refresh or app restart will catch it.
- **Showing alerts on non-member wallets:** `WalletTileMembre` is already only used for member wallets, so this is automatically scoped correctly.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cert expiration thresholds | Custom threshold constants | Reuse the same logic as `CertTile._buildExpirationDisplay()` | Consistency -- single source of truth for 30-day and expired thresholds |
| Color semantics | Hardcoded color values | `context.geckoColors.danger` / `.warning` | Theme-aware, dark mode compatible |
| Responsive sizing | Raw pixel values | `scaleSize()` / `scaledTextStyle()` from `scale_functions.dart` | Consistent scaling across screen sizes |
| Cert data fetching | New API calls | `certificationListProvider` | Already fetches, caches, and subscribes to cert data with `expireDate` |

**Key insight:** This feature is purely derived computation + UI overlay. Zero new data infrastructure needed.

## Common Pitfalls

### Pitfall 1: CertificationListProvider Not Yet Loaded
**What goes wrong:** The `certificationListProvider` starts with `isLoading: true` and no certifications. If the alert provider reads during this state, it incorrectly shows "no alerts."
**Why it happens:** Provider initialization is async. Cert data fetches from Squid indexer.
**How to avoid:** Return `CertAlertStatus.none` during loading -- this is correct behavior since showing "no alert" during load is better than showing a stale/incorrect alert. The dot will appear once data loads.
**Warning signs:** Dot flickers on/off during navigation.

### Pitfall 2: Contact Cert Alert Requires Matching by Address
**What goes wrong:** `certificationListProvider` returns `CertDisplayItem` with an `address` field representing the other party (issuer for received, receiver for sent). For the contact alert, we need to find the cert where `cert.address == contactAddress` within the sent cert list.
**Why it happens:** The cert list data model stores the "other party" address, not the cert relationship's full issuer+receiver pair.
**How to avoid:** Filter the sent cert list by `cert.address == contactAddress` to find the specific cert to that contact.
**Warning signs:** Alert dot appears on wrong contacts or all contacts.

### Pitfall 3: Multiple Owned Wallets
**What goes wrong:** User may have multiple wallets in the same safe. A sent cert might come from any of them.
**Why it happens:** Gecko supports multiple wallets per safe (mnemonic derivation).
**How to avoid:** The `contactCertAlertProvider` iterates all owned wallets to find sent certs to the contact address.
**Warning signs:** Missing alerts for certs sent from non-primary wallets.

### Pitfall 4: Offline Mode / Squid Unavailable
**What goes wrong:** When squid is disconnected, `certificationListProvider` returns empty or cached stale data.
**Why it happens:** Cert data comes from the Squid indexer.
**How to avoid:** The provider already handles this -- `CertificationListNotifier` checks `squidConnectionStatusProvider` and sets error state when offline. The alert provider treats loading/error/empty the same: `CertAlertStatus.none`. Persisted state (SQLite cache) will provide cached data for the alert to work with.
**Warning signs:** None expected -- graceful degradation is already built in.

### Pitfall 5: Performance with Many Contacts
**What goes wrong:** If the user has 50+ contacts, creating `certificationListProvider` subscriptions for each contact's sent certs could be expensive.
**Why it happens:** Each `certificationListProvider` instance creates a Squid subscription.
**How to avoid:** The contact cert alert only needs to check the user's OWN sent cert lists (one per owned wallet), not one per contact. The sent cert list for each owned wallet is already loaded (one list per wallet, not per contact). The filtering by contact address is a simple in-memory operation on the already-loaded list.
**Warning signs:** App slowdown when opening contacts screen with many contacts.

## Code Examples

### Existing Threshold Logic (Source of Truth)
```dart
// From lib/widgets/cert_tile.dart, _buildExpirationDisplay()
final now = DateTime.now();
final daysUntilExpiration = cert.expireDate!.difference(now).inDays;
final isExpired = now.isAfter(cert.expireDate!);

if (isExpired) {
  // Red -- expired
} else if (daysUntilExpiration <= 30) {
  // Orange/warning -- expiring soon
} else if (daysUntilExpiration <= 90) {
  // Amber -- moderate
} else {
  // Green -- healthy
}
```

### Existing Semantic Colors Usage
```dart
// From various widgets
context.geckoColors.danger    // Red for expired/error
context.geckoColors.warning   // Orange for expiring-soon/caution
context.geckoColors.success   // Green for healthy
```

### Existing Medal Icon in WalletTileMembre
```dart
// From lib/widgets/wallet_tile_membre.dart, line 86-94
Positioned(
  left: scaleSize(16),
  top: scaleSize(16),
  child: Image.asset(
    'assets/medal.png',
    color: context.colorScheme.primary.withValues(alpha: 0.8),
    height: scaleSize(28),
  ),
),
```

### Ginkgo Reference Pattern (Simpler Approach)
```dart
// From ../ginkgo/lib/ui/widgets/certifications_page.dart
// Ginkgo uses emoji prefixes and icon color changes:
final bool isExpired = cert.expireOn <= currentBlockHeight;
final bool isExpiringSoon = cert.isActive && (cert.expireOn - currentBlockHeight < limit);
// Icon: timelapse (orange) for expiring, check_circle (green) for ok, warning (red) for expired
```

### Riverpod Family Provider Pattern (Codebase Convention)
```dart
// Established pattern from certification_list_providers.dart
final certificationListProvider =
    NotifierProvider.family<
      CertificationListNotifier,
      CertificationListState,
      ({String address, CertDirection direction})
    >((params) => CertificationListNotifier(params));

// Usage:
ref.watch(certificationListProvider((address: addr, direction: CertDirection.received)));
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Timer.periodic polling | Squid subscription + cert activity stream | Already in codebase | Real-time updates without polling |
| ChangeNotifier providers | Riverpod NotifierProvider | Ongoing migration | New code must use Riverpod |
| Hardcoded colors | GeckoColors ThemeExtension | Already in codebase | Use `context.geckoColors.*` for all semantic colors |

## Project Constraints (from CLAUDE.md)

- **Never use codegen** (`@riverpod` syntax) -- write providers manually
- Separate business logic into `lib/services/`, state management in `lib/providers/`
- Prefer `AsyncNotifier` for async state, `FutureProvider` for cached async data
- Document providers in English with `///`
- New code uses `flutter_riverpod` with `ConsumerWidget`/`ConsumerStatefulWidget`
- Never use plain `Text` widget for translation strings that contain markdown
- Use `scaleSize()` / `scaledTextStyle()` for responsive sizing
- Do NOT run `flutter build`, `flutter run`, or any Flutter compilation command
- `flutter analyze` and `dart format .` are allowed for lint/format checks

## Open Questions

1. **Contact alert: which user wallet to check?**
   - What we know: User may own multiple wallets. Sent certs come from specific wallets.
   - What's unclear: Should we check ALL owned wallets' sent certs, or only the "primary" wallet?
   - Recommendation: Check all owned wallets -- iterate `walletsListProvider.wallets` and check each one's sent cert list. This is the correct behavior since a user might certify a contact from any wallet.

2. **Cert alert dot on the Certifications widget vs medal icon?**
   - What we know: D-01/D-02 specify overlaying on the medal icon in `WalletTileMembre`.
   - What's unclear: The `Certifications` widget (showing "medal 5 (3)") also contains a medal icon in the bottom bar. Should it also get a dot?
   - Recommendation: Only add the dot to the large medal icon in the top-left corner per D-01/D-02. The small medal in the Certifications widget row is too small for a readable dot and would clutter the count display.

## Sources

### Primary (HIGH confidence)
- Direct source code analysis of all canonical reference files listed in CONTEXT.md
- `lib/providers/certification_list_providers.dart` -- CertificationListNotifier data model with `expireDate`
- `lib/widgets/cert_tile.dart` -- `_buildExpirationDisplay()` threshold logic
- `lib/widgets/wallet_tile_membre.dart` -- Medal icon Positioned layout
- `lib/widgets/certifications.dart` -- Certifications widget with `hybridCertificationProvider`
- `lib/providers/stream_providers.dart` -- HybridCertificationNotifier subscription architecture
- `lib/widgets/contacts_list.dart` -- Mobile contact tile structure
- `lib/widgets/desktop/panels/contacts_panel.dart` -- Desktop contact tile structure
- `lib/providers/gecko_colors.dart` -- Semantic color tokens
- `lib/providers/wallets_provider.dart` -- `isOwnerProvider` and `walletsListProvider`
- `../ginkgo/lib/ui/widgets/certifications_page.dart` -- Reference implementation from Ginkgo

### Secondary (MEDIUM confidence)
- `lib/widgets/membership_alert_card.dart` -- Alert card pattern with threshold logic (verified in source)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- no new dependencies, all existing Flutter/Riverpod patterns
- Architecture: HIGH -- provider pattern well-established, source code fully analyzed
- Pitfalls: HIGH -- identified from direct code analysis and data model understanding

**Research date:** 2026-03-25
**Valid until:** 2026-04-25 (stable -- no moving parts, all internal code)
