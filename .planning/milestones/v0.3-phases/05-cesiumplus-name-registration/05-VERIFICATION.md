---
phase: 05-cesiumplus-name-registration
verified: 2026-03-31T12:00:00Z
status: gaps_found
score: 5/6 must-haves verified
re_verification: false
gaps:
  - truth: "When user renames a wallet to a custom (non-default) name, the name is published to the CesiumPlus pod as the profile title"
    status: failed
    reason: "csPublishStatusProvider uses StateProvider.family which does not exist in Riverpod 3.2.1 (removed in v3). dart analyze reports 'Undefined name StateProvider'. The provider will not compile, breaking the entire publish chain."
    artifacts:
      - path: "lib/providers/cs_publish_status_provider.dart"
        issue: "StateProvider is not available in Riverpod 3. Must be replaced with NotifierProvider.family + Notifier<CsPublishStatus> class."
      - path: "lib/services/wallet_management_service.dart"
        issue: "ref.read(csPublishStatusProvider(walletAddress).notifier).state = ... relies on StateProvider API which does not compile."
    missing:
      - "Replace StateProvider.family with NotifierProvider.family using a Notifier<CsPublishStatus> class (matching the project's existing pattern in certification_queue_provider.dart)"
  - truth: "If CesiumPlus upload fails, a retry indicator is visible on the wallet options screen"
    status: failed
    reason: "Retry indicator depends on csPublishStatusProvider compiling correctly. Since StateProvider is invalid in Riverpod 3, ref.watch(csPublishStatusProvider(address)) in wallet_options.dart will also fail to compile."
    artifacts:
      - path: "lib/screens/myWallets/wallet_options.dart"
        issue: "ref.watch(csPublishStatusProvider(widget.wallet.address)) depends on the broken csPublishStatusProvider."
    missing:
      - "Fix csPublishStatusProvider first; retry indicator wiring is otherwise correct."
human_verification:
  - test: "Rename a wallet to a custom name and verify the CesiumPlus publish succeeds end-to-end"
    expected: "Name appears on CesiumPlus pod; status goes idle -> publishing -> success"
    why_human: "Requires a live CesiumPlus pod and valid wallet credentials"
  - test: "Rename a wallet while offline and verify the retry indicator appears"
    expected: "Local rename succeeds immediately; cloud_off + refresh icon row appears below rename button"
    why_human: "Requires simulated network failure and visual verification of the retry row"
  - test: "Tap the retry indicator and verify it re-publishes on success"
    expected: "PIN prompt appears; on success, retry indicator disappears"
    why_human: "Requires interactive PIN input and live CesiumPlus pod"
---

# Phase 05: CesiumPlus Name Registration — Verification Report

**Phase Goal:** Users can make their wallet discoverable by publishing a custom name to CesiumPlus when they rename it
**Verified:** 2026-03-31
**Status:** GAPS FOUND
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #   | Truth                                                                                          | Status     | Evidence                                                                                     |
| --- | ---------------------------------------------------------------------------------------------- | ---------- | -------------------------------------------------------------------------------------------- |
| 1   | When user renames a wallet to a custom name, the name is published to CesiumPlus as the title | ✗ FAILED   | `StateProvider` undefined in Riverpod 3.2.1; `cs_publish_status_provider.dart` won't compile |
| 2   | The local rename always succeeds immediately regardless of CesiumPlus upload outcome           | ✓ VERIFIED | `unawaited()` call in wallet_options.dart:386; rename completed before publish is attempted  |
| 3   | Default wallet names (starting with #) are never published to CesiumPlus                      | ✓ VERIFIED | Guard at `wallet_options.dart:383` and `wallet_management_service.dart:237`                  |
| 4   | If CesiumPlus upload fails, a retry indicator is visible on the wallet options screen          | ✗ FAILED   | Retry widget exists but depends on broken `csPublishStatusProvider`                          |
| 5   | Tapping the retry indicator re-attempts the CesiumPlus publish after PIN verification         | ✓ VERIFIED | `wallet_options.dart:423-433`: PIN check + `unawaited(publishNameToCesiumPlus)` wired        |
| 6   | Existing profile data is preserved when updating the title                                     | ✓ VERIFIED | `publishNameToCesiumPlus` reads existing profile and forwards description/city/socials/tags   |

**Score:** 4/6 truths verified (2 blocked by Riverpod 3 API incompatibility)

Note: Truths 5 and 6 are logically correct in their code paths, but depend on the broken provider being fixed before they can function at runtime. They are marked VERIFIED for code structure, with truth 1 and 4 capturing the root cause.

### Required Artifacts

| Artifact                                          | Expected                                                     | Status       | Details                                                                                           |
| ------------------------------------------------- | ------------------------------------------------------------ | ------------ | ------------------------------------------------------------------------------------------------- |
| `lib/providers/cs_publish_status_provider.dart`   | CsPublishStatus enum + StateProvider.family                  | ✗ STUB       | File exists with correct intent but `StateProvider` is not defined in Riverpod 3.2.1             |
| `lib/services/wallet_management_service.dart`     | publishNameToCesiumPlus static method                        | ✓ VERIFIED   | Method at line 230; profile preservation, status updates, error handling all present             |
| `lib/screens/myWallets/wallet_options.dart`       | CesiumPlus publish call after rename + retry indicator widget | ⚠️ PARTIAL   | Wiring present (lines 383-393, 419-453) but broken by invalid provider API                       |

### Key Link Verification

| From                                          | To                                              | Via                                                     | Status      | Details                                                                              |
| --------------------------------------------- | ----------------------------------------------- | ------------------------------------------------------- | ----------- | ------------------------------------------------------------------------------------ |
| `wallet_options.dart`                         | `wallet_management_service.dart`                | `unawaited(WalletManagementService.publishNameToCesiumPlus(...))` | ✓ WIRED | Lines 386-391 and 428-433                                                         |
| `wallet_management_service.dart`              | `cesiumPlusService.uploadProfile`               | `cesiumPlusService.uploadProfile(title: name, ...)`     | ✓ WIRED     | Line 255; existing profile read first at line 253                                   |
| `wallet_management_service.dart`              | `cs_publish_status_provider.dart`               | `ref.read(csPublishStatusProvider(address).notifier).state` | ✗ BROKEN | `StateProvider` not defined in Riverpod 3; compile-time error                    |
| `wallet_options.dart`                         | `cs_publish_status_provider.dart`               | `ref.watch(csPublishStatusProvider(address))`           | ✗ BROKEN    | Depends on broken provider                                                           |

### Data-Flow Trace (Level 4)

| Artifact                                        | Data Variable         | Source                              | Produces Real Data | Status      |
| ----------------------------------------------- | --------------------- | ----------------------------------- | ------------------ | ----------- |
| `wallet_management_service.dart:publishName...` | `existing` (profile)  | `cesiumPlusService.getProfileByAddress` | Yes (live HTTP)  | ✓ FLOWING   |
| `wallet_management_service.dart:publishName...` | `success` (upload)    | `cesiumPlusService.uploadProfile`   | Yes (live HTTP)    | ✓ FLOWING   |
| `cs_publish_status_provider.dart`               | `CsPublishStatus`     | `StateProvider.family`              | N/A                | ✗ DISCONNECTED — API removed in Riverpod 3 |

### Behavioral Spot-Checks

Step 7b: SKIPPED — Flutter provider compilation requires full `flutter pub get` + build; cannot test provider resolution without running the app. The compile error is identified statically via `dart analyze`.

### Requirements Coverage

| Requirement | Source Plan | Description                                                                          | Status    | Evidence                                                                                                |
| ----------- | ----------- | ------------------------------------------------------------------------------------ | --------- | ------------------------------------------------------------------------------------------------------- |
| REG-01      | 05-01-PLAN  | Renaming a wallet (non-default name) publishes the name as CesiumPlus profile title  | ✗ BLOCKED | Publish method is written and wired; blocked by `StateProvider` compile error in provider file         |
| REG-02      | 05-01-PLAN  | Failed publish shows retry indicator; local rename always succeeds                   | ✗ BLOCKED | Retry indicator UI is written; blocked by same `StateProvider` compile error                           |

No orphaned requirements — REQUIREMENTS.md traceability table maps exactly REG-01 and REG-02 to Phase 5, matching the PLAN frontmatter.

### Anti-Patterns Found

| File                                         | Line | Pattern                                                                    | Severity    | Impact                                                                               |
| -------------------------------------------- | ---- | -------------------------------------------------------------------------- | ----------- | ------------------------------------------------------------------------------------ |
| `lib/providers/cs_publish_status_provider.dart` | 8  | `StateProvider.family` — removed in Riverpod 3.2.1                        | BLOCKER     | Provider won't compile; entire phase feature non-functional at runtime               |
| `assets/translations/en.json`               | 627-628 | `namePublished`, `namePublishFailed` keys defined but never called in code | WARNING     | Dead translation keys; no snackbar feedback shown to user on publish success/failure |
| `assets/translations/fr.json`               | 703-704 | Same dead keys                                                             | WARNING     | Same                                                                                 |
| `assets/translations/es.json`               | 631-632 | Same dead keys                                                             | WARNING     | Same                                                                                 |
| `assets/translations/it.json`               | 632-633 | Same dead keys                                                             | WARNING     | Same                                                                                 |

Notes:
- `use_build_context_synchronously` at `wallet_options.dart:384` is an existing pattern in the file (line 770 has the same warning) — not introduced by this phase.
- The dead translation keys (`namePublished`, `namePublishFailed`) were planned as snackbar messages but no `SnackbarService.showSuccess/showError` calls were added to `publishNameToCesiumPlus`. The feature goal does not strictly require a snackbar (the retry indicator is the primary feedback mechanism), but the keys suggest intent that was not fulfilled.

### Human Verification Required

#### 1. End-to-end CesiumPlus name publish

**Test:** Rename a wallet to a custom name (after fixing the StateProvider issue), then check the CesiumPlus pod for the updated profile title.
**Expected:** Profile title on the pod matches the new wallet name within a few seconds.
**Why human:** Requires a live CesiumPlus pod and valid wallet credentials with an actual keypair.

#### 2. Retry indicator appears on network failure

**Test:** Simulate CesiumPlus pod unavailability (e.g., block the network), rename a wallet, observe the wallet options screen.
**Expected:** Local rename succeeds immediately; the `cloud_off` + `Retry name publication` row appears below the rename button.
**Why human:** Requires controlled network simulation and visual verification of the retry row rendering.

#### 3. Retry re-publishes successfully

**Test:** With the retry indicator visible, tap it, enter PIN, wait for network recovery.
**Expected:** PIN prompt appears; on success, the retry indicator disappears and the name is live on the pod.
**Why human:** Interactive PIN input required; success depends on live pod availability.

### Gaps Summary

**Root cause:** A single API incompatibility blocks both REG-01 and REG-02.

`lib/providers/cs_publish_status_provider.dart` was written using `StateProvider.family<CsPublishStatus, String>`, which was removed from Riverpod in version 3.x. The project uses Riverpod 3.2.1. `dart analyze` reports a compile-time error: `Undefined name 'StateProvider'`.

This cascades to:
- `wallet_management_service.dart` — `ref.read(csPublishStatusProvider(walletAddress).notifier).state = ...` won't compile
- `wallet_options.dart` — `ref.watch(csPublishStatusProvider(widget.wallet.address))` won't compile

The fix is straightforward: replace `StateProvider.family` with `NotifierProvider.family` backed by a `Notifier<CsPublishStatus>` class, following the existing pattern used throughout the codebase (e.g., `RecentCertificationsNotifier` in `certification_queue_provider.dart`).

All other implementation details are correct:
- `publishNameToCesiumPlus` is logically sound — guards on default names, reads existing profile to preserve fields, handles success/failure paths
- Rename flow wiring (`unawaited` call, PIN gate, `!isDefault` guard) is correctly placed in `wallet_options.dart`
- Retry indicator widget structure and logic are correct
- Translation keys for `retryPublishName` are present and used; `namePublished`/`namePublishFailed` are defined but not yet wired to snackbar calls (minor gap, does not block the goal)
- Both commits (1afde01d, 6d19d2cb) are verified in git log

**Secondary gap (warning):** The Plan specified `namePublished` and `namePublishFailed` as "snackbar messages" but no `SnackbarService.showSuccess/showError` calls were added. The user receives no visual feedback on success beyond the status returning to idle. This is an incomplete UX element but does not block the core goal.

---

_Verified: 2026-03-31_
_Verifier: Claude (gsd-verifier)_
