import 'dart:async';
import 'dart:convert';
import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/persist_storage_provider.dart';
import 'package:gecko/providers/squid_cache_buster.dart';

/// Result of fetching a page of items from the API.
class PaginatedResult<T> {
  final List<T> items;
  final bool hasNextPage;
  final String? endCursor;

  const PaginatedResult({required this.items, required this.hasNextPage, this.endCursor});
}

/// Generic paginated state that replaces per-domain state classes.
///
/// JSON serialization uses [itemsJsonKey] as the key for the items list
/// to maintain backward compatibility with existing persisted data
/// (e.g. 'transactions', 'certifications', 'identities').
class PaginatedState<T> {
  final List<T> items;
  final bool isLoading;
  final bool hasNextPage;
  final String? cursor;
  final String? error;
  final String? lastActivityId;

  const PaginatedState({
    this.items = const [],
    this.isLoading = false,
    this.hasNextPage = false,
    this.cursor,
    this.error,
    this.lastActivityId,
  });

  PaginatedState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? hasNextPage,
    String? cursor,
    String? error,
    String? lastActivityId,
  }) {
    return PaginatedState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      cursor: cursor ?? this.cursor,
      error: error ?? this.error,
      lastActivityId: lastActivityId ?? this.lastActivityId,
    );
  }

  /// Serialize to JSON using [itemsJsonKey] for backward compatibility.
  Map<String, dynamic> toJson(String itemsJsonKey, Map<String, dynamic> Function(T item) itemToJson) => {
    itemsJsonKey: items.map(itemToJson).toList(),
    'hasNextPage': hasNextPage,
    'cursor': cursor,
    'lastActivityId': lastActivityId,
  };

  /// Deserialize from JSON using [itemsJsonKey] for backward compatibility.
  static PaginatedState<T> fromJson<T>(
    Map<String, dynamic> json,
    String itemsJsonKey,
    T Function(Map<String, dynamic> json) itemFromJson,
  ) => PaginatedState<T>(
    items: (json[itemsJsonKey] as List).map((e) => itemFromJson(e as Map<String, dynamic>)).toList(),
    hasNextPage: json['hasNextPage'] as bool? ?? false,
    cursor: json['cursor'] as String?,
    lastActivityId: json['lastActivityId'] as String?,
  );
}

/// Abstract base notifier that implements the full paginated lifecycle:
/// persistence, subscriptions, initial load, refresh, and pagination.
///
/// Subclasses only need to implement the abstract members to define
/// their domain-specific behavior.
abstract class BasePaginatedNotifier<T> extends Notifier<PaginatedState<T>> {
  StreamSubscription<String?>? _activitySubscription;
  bool _isLoadingGuard = false;

  // ── Abstract members that subclasses must provide ──

  /// Persist key used to store/restore state (e.g. 'networkIdentities_gdev').
  String get persistKey;

  /// JSON key for the items list, for backward-compatible serialization.
  /// E.g. 'transactions', 'certifications', 'identities'.
  String get itemsJsonKey;

  /// Serialize a single item to JSON.
  Map<String, dynamic> itemToJson(T item);

  /// Deserialize a single item from JSON.
  T itemFromJson(Map<String, dynamic> json);

  /// Create a subscription stream that yields activity IDs.
  /// Return null if no subscription is needed or Squid is not connected.
  Stream<String?>? createSubscription();

  /// Fetch a page of items from the API.
  /// Return null if the API call fails or Squid is not connected.
  Future<PaginatedResult<T>?> fetchPage({required int count, String? cursor});

  /// Whether this notifier should watch the squid cache buster provider.
  /// Override to return true for providers that need to rebuild when the
  /// Squid endpoint changes (e.g. account-scoped history providers).
  bool get watchCacheBuster => false;

  /// Whether persist should mark isLoading: true on decode.
  /// Family providers (account-scoped) set this to true so the UI shows
  /// a loading indicator while fresh data is fetched.
  bool get markLoadingOnDecode => false;

  // ── Lifecycle ──

  @override
  PaginatedState<T> build() {
    ref.onDispose(() => _activitySubscription?.cancel());

    // Persist state to local SQLite DB for instant display on app restart
    persist(
      ref.read(persistStorageProvider.future),
      key: persistKey,
      encode: (state) => jsonEncode(state.toJson(itemsJsonKey, itemToJson)),
      decode: (json) {
        final decoded = PaginatedState.fromJson<T>(
          jsonDecode(json) as Map<String, dynamic>,
          itemsJsonKey,
          itemFromJson,
        );
        return markLoadingOnDecode ? decoded.copyWith(isLoading: true) : decoded;
      },
      options: const StorageOptions(destroyKey: persistCacheVersion),
    );

    // Optionally watch the cache buster to force refresh when Squid endpoint changes
    if (watchCacheBuster) {
      ref.listen(squidCacheBusterProvider, (previous, next) {
        log.i('Cache buster changed ($previous -> $next) - reloading $persistKey');
        loadItems();
      });
    }

    // React to Squid connection changes: reload + resubscribe when connected
    ref.listen(squidConnectionStatusProvider, (previous, next) {
      if (previous != d.ConnectionStatus.connected && next == d.ConnectionStatus.connected) {
        log.i('Squid connected - loading $persistKey');
        loadItems();
        _subscribe();
      }
    });

    // Start initial load asynchronously
    Future.microtask(() {
      final status = ref.read(squidConnectionStatusProvider);
      if (status == d.ConnectionStatus.connected) {
        loadItems();
        _subscribe();
      }
    });

    return PaginatedState<T>(isLoading: true);
  }

  // ── Subscription ──

  void _subscribe() {
    _activitySubscription?.cancel();

    final squidStatus = ref.read(squidConnectionStatusProvider);
    if (squidStatus != d.ConnectionStatus.connected) {
      log.w('Cannot subscribe: Squid not connected ($persistKey)');
      return;
    }

    try {
      final stream = createSubscription();
      if (stream == null) return;

      _activitySubscription = stream.listen(
        (activityId) {
          if (activityId != null && activityId != state.lastActivityId) {
            log.d('New activity for $persistKey: $activityId');
            state = state.copyWith(lastActivityId: activityId);
            _onActivity();
          }
        },
        onError: (error) {
          log.e('Subscription error ($persistKey): $error');
        },
      );
    } catch (e) {
      log.e('Failed to setup subscription ($persistKey): $e');
    }
  }

  void _onActivity() async {
    try {
      if (state.isLoading) return;
      await _refresh();
    } catch (e) {
      log.e('Error handling activity ($persistKey): $e');
    }
  }

  /// Fetch the first page and update state (used by subscription-triggered refreshes).
  Future<void> _refresh() async {
    final squidStatus = ref.read(squidConnectionStatusProvider);
    if (squidStatus != d.ConnectionStatus.connected) return;

    try {
      final result = await fetchPage(count: 20, cursor: null);
      if (result != null) {
        final hasNew =
            result.items.isNotEmpty && (state.items.isEmpty || _isNewer(result.items.first, state.items.first));
        if (hasNew) {
          log.i('Found new items for $persistKey');
        }

        state = state.copyWith(items: result.items, hasNextPage: result.hasNextPage, cursor: result.endCursor);
      }
    } catch (e) {
      log.e('Error refreshing $persistKey: $e');
    }
  }

  /// Override to compare timestamps. Default returns false (no comparison).
  bool _isNewer(T newItem, T existingItem) => false;

  // ── Public API ──

  /// Load the first page of items.
  Future<void> loadItems() async {
    if (_isLoadingGuard) return;
    _isLoadingGuard = true;

    try {
      await _loadItemsInner();
    } finally {
      _isLoadingGuard = false;
    }
  }

  Future<void> _loadItemsInner() async {
    final squidStatus = ref.read(squidConnectionStatusProvider);
    if (squidStatus != d.ConnectionStatus.connected) {
      state = state.copyWith(isLoading: false, error: 'No network connection');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await fetchPage(count: 20, cursor: null);
      if (result == null) {
        state = state.copyWith(items: [], isLoading: false, hasNextPage: false, cursor: null);
        return;
      }

      state = state.copyWith(
        items: result.items,
        isLoading: false,
        hasNextPage: result.hasNextPage,
        cursor: result.endCursor,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load the next page of items (pagination).
  Future<void> loadMoreItems() async {
    if (state.isLoading || !state.hasNextPage) return;

    final squidStatus = ref.read(squidConnectionStatusProvider);
    if (squidStatus != d.ConnectionStatus.connected) return;

    state = state.copyWith(isLoading: true);

    try {
      final result = await fetchPage(count: 20, cursor: state.cursor);
      if (result == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      state = state.copyWith(
        items: [...state.items, ...result.items],
        isLoading: false,
        hasNextPage: result.hasNextPage,
        cursor: result.endCursor,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Reset and reload from scratch.
  Future<void> refresh() async {
    state = PaginatedState<T>(lastActivityId: state.lastActivityId);
    await loadItems();
  }
}
