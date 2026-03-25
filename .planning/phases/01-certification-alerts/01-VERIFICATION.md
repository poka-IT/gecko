---
phase: 01-certification-alerts
verified: 2026-03-25T10:00:00Z
status: passed
score: 9/9 must-haves verified
re_verification: false
---

# Phase 1: Certification Alerts Verification Report

**Phase Goal:** Users can see at a glance which certifications need attention (expired or expiring soon) without navigating to the certification detail screen
**Verified:** 2026-03-25T10:00:00Z
**Status:** passed
**Re-verification:** No -- initial verification

## Goal Achievement

### Observable Truths (from ROADMAP.md Success Criteria)

| #  | Truth                                                                                                   | Status     | Evidence                                                                                                             |
|----|---------------------------------------------------------------------------------------------------------|------------|----------------------------------------------------------------------------------------------------------------------|
| 1  | User viewing a cert list sees distinct icons/badges for expired certs and certs expiring within 30 days | ✓ VERIFIED | `cert_tile.dart` `_buildExpirationDisplay()` covers all 4 tiers + null fallback (lines 138-223)                     |
| 2  | User on home screen sees alert indicator on wallet tiles when received certs are expired/expiring soon  | ✓ VERIFIED | `wallet_tile_membre.dart` line 102: `CertAlertDot(address: freshWallet.address, direction: CertDirection.received)` |
| 3  | User browsing contacts sees alert indicator where sent certifications need renewal                      | ✓ VERIFIED | `contacts_list.dart` line 79 + `contacts_panel.dart` line 296 both watch `contactCertAlertProvider`                |
| 4  | Alert indicators update automatically when cert is renewed on-chain (no manual refresh)                 | ✓ VERIFIED | `certificationListProvider` has active Squid subscription (`subscribeCertActivity`); providers derive reactively    |

**Score:** 4/4 success criteria verified

### Plan-Level Truths (from must_haves frontmatter)

| #  | Truth                                                                                             | Status     | Evidence                                                                                    |
|----|---------------------------------------------------------------------------------------------------|------------|---------------------------------------------------------------------------------------------|
| 1  | `CertAlertStatus` enum has three values: none, expiringSoon, expired                             | ✓ VERIFIED | `cert_alert_provider.dart` lines 7-16                                                       |
| 2  | `certAlertStatusProvider` computes worst-status from cert expiration dates for address+direction  | ✓ VERIFIED | `cert_alert_provider.dart` lines 28-55; uses `inDays <= 30` threshold, short-circuits expired |
| 3  | `contactCertAlertProvider` checks sent certs across all owned wallets for a given contact address | ✓ VERIFIED | `cert_alert_provider.dart` lines 62-93; iterates `walletsState.wallets`, filters by `cert.address == contactAddress` |
| 4  | `CertAlertDot` renders colored circle or `SizedBox.shrink` for none                              | ✓ VERIFIED | `cert_alert_dot.dart` lines 33-51; `danger` for expired, `warning` for expiringSoon         |
| 5  | `CertTile._buildExpirationDisplay()` covers all 4 tiers + null fallback                          | ✓ VERIFIED | `cert_tile.dart`: null (line 140), expired red (line 157), <=30d orange (line 171), <=90d amber (line 189), >90d green (line 205) |

**Score:** 5/5 plan truths verified

**Overall Score:** 9/9 must-haves verified

### Required Artifacts

| Artifact                                             | Expected                                            | Status     | Details                                                   |
|------------------------------------------------------|-----------------------------------------------------|------------|-----------------------------------------------------------|
| `lib/providers/cert_alert_provider.dart`             | CertAlertStatus enum, certAlertStatusProvider, contactCertAlertProvider | ✓ VERIFIED | 93 lines, all three exports present, no stubs             |
| `lib/widgets/cert_alert_dot.dart`                    | CertAlertDot widget for overlay indicators          | ✓ VERIFIED | 53 lines, ConsumerWidget, colored dot or SizedBox.shrink  |
| `lib/widgets/wallet_tile_membre.dart`                | Medal icon with CertAlertDot overlay                | ✓ VERIFIED | Stack+Positioned wrapping medal, CertAlertDot wired       |
| `lib/widgets/contacts_list.dart`                     | Contact tiles with cert alert indicator             | ✓ VERIFIED | `_buildContactAlert` helper at line 78, contactCertAlertProvider wired |
| `lib/widgets/desktop/panels/contacts_panel.dart`     | Desktop contact tiles with cert alert indicator     | ✓ VERIFIED | Inline Builder at line 294-310, contactCertAlertProvider wired |

### Key Link Verification

| From                               | To                                | Via                                          | Status     | Details                                                            |
|------------------------------------|-----------------------------------|----------------------------------------------|------------|--------------------------------------------------------------------|
| `cert_alert_provider.dart`         | `certification_list_providers.dart` | `ref.watch(certificationListProvider(...))`  | ✓ WIRED    | Lines 32 and 73; named tuple params match provider signature       |
| `cert_alert_provider.dart`         | `wallets_provider.dart`           | `ref.watch(walletsListProvider)`             | ✓ WIRED    | Line 63; used to iterate all owned wallets                         |
| `cert_alert_dot.dart`              | `cert_alert_provider.dart`        | `ref.watch(certAlertStatusProvider(...))`    | ✓ WIRED    | Line 31; address+direction record param passed correctly           |
| `wallet_tile_membre.dart`          | `cert_alert_provider.dart`        | `CertAlertDot` with `CertDirection.received` | ✓ WIRED    | Line 102; uses `freshWallet.address` from live provider            |
| `contacts_list.dart`               | `cert_alert_provider.dart`        | `contactCertAlertProvider(contactAddress)`   | ✓ WIRED    | Line 79; `g1Wallet.address` passed, result rendered or hidden      |
| `contacts_panel.dart`              | `cert_alert_provider.dart`        | `contactCertAlertProvider(contact.address)`  | ✓ WIRED    | Line 296; inside Builder, result rendered or hidden                |

### Data-Flow Trace (Level 4)

| Artifact                          | Data Variable | Source                                  | Produces Real Data | Status     |
|-----------------------------------|--------------|-----------------------------------------|--------------------|------------|
| `cert_alert_provider.dart`        | `certState.certifications` | `certificationListProvider` (Squid subscription `subscribeCertActivity`) | Yes -- real on-chain data via Squid | ✓ FLOWING |
| `cert_alert_dot.dart`             | `status`     | `certAlertStatusProvider` (derived from above) | Yes -- computed from live cert data | ✓ FLOWING |
| `wallet_tile_membre.dart`         | `CertAlertDot` rendered state | `certAlertStatusProvider` via CertAlertDot | Yes | ✓ FLOWING |
| `contacts_list.dart`              | `alertStatus` | `contactCertAlertProvider` (iterates all wallets' sent certs) | Yes | ✓ FLOWING |
| `contacts_panel.dart`             | `alertStatus` | `contactCertAlertProvider` | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

Step 7b: SKIPPED -- Flutter UI code; cannot run UI without emulator. Visual verification requires human.

### Requirements Coverage

| Requirement | Source Plan | Description                                                              | Status       | Evidence                                                                      |
|-------------|------------|--------------------------------------------------------------------------|--------------|-------------------------------------------------------------------------------|
| CERT-01     | 01-01-PLAN | Alertes de certification dans la liste des certifications (icones expiree/bientot expiree) | ✓ SATISFIED  | `cert_tile.dart` `_buildExpirationDisplay()` covers 5 cases: null fallback, expired (red), <=30d (orange), <=90d (amber), >90d (green) |
| CERT-02     | 01-01-PLAN, 01-02-PLAN | Indicateur d'alerte certification visible depuis l'accueil et les contacts | ✓ SATISFIED  | `wallet_tile_membre.dart` (home medal overlay), `contacts_list.dart` (mobile), `contacts_panel.dart` (desktop) all wired and rendering |

No orphaned requirements: REQUIREMENTS.md maps only CERT-01 and CERT-02 to Phase 1. Both are claimed by plans and verified.

### Anti-Patterns Found

No anti-patterns found. Scanned all 5 phase files for TODO/FIXME, placeholder returns (`return null`, `return []`, `return {}`), empty handlers, and hardcoded empty data. All clear.

### Human Verification Required

#### 1. Visual appearance of cert alert dots

**Test:** Open the app on a device or emulator with at least one wallet that has received certifications. Navigate to the home screen and look at the member wallet tile medal icon.
**Expected:** A small red dot (expired) or orange dot (expiring within 30 days) appears at the top-right of the medal icon. No dot when all received certs are healthy (>30 days).
**Why human:** Cannot verify pixel rendering, color accuracy, or visual proportions without running the Flutter app.

#### 2. Contact list alert dots (mobile)

**Test:** Navigate to the contacts tab. Identify a contact for whom you have sent a certification that is expired or expiring soon.
**Expected:** A small colored dot appears next to the contact's balance in the trailing section. Contacts with healthy certs show no dot.
**Why human:** Requires live Squid data and visual inspection.

#### 3. Desktop contact panel alert dots

**Test:** Open the app on desktop. Inspect the left-column contacts panel for contacts with expiring sent certifications.
**Expected:** A small colored dot appears between the contact name column and balance for contacts needing cert renewal.
**Why human:** Requires desktop layout rendering and live data.

#### 4. Automatic update on cert renewal

**Test:** Renew a certification on-chain. Without manually refreshing, observe whether the alert dot disappears.
**Expected:** The dot disappears automatically within seconds of the Squid subscription receiving the update.
**Why human:** Requires on-chain transaction and real-time observation.

### Gaps Summary

No gaps. All automated checks passed:
- All 5 artifacts exist, are substantive (no stubs), and are wired
- All 6 key links verified
- Data flows from live Squid subscriptions through providers to UI
- Both requirements (CERT-01, CERT-02) satisfied with concrete code evidence
- All 4 ROADMAP success criteria verified
- Zero anti-patterns detected in any phase file
- All 4 task commits (64b6c229, 07c04a02, 58b06d9b, f9e260e2) confirmed in git log

The phase goal is achieved: users can see cert expiration status at a glance on the home screen and contact list without navigating to the cert detail screen.

---

_Verified: 2026-03-25T10:00:00Z_
_Verifier: Claude (gsd-verifier)_
