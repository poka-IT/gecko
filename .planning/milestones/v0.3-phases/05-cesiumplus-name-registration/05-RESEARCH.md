# Phase 5: CesiumPlus Name Registration - Research

**Researched:** 2026-03-31
**Domain:** CesiumPlus REST API profile upload, wallet rename integration, fire-and-forget with retry
**Confidence:** HIGH

## Summary

Phase 5 adds automatic CesiumPlus name publication when a user renames their wallet to a custom (non-default) name. All the infrastructure already exists: `CesiumPlusService.uploadProfile()` in durt2 handles profile creation/update with hash+signature authentication, `WalletNameService.isDefault()` detects whether a name is a system default (prefixed with `#`), and `WalletManagementService.renameWallet()` is the single entry point for wallet renames. The implementation is a straightforward composition of these existing capabilities.

The critical design question is **where to inject the CesiumPlus upload and how to handle the PIN requirement**. Currently, `renameWallet()` does not require a PIN (it only writes to the local ObjectBox database). CesiumPlus uploads require a keypair for signing, which requires the PIN. The existing pattern from `uploadAvatarToCesiumPlus()` shows the correct approach: obtain the PIN at the call site (wallet_options.dart already calls `PinCodeService.askPinCode()` for avatar changes), then pass it through. For rename, the upload should be fire-and-forget after the local rename succeeds, with failure tracked via a Riverpod provider for a retry indicator.

The `uploadProfile()` method in durt2 already handles the read-then-merge pattern: it fetches the existing profile, preserves existing fields (avatar, description, city, socials, tags) when not explicitly provided, and only updates the `title` field. This means we can call `uploadProfile()` with only the `title` parameter and it will not clobber existing profile data.

**Primary recommendation:** Add a `publishNameToCesiumPlus()` method to `WalletManagementService`, called fire-and-forget from `wallet_options.dart` after successful rename. Track publish status in a simple `StateProvider.family<CsPublishStatus, String>` keyed by address. Show a retry icon on the wallet options screen when status is `failed`.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REG-01 | When user renames a wallet (non-default name), the name is published as CesiumPlus profile | `WalletNameService.isDefault()` already detects default names; `CesiumPlusService.uploadProfile()` handles create/update with read-then-merge; `WalletManagementService.renameWallet()` is the single rename entry point |
| REG-02 | On network failure, a status indicator and retry are available | `SnackbarService` exists for immediate feedback; `StateProvider.family` can track per-address publish status; `uploadProfile()` returns `bool` for success/failure detection |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| durt2 | local override | `CesiumPlusService.uploadProfile()` for profile creation/update | Already handles hash+signature auth, read-then-merge, create vs update detection |
| flutter_riverpod | ^3.2.1 | `StateProvider.family` for publish status tracking | Already used throughout codebase for state management |
| easy_localization | ^3.0.8 | Translation keys for publish status messages | Already used for all UI strings |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| PinCodeService | internal | Cached PIN retrieval for keypair access | When CesiumPlus upload needs signing |
| SnackbarService | internal | User feedback on publish success/failure | After upload attempt completes |
| WalletNameService | internal | `isDefault()` check to gate publication | Before every upload attempt |

No new packages are needed. Everything is already in the project.

## Architecture Patterns

### Integration Point Map

```
wallet_options.dart (UI)
  |
  |-- [tap Rename] --> WalletNameDialogService.showEditWalletNameDialog()
  |                       |
  |                       |-- WalletManagementService.renameWallet() [local save]
  |                       |-- returns newName
  |
  |-- [if newName != null && !isDefault(newName)]
  |     |
  |     |-- PinCodeService.askPinCode() [if PIN not cached]
  |     |-- WalletManagementService.publishNameToCesiumPlus() [fire-and-forget]
  |           |
  |           |-- walletService.getKeyPairFromAddress() [needs PIN]
  |           |-- cesiumPlusService.uploadProfile(title: newName) [read-then-merge]
  |           |-- Update csPublishStatusProvider [success/failed]
  |           |-- Invalidate cesiumProfileProvider(address) [refresh cache]
```

### Pattern 1: Fire-and-Forget with Status Tracking

**What:** The CesiumPlus upload runs after the local rename succeeds. It does not block the dialog close or the UI update. A Riverpod `StateProvider.family` tracks the publish status per address.

**When to use:** When a network operation must not block a local operation, but the user needs to know if it failed and be able to retry.

**Example:**
```dart
// In lib/providers/ — new provider
enum CsPublishStatus { idle, publishing, success, failed }

final csPublishStatusProvider = StateProvider.family<CsPublishStatus, String>(
  (ref, address) => CsPublishStatus.idle,
);
```

```dart
// In wallet_options.dart — after rename dialog returns
final newName = await WalletNameDialogService.showEditWalletNameDialog(context, widget.wallet);
if (newName != null && mounted) {
  // ... existing loadWallets/setState code ...

  // Fire-and-forget CesiumPlus publish for custom names
  if (!WalletNameService.isDefault(newName)) {
    final pinOk = await PinCodeService.askPinCode(context, wallet: widget.wallet);
    if (pinOk && mounted) {
      unawaited(WalletManagementService.publishNameToCesiumPlus(
        widget.wallet.address, newName, PinCodeService.pinCode, ref: ref,
      ));
    }
  }
}
```

### Pattern 2: Read-Then-Merge on Profile Update

**What:** `uploadProfile()` in durt2 already implements this pattern. When `isUpdate` is true, it fetches the existing profile and preserves all fields not explicitly provided. This means calling `uploadProfile(title: newName)` without avatar/description/city will keep the existing avatar/description/city intact.

**When to use:** Always when updating CesiumPlus profiles. Never construct a profile from scratch when updating.

**Key code from `cesium_plus_service.dart` (lines 349-399):**
```dart
final existingProfile = forceCreate ? null : await _getProfileByPubkeyInternal(pubkey);
final isUpdate = existingProfile != null;
// ...
// Add avatar if provided
if (avatarBytes != null) {
  profile['avatar'] = { ... };
} else if (isUpdate && existingProfile['avatar'] != null) {
  // Keep existing avatar if updating and no new avatar provided
  profile['avatar'] = existingProfile['avatar'];
}
```

### Pattern 3: PIN Acquisition at Call Site

**What:** The PIN is obtained via `PinCodeService.askPinCode()` at the UI level (wallet_options.dart), then passed down to the service method. This matches the existing pattern used by `changeAvatar()`.

**When to use:** Every time a CesiumPlus write operation needs signing.

**Existing pattern from wallet_options.dart (lines 200-217):**
```dart
final pinCodeValid = await PinCodeService.askPinCode(context, wallet: widget.wallet);
if (!mounted) return;
if (pinCodeValid) {
  final newPath = await WalletManagementService.changeAvatar(
    widget.wallet.address,
    pinCode: PinCodeService.pinCode,
    ref: ref,
  );
  // ...
}
```

### Anti-Patterns to Avoid

- **Requiring PIN before showing the rename dialog:** The PIN is only needed for CesiumPlus upload, not for local rename. Ask for PIN after the dialog closes and only if the name is non-default.
- **Blocking the rename on CesiumPlus upload success:** The local rename must always succeed immediately. CesiumPlus is optional/fire-and-forget.
- **Publishing default names to CesiumPlus:** `WalletNameService.isDefault(name)` must be checked before any upload. Default names start with `#` and are locale-dependent display names.
- **Creating a new profile when updating title only:** Always let `uploadProfile()` handle the create-vs-update detection. It already does read-then-merge correctly.
- **Calling `uploadProfile()` without preserving existing data:** When only updating the title, do NOT pass explicit `null` for description/city/etc. Let the read-then-merge in `_uploadProfileInternal` handle it. The existing code preserves fields when they are not provided.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Profile hash+signature auth | Custom signing logic | `CesiumPlusService.uploadProfile()` | Already handles SHA256 hash, signature prepending, JSON serialization quirks |
| Create vs update detection | Manual profile existence check | `uploadProfile()`'s internal `_getProfileByPubkeyInternal` | Already branches to `/user/profile` (create) vs `/user/profile/$pubkey/_update` (update) |
| Field preservation on update | Manual profile field copying | `_uploadProfileInternal`'s read-then-merge | Already preserves avatar, description, city, socials, tags when not provided |
| PIN cache management | Custom PIN state | `PinCodeService.askPinCode()` + `PinCodeService.pinCode` | Already handles cache timeout, safe number validation, desktop vs mobile modal |
| Default name detection | Custom regex/string matching | `WalletNameService.isDefault()` | Already handles `#main`, `#2`, `#legacy` etc. |

**Key insight:** The entire CesiumPlus upload pipeline (signing, hashing, create/update routing, field merging) already exists and works. This phase is purely about wiring it into the rename flow with proper failure handling.

## Common Pitfalls

### Pitfall 1: Overwriting Existing Profile Data When Only Updating Title
**What goes wrong:** Calling `uploadProfile()` and explicitly passing `null` for description, city, etc. causes the read-then-merge logic to set those fields to `null` in the update, erasing existing data.
**Why it happens:** The `_uploadProfileInternal` code at lines 364-399 explicitly clears fields when they are `null` AND the existing profile has data: `if (isUpdate && existingProfile['description'] != null) { profile['description'] = null; }`
**How to avoid:** Do NOT pass description/city/socials/tags at all when only updating the title. The method signature uses optional parameters -- omit them entirely so the `else if` branch that clears data is never reached.
**Warning signs:** After a rename+publish, the user's profile description/city/avatar disappears.

**CORRECTION on re-reading the code:** Actually, the `_uploadProfileInternal` code DOES clear fields when they are `null` (not provided). Lines 364-366: `if (description != null && description.isNotEmpty) { profile['description'] = description; } else if (isUpdate && existingProfile['description'] != null) { profile['description'] = null; }`. This means calling `uploadProfile(title: newName)` WITHOUT providing description WILL clear the existing description. **This is a real bug that must be addressed.** The `publishNameToCesiumPlus()` method must read the existing profile first and pass through all existing fields to `uploadProfile()`, OR the method must provide them from the existing profile. Since `uploadProfile()` already reads the profile internally (via `existingProfile`), the fix is to change the logic: when a field is `null` (not provided) and `isUpdate`, keep the existing value instead of clearing it. But modifying durt2 may be out of scope. The simpler approach is: read the profile first in `publishNameToCesiumPlus()`, then pass existing field values through to `uploadProfile()`.

### Pitfall 2: Publishing Default Names to CesiumPlus
**What goes wrong:** If `WalletNameService.isDefault()` check is missed, names like `#main` get published to CesiumPlus as the literal string "#main".
**Why it happens:** The `#` prefix is an internal convention. CesiumPlus has no concept of it.
**How to avoid:** Gate the publish call on `!WalletNameService.isDefault(newName)`. This is a hard requirement (REG-01 specifies "non-default names only").
**Warning signs:** CesiumPlus profiles showing `#main`, `#2`, `#legacy` as their title.

### Pitfall 3: Not Requesting PIN for CesiumPlus Upload
**What goes wrong:** The rename dialog does not currently require PIN. Adding CesiumPlus upload requires a keypair for signing, which requires the PIN.
**Why it happens:** `renameWallet()` only writes to local ObjectBox and does not need crypto operations.
**How to avoid:** Request PIN after the rename dialog closes (not before/during), only when the name is non-default. If PIN is already cached (PinCodeService), it will be returned immediately without user interaction.
**Warning signs:** `getKeyPairFromAddress` throws because pinCode is empty.

### Pitfall 4: Making CesiumPlus Upload Blocking
**What goes wrong:** If the upload is awaited in the rename flow, the UI freezes for up to 30 seconds (the timeout on `uploadProfile()`), or fails to rename locally if the network is down.
**Why it happens:** Natural tendency to `await` everything.
**How to avoid:** Use `unawaited()` for the publish call. Track status via provider. Local rename must complete and close the dialog immediately.
**Warning signs:** Dialog stays open for seconds after tapping validate; rename fails when offline.

### Pitfall 5: Not Invalidating cesiumProfileProvider After Upload
**What goes wrong:** After publishing a new name to CesiumPlus, the cached `cesiumProfileProvider(address)` still returns the old profile. Other screens (wallet_header, name_by_address) show the old name or no name.
**Why it happens:** `cesiumProfileProvider` is a `FutureProvider.family` -- it caches its result until invalidated.
**How to avoid:** After a successful upload, call `ref.invalidate(cesiumProfileProvider(address))` so the next read fetches the updated profile.
**Warning signs:** Name shows as old value in wallet header until app restart.

## Code Examples

### Example 1: publishNameToCesiumPlus Method (New)

```dart
// In lib/services/wallet_management_service.dart
/// Publish wallet name to CesiumPlus pod as profile title.
///
/// Fire-and-forget: updates csPublishStatusProvider with result.
/// Only publishes non-default names. Preserves existing profile data.
static Future<void> publishNameToCesiumPlus(
  String walletAddress,
  String name,
  String pinCode, {
  required riverpod.WidgetRef ref,
}) async {
  // Safety: never publish default names
  if (WalletNameService.isDefault(name)) return;

  ref.read(csPublishStatusProvider(walletAddress).notifier).state = CsPublishStatus.publishing;

  try {
    final walletService = ref.read(walletServiceProvider);
    final cesiumPlusService = ref.read(cesiumPlusServiceProvider);

    final keyPair = await walletService.getKeyPairFromAddress(
      address: walletAddress, pinCode: pinCode,
    );

    // Read existing profile to preserve fields (see Pitfall 1)
    final existing = await cesiumPlusService.getProfileByAddress(walletAddress);

    final success = await cesiumPlusService.uploadProfile(
      address: walletAddress,
      signFunction: keyPair.sign,
      title: name,
      // Pass through existing fields to prevent overwrite
      description: existing?['description'] as String?,
      city: existing?['city'] as String?,
      geoPointLat: existing?['geoPoint']?['lat']?.toString(),
      geoPointLon: existing?['geoPoint']?['lon']?.toString(),
      socials: (existing?['socials'] as List?)
          ?.map((s) => CesiumSocial.fromJson(s as Map<String, dynamic>))
          .toList(),
      tags: (existing?['tags'] as List?)?.cast<String>(),
    );

    if (success) {
      ref.read(csPublishStatusProvider(walletAddress).notifier).state = CsPublishStatus.success;
      ref.invalidate(cesiumProfileProvider(walletAddress));
      log.i('CesiumPlus name published: $name');
    } else {
      ref.read(csPublishStatusProvider(walletAddress).notifier).state = CsPublishStatus.failed;
      log.w('CesiumPlus name publish failed for $walletAddress');
    }
  } catch (e) {
    ref.read(csPublishStatusProvider(walletAddress).notifier).state = CsPublishStatus.failed;
    log.e('CesiumPlus name publish error: $e');
  }
}
```

### Example 2: Retry Indicator Widget Pattern

```dart
// In wallet_options.dart — near the rename InkWell
// Show retry indicator when CesiumPlus publish failed
final publishStatus = ref.watch(csPublishStatusProvider(widget.wallet.address));
if (publishStatus == CsPublishStatus.failed)
  InkWell(
    onTap: () async {
      final pinOk = await PinCodeService.askPinCode(context, wallet: widget.wallet);
      if (pinOk && mounted) {
        unawaited(WalletManagementService.publishNameToCesiumPlus(
          widget.wallet.address,
          widget.wallet.name!,
          PinCodeService.pinCode,
          ref: ref,
        ));
      }
    },
    child: Row(
      children: [
        Icon(Icons.cloud_off, color: context.geckoColors.warning),
        SizedBox(width: 8),
        Text('retryPublishName'.tr()),
      ],
    ),
  ),
```

### Example 3: Call Site in wallet_options.dart

```dart
// After rename dialog returns successfully
final newName = await WalletNameDialogService.showEditWalletNameDialog(context, widget.wallet);
if (newName != null && mounted) {
  await ref.read(walletsListProvider.notifier).loadWallets(safeBoxNumber: currentSafe);
  if (!mounted) return;
  // ... existing state update code ...

  // Publish to CesiumPlus if non-default name
  if (!WalletNameService.isDefault(newName)) {
    final pinOk = await PinCodeService.askPinCode(context, wallet: widget.wallet);
    if (pinOk && mounted) {
      unawaited(WalletManagementService.publishNameToCesiumPlus(
        widget.wallet.address, newName, PinCodeService.pinCode, ref: ref,
      ));
    }
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| CesiumPlus name only set via CesiumProfileScreen (manual) | Auto-publish on wallet rename | Phase 5 (this phase) | Users become discoverable without visiting profile settings |
| `uploadAvatarToCesiumPlus` as only write pattern | `publishNameToCesiumPlus` adds title-only write | Phase 5 | Title updates preserve existing profile data |

## Open Questions

1. **Should PIN be requested before or after the rename dialog?**
   - What we know: Current flow shows rename dialog first, no PIN. Avatar change requests PIN first. The rename dialog is a quick operation; asking PIN after feels more natural since the local rename is the primary action and CesiumPlus is secondary.
   - Recommendation: Ask PIN AFTER the rename dialog returns a non-default name. If PIN is cached, user sees nothing. If not cached, they see the PIN dialog after the rename succeeds. If they dismiss the PIN dialog, local rename still worked; CesiumPlus just didn't publish (status = idle, no retry indicator needed since they actively declined).

2. **Should a publishing indicator (spinner) show during the upload?**
   - What we know: The upload takes up to 30 seconds (timeout). A snackbar could show "Publishing name..." but snackbars auto-dismiss. A provider-driven `publishing` state could show a subtle spinner on the wallet options screen.
   - Recommendation: Show a brief snackbar on success ("Name published to CesiumPlus"). Show the retry indicator (persistent widget) only on failure. The `publishing` state can show a small CircularProgressIndicator next to the rename button, but this is optional polish.

3. **Profile field preservation: should we modify durt2 or work around?**
   - What we know: `_uploadProfileInternal` clears fields not provided when `isUpdate` is true. Reading the profile first and passing existing fields through is a correct workaround.
   - Recommendation: Work around by reading the profile first in `publishNameToCesiumPlus()`. This adds one extra HTTP call but is correct and avoids modifying durt2. The `uploadProfile()` method already reads the profile internally too, so there is a small inefficiency (profile fetched twice), but it is acceptable for correctness.

## Project Constraints (from CLAUDE.md)

- **Never run flutter build/run commands** -- only `flutter pub get`, `flutter analyze`, `dart format .`
- **Never use destructive git commands** -- no stash, checkout ., reset --hard, etc.
- **Riverpod conventions:** Never use codegen (`@riverpod`); write providers manually. Prefer `AsyncNotifier` for async state, `FutureProvider` for cached async data. Document providers in English.
- **UTF-8 accents in translations:** Always use proper diacritics in French, Spanish, Italian strings
- **Desktop/Mobile dual layout:** Every new screen must support both; use `embeddedMode` parameter pattern
- **UI text with markdown:** Use `TextMarkDown` widget instead of `Text` for strings containing markdown formatting
- **Git commits:** Subject line only, no Co-Authored-By signature

## Sources

### Primary (HIGH confidence)
- `lib/services/wallet_management_service.dart` -- existing `renameWallet()` and `uploadAvatarToCesiumPlus()` patterns
- `lib/services/wallet_name_service.dart` -- `isDefault()` check, `#` prefix convention
- `lib/services/wallet_name_dialog_service.dart` -- rename dialog flow, validation integration
- `lib/screens/myWallets/wallet_options.dart` -- UI integration point, PIN acquisition pattern
- `../durt2/lib/src/services/cesium_plus_service.dart` -- `uploadProfile()`, `_uploadProfileInternal()` read-then-merge logic, hash+signature auth
- `lib/providers/cesium_name_provider.dart` -- existing `cesiumNameProvider` cache that needs invalidation
- `lib/providers/cesium_profile_provider.dart` -- existing `cesiumProfileProvider` cache
- `lib/services/pin_cache_service.dart` -- PIN cache mechanism, `askPinCode()` flow

### Secondary (MEDIUM confidence)
- `.planning/research/SUMMARY.md` -- project-level architecture decisions, pitfall analysis

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all components verified present in codebase, no new packages needed
- Architecture: HIGH -- integration points directly readable in source, patterns verified from existing `uploadAvatarToCesiumPlus` flow
- Pitfalls: HIGH -- profile field overwrite issue confirmed by reading `_uploadProfileInternal` lines 364-399; all other pitfalls grounded in concrete code paths

**Research date:** 2026-03-31
**Valid until:** 2026-04-30 (stable domain, no external dependencies changing)
