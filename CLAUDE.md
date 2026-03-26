# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ğecko is a Flutter mobile wallet for the Duniter v2s blockchain (Ḡ1v2). It uses the `durt2` package to interact with Duniter nodes and provides wallet management, identity certification, and transaction capabilities.

## Build & Run Commands

```bash
# Run in debug mode (requires running emulator)
flutter run

# Build APK
./scripts/build-apk.sh

# Run unit tests
flutter test                                         # all unit tests
flutter test test/providers/                         # provider tests only

# Code generation (Hive adapters)
./scripts/build_runner.sh

# Lint
flutter analyze

# Format (uses page_width from analysis_options.yaml)
dart format .
```

## Architecture

### State Management: Riverpod + Legacy Provider

The app is migrating from `package:provider` to **Riverpod 3**. Both coexist:
- New code uses `flutter_riverpod` with `ConsumerWidget`/`ConsumerStatefulWidget`
- Legacy providers in `lib/providers_deprecated/` (being phased out)

**Riverpod conventions (from `.cursor/rules/migration_riverpod.mdc`):**
- **Never use codegen** (`@riverpod` syntax) - write providers manually
- Separate business logic into `lib/services/` (stateless), state management in `lib/providers/`
- Prefer `AsyncNotifier` for async state, `FutureProvider` for cached async data
- Document providers in English with `///`

### Core Provider Hierarchy

Root provider chain in `lib/providers/providers.dart`:
```
durtProvider (Durt.i singleton)
├── walletServiceProvider    → Wallet/Safe management
├── storageServiceProvider   → On-chain data cache & subscriptions
├── duniterServiceProvider   → Transaction building (pay, certify, etc.)
├── squidServiceProvider     → GraphQL indexer queries
├── cesiumPlusServiceProvider → Identity REST API
└── networkProvider          → Current network (gdev, gtest, g1)
```

### Key Directories

- `lib/providers/` - Riverpod providers (state management)
- `lib/services/` - Stateless business logic (mnemonic, wallet scan, PIN security)
- `lib/screens/` - UI screens (ConsumerStatefulWidget pattern)
- `lib/widgets/` - Reusable UI components
- `lib/models/` - Data models and widget keys
- `lib/providers_deprecated/` - Legacy ChangeNotifier providers (do not add new ones)

### Blockchain Integration (durt2)

The `durt2` package provides all Duniter blockchain interactions:
- Real-time subscriptions: `storageService.subscribeBalance(address)`, `subscribeIdtyStatus(address)`
- Connection streams: `durt.duniterConnectionStatusStream`, `squid.connectionStream`
- Transactions: Built via `duniterService.pay()`, `duniterService.certify()`, etc.

### Connection State Management

`lib/providers/connection_providers.dart` handles dual connectivity (Duniter node + Squid indexer):
- `storageStateProvider` tracks: `notInitialized`, `offlineMode`, `onlineMode`
- Reconnection triggers provider invalidation for automatic data refresh

## Unit Tests

Unit tests use durt2's test mode to mock blockchain services without network connections.

### Running tests

```bash
flutter test                          # all tests
flutter test test/providers/          # provider tests only
```

### Test mode setup (durt2)

The `durt2` package provides `DurtTestMode` to mock `Durt.storage` and `Durt.wallets`:

```dart
import 'package:durt2/durt2.dart';

setUpAll(() async {
  await DurtTestMode.init();
});

tearDownAll(() {
  Durt.resetTestMode();
});
```

### Testing async providers (priming technique)

When testing providers that use `ref.watch()` on `AsyncNotifierProvider`, you must "prime" them first to avoid hanging on `AsyncLoading`:

```dart
final container = ProviderContainer(overrides: [...]);

// Prime async providers BEFORE reading the main provider
await container.read(certStateProvider(address).future);
await container.read(certificationQueueProvider(address).future);

// Now safe to read the provider that watches them
final state = await container.read(certButtonStateProvider(address).future);
```

### Test structure

- `test/providers/` - Riverpod provider unit tests
- Widget keys for test interactions: `lib/models/widgets_keys.dart`

## Localization

Uses `easy_localization` with translations in `assets/translations/`. Supported: en, fr, es, it.

**CRITICAL: Always use proper UTF-8 accented characters in ALL translation strings.** Never write ASCII-only approximations. This applies to every language:
- **French**: é, è, ê, ë, à, â, ù, û, ô, î, ï, ç (e.g. "Sélectionner" not "Selectionner", "période" not "periode", "reçu" not "recu")
- **Spanish**: á, é, í, ó, ú, ñ, ü (e.g. "análisis" not "analisis", "días" not "dias", "conexión" not "conexion")
- **Italian**: à, è, é, ì, ò, ù (e.g. "può" not "puo", "perché" not "perche")
- **Esperanto**: ĉ, ĝ, ĥ, ĵ, ŝ, ŭ
- **German**: ä, ö, ü, ß

When adding or modifying translation strings, double-check every word for missing diacritics before committing.

## Desktop / Mobile Dual Layout

**CRITICAL: Every new screen MUST support both mobile (full-screen push) and desktop (modal) layouts.** Never push a mobile-only screen on desktop.

**Pattern to follow:**
1. Create the screen widget with an `embeddedMode` parameter (omits AppBar when `true`)
2. Create a desktop modal wrapper in `lib/widgets/desktop/modals/` using `showDesktopModal()`
3. At the navigation call site, use `isDesktopLayout(context)` to route:
   - Desktop: close current modal if in `embeddedMode`, then call `showDesktop*Modal()`
   - Mobile: `Navigator.pushNamed()` as usual

**Reference:** `NavigationService.openProfile()` in `lib/services/navigation_service.dart` is the canonical example (desktop → `showDesktopProfileModal`, mobile → `Navigator.push` with `ProfileViewScreen`).

**Existing desktop modals:** `lib/widgets/desktop/modals/` — activity, profile, cesium_profile, certification_queue, market_analysis, settings, etc.

## Git Commit Conventions

- When a commit fixes a GitLab issue, include `Closes #<number>` in the commit message (e.g. `fix: membership banner too early\n\nCloses #156`). This auto-closes the issue on GitLab.

## Bug Research Strategy

When searching for bugs across forums and issue trackers, always launch all searches **in parallel using multiple agents or tool calls**:
- Forum Duniter (MCP `discourse`): filter by `tag:bugv2`, search `gecko after:DATE`, read recent posts of topic #9372
  - **IMPORTANT**: Always paginate to read ALL posts of a topic. `discourse_read_topic` returns max 50 posts per call. Use `start_post_number` to fetch subsequent pages until `has_more` is false. Missing the latest posts means missing critical information.
  - **Viewing forum images**: Discourse MCP tools don't resolve `upload://` image URLs. To view screenshots/images from forum posts:
    1. Get the `post_id` from the MCP `discourse_read_topic` response
    2. `WebFetch` on `https://forum.duniter.org/posts/{post_id}.json` → extract image URLs from the `cooked` HTML field (look for `<img src="..."`)
    3. Download the image: `curl -sL "{image_url}" -o /tmp/forum_image.png`
    4. View with `Read` tool: `Read /tmp/forum_image.png` (supports PNG, JPG, etc.)
  - For Forum Monnaie Libre, use `https://forum.monnaie-libre.fr/posts/{post_id}.json` instead
- Forum Monnaie Libre (MCP `discourse-ml`): filter `category:gecko`, search `gecko bug after:DATE`
- GitLab API: `WebFetch` on `https://git.duniter.org/api/v4/projects/clients%2Fgecko/issues?state=opened&order_by=created_at&sort=desc`
- See `memory/forum_search_guide.md` for full details

### Forum bug → Sentry → Fix → Reply workflow

When a user reports a bug on the forum, follow this complete workflow:

1. **Read the forum post** — get screenshots (resolve `upload://` URLs via the post JSON `cooked` field), understand the issue described by the user
2. **Search Sentry** — in parallel, search for matching issues on the **latest version only** (see "Sentry Issue Analysis" section). Cross-reference the user's description, platform, and timing with Sentry stacktraces and diagnostic tags
3. **Analyze** — read the relevant source code, identify the root cause, plan the fix
4. **Fix & commit** — implement the fix, commit with `Fixes AXIOM-TEAM-XX` in the message to reference Sentry issues
5. **Reply on the forum** — post a reply to the user (via the Discourse API, NOT MCP which is read-only) explaining:
   - What the problem was (cause racine, en termes accessibles)
   - What was fixed (résumé technique concis)
   - In which version it will be available (next version from `pubspec.yaml`)
   - Keep the tone **polite, friendly, and grateful** for the report
   - Example format:
     ```
     Salut @username,

     Merci pour le retour ! J'ai identifié le problème grâce à [source].

     [Explication du problème en termes accessibles].

     C'est corrigé, [résumé de la correction]. Ce sera disponible dans la version **X.Y.Z**.
     ```
6. **Provide Sentry resolve links** — give the user (poka) the direct Sentry issue URLs to manually mark as "Resolve in Next Release"

## GitLab Issue Management

The `GITLAB_TOKEN` env variable provides access to `git.duniter.org` API. Project ID: **474** (path: `clients/gecko`).

**IMPORTANT**: Use `Authorization: Bearer` header (NOT `PRIVATE-TOKEN`) for ALL write operations (POST, PUT, DELETE). `PRIVATE-TOKEN` works only for read (GET).

### Create an issue

Prefer Python over curl to avoid shell quoting issues with apostrophes/accents:

```python
import json, urllib.request, os
token = os.environ['GITLAB_TOKEN']
data = json.dumps({"title": "...", "description": "...", "labels": "bug"}).encode()
req = urllib.request.Request('https://git.duniter.org/api/v4/projects/474/issues', data=data, method='POST')
req.add_header('Authorization', f'Bearer {token}')
req.add_header('Content-Type', 'application/json')
with urllib.request.urlopen(req) as resp:
    result = json.loads(resp.read())
    print(f'#{result["iid"]} - {result["web_url"]}')
```

### List open issues

```bash
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://git.duniter.org/api/v4/projects/474/issues?state=opened&order_by=created_at&sort=desc"
```

### Add a comment to an issue

```bash
curl -s --request POST \
  --header "Authorization: Bearer $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  -d '{"body":"comment text"}' \
  "https://git.duniter.org/api/v4/projects/474/issues/ISSUE_IID/notes"
```

**IMPORTANT**: When creating an issue from a forum report that contains screenshots/images, always include those images in the GitLab issue description. Use the Discourse image resolution method (see "Viewing forum images" in Bug Research Strategy) to get the actual image URLs, then embed them in the issue description with `![description](image_url)`.

Available labels: `bug`, `p1`, `p2`, `p3`, `need-infos`, `GoodFirstIssue`, `Refactoring`, `WIP`, `blocked`, `duplicated`

## UI Text Rendering

- **Never use plain `Text` widget for translation strings that contain markdown** (bold `**...**`, italic `*...*`, etc.). Use `TextMarkDown` from `lib/widgets/commons/text_markdown.dart` instead, which renders markdown formatting via `flutter_markdown`.
- This applies to all UI: screens, modals, dialogs, cards, etc.

## Sentry Issue Analysis

The Sentry project is **axiom-team** (org: `axiom-team`, regionUrl: `https://us.sentry.io`). The project slug is `axiom-team`.

### Release tags by platform

Gecko uses **3 different release tag formats** depending on the platform. When analyzing issues, **always query all 3 release tags** to get the full picture:
- `gecko@{version}+{build}` — Linux, Windows (desktop)
- `fr.axiomteam.gecko@{version}+{build}` — Android
- `fr.axiom-team.gecko@{version}+{build}` — iOS, macOS

**IMPORTANT**: Always filter by the **latest release version** (check `pubspec.yaml` for `version:`). Issues from old versions may already be fixed. Search all 3 release tags in parallel.

### Querying issues

Use the Sentry MCP tools:
- `search_issues` with `naturalLanguageQuery: "unresolved issues with release <tag>"` for each of the 3 release tags
- `get_issue_details` for individual issue investigation (includes stacktrace, tags, device info)
- `search_events` for counts/aggregations

### Diagnostic tags

Gecko sends rich diagnostic context with every Sentry event. Key tags to check:
- `diagnostic_durt_storage_status_*` — connection endpoint, storage mode (online/offline)
- `diagnostic_indexer_debug_connection_status_*` — duniter/squid connection state
- `diagnostic_providers_state_*` — app state (home message, wallets count, connection status)
- `diagnostic_authentication_debug_*` — PIN state, safe state
- `diagnostic_device_info_*` — screen size, pixel ratio (helps identify desktop vs mobile)
- `diagnostic_app_info_platform` — android, ios, linux, macos, windows

### Fixing Sentry issues — quality rules

When fixing a Sentry crash, **never write a band-aid that silences the symptom**. Always fix the root cause:

1. **No empty `catch` blocks to silence crashes.** A `catch` is only justified if the caught scenario is an expected, documented edge case (e.g., offline mode during a network query) AND the recovery behavior is correct for the flow (e.g., returning partial results, showing a user-facing error). If a catch is needed, verify the existing codebase already uses the same pattern for the same call — be consistent.

2. **No `if (!mounted) return;` as a band-aid.** If a callback fires after widget disposal, ask *why* the callback still references stale state. Common root causes and real fixes:
   - **`ScaffoldMessenger.of(context)` in late callbacks/dispose**: capture `ScaffoldMessengerState` once when creating the snackbar/widget, store it as a field, reuse it everywhere. No context re-lookup needed.
   - **Timer/stream callbacks after disposal**: cancel them in `dispose()`, don't guard with `mounted`.
   - `mounted` checks ARE appropriate when protecting code that genuinely needs a live widget tree (e.g., `showModalBottomSheet`, `Navigator.push`, `showDialog`), because those operations require an active overlay/context by design.

3. **Understand the flow before writing the fix.** Read the full stacktrace, check diagnostic tags (PIN state, connection state, lifecycle state), read the source code of every frame in the stacktrace that's in our codebase. The fix must make sense in context of the actual user flow, not just suppress the exception.

4. **Before proposing a fix, ask yourself:** "Does this fix address why the error happens, or does it just prevent the crash from being reported?" If the answer is the latter, dig deeper.

### After fixing a Sentry issue

Once a fix is committed, provide the user with direct links to each resolved Sentry issue so they can manually mark them as **"Resolve in Next Release"** in the Sentry UI. Format:
```
https://axiom-team.sentry.io/issues/AXIOM-TEAM-XX
```
The Sentry MCP has no `update_issue` tool, so this manual step is required.

## Platform Notes

- Android API 23+, iOS, macOS, Linux, Windows supported
- Portrait orientation only (mobile), free resize (desktop)
- SSL self-signed certificates enabled for Android compatibility
- Local dev can override durt2 via `pubspec.yaml` dependency_overrides pointing to `../durt2`
