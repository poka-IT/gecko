import 'dart:async';
import 'dart:convert';
import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/persist_storage_provider.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/models/identity_display_item.dart';
import 'package:gecko/providers/identity_filters_provider.dart';
import 'package:gecko/models/identity_filters.dart';

/// State for network identity activity
class NetworkIdentitiesState {
  final List<IdentityDisplayItem> identities;
  final bool isLoading;
  final bool hasNextPage;
  final String? cursor;
  final String? error;
  final bool hasActiveFilters;
  final d.IdentityFilters? appliedServerFilters;
  final String? lastActivityId;

  const NetworkIdentitiesState({
    this.identities = const [],
    this.isLoading = false,
    this.hasNextPage = true,
    this.cursor,
    this.error,
    this.hasActiveFilters = false,
    this.appliedServerFilters,
    this.lastActivityId,
  });

  Map<String, dynamic> toJson() => {
    'identities': identities.map((i) => i.toJson()).toList(),
    'hasNextPage': hasNextPage,
    'cursor': cursor,
    'lastActivityId': lastActivityId,
  };

  factory NetworkIdentitiesState.fromJson(Map<String, dynamic> json) => NetworkIdentitiesState(
    identities: (json['identities'] as List)
        .map((i) => IdentityDisplayItem.fromJson(i as Map<String, dynamic>))
        .toList(),
    hasNextPage: json['hasNextPage'] as bool? ?? false,
    cursor: json['cursor'] as String?,
    lastActivityId: json['lastActivityId'] as String?,
  );

  NetworkIdentitiesState copyWith({
    List<IdentityDisplayItem>? identities,
    bool? isLoading,
    bool? hasNextPage,
    String? cursor,
    String? error,
    bool? hasActiveFilters,
    d.IdentityFilters? appliedServerFilters,
    String? lastActivityId,
  }) {
    return NetworkIdentitiesState(
      identities: identities ?? this.identities,
      isLoading: isLoading ?? this.isLoading,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      cursor: cursor ?? this.cursor,
      error: error ?? this.error,
      hasActiveFilters: hasActiveFilters ?? this.hasActiveFilters,
      appliedServerFilters: appliedServerFilters ?? this.appliedServerFilters,
      lastActivityId: lastActivityId ?? this.lastActivityId,
    );
  }
}

/// Notifier for managing network-wide identity activity
class NetworkIdentitiesNotifier extends Notifier<NetworkIdentitiesState> {
  StreamSubscription<String?>? _networkIdentitiesSubscription;
  bool _isLoadingGuard = false;

  @override
  NetworkIdentitiesState build() {
    ref.onDispose(() => _networkIdentitiesSubscription?.cancel());

    // Persist state to local SQLite DB for instant display on app restart
    final network = ref.read(durtProvider).network.name;
    persist(
      ref.watch(persistStorageProvider.future),
      key: 'networkIdentities_$network',
      encode: (state) => jsonEncode(state.toJson()),
      decode: (json) => NetworkIdentitiesState.fromJson(jsonDecode(json) as Map<String, dynamic>),
    );

    // React to Squid connection changes: reload + resubscribe when connected
    ref.listen(squidConnectionStatusProvider, (previous, next) {
      if (previous != d.ConnectionStatus.connected && next == d.ConnectionStatus.connected) {
        log.i('🔄 Squid connected - loading network identities');
        loadIdentities();
        _subscribeToNetworkIdentities();
      }
    });

    // Only start initial load if Squid is already connected;
    // otherwise the squidConnectionStatusProvider listener handles it.
    Future.microtask(() {
      final status = ref.read(squidConnectionStatusProvider);
      if (status == d.ConnectionStatus.connected) {
        loadIdentities();
        _subscribeToNetworkIdentities();
      }
    });

    // Start with isLoading: true to avoid flash of "no data" before loading starts
    return const NetworkIdentitiesState(isLoading: true);
  }

  /// Subscribe to network-wide identity activity (triggers refreshes when new identities are created)
  void _subscribeToNetworkIdentities() {
    // Cancel existing subscription before creating new one
    _networkIdentitiesSubscription?.cancel();

    // Check if we have Squid connection
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      log.w('Cannot subscribe to network identities: Squid not connected');
      return;
    }

    try {
      _networkIdentitiesSubscription = d.SquidService.client.subscribeNetworkIdentities().listen(
        (activityId) {
          if (activityId != null && activityId != state.lastActivityId) {
            state = state.copyWith(lastActivityId: activityId);
            _onNetworkIdentityActivity();
          } else if (activityId != null) {
            log.d('Received known identity activity ID: $activityId');
          }
        },
        onError: (error) {
          log.e('Network identity subscription error: $error');
        },
      );
    } catch (e) {
      log.e('Failed to setup network identity subscription: $e');
    }
  }

  /// Handle network identity activity by refreshing the identity history
  void _onNetworkIdentityActivity() async {
    try {
      // Don't refresh if we're already loading
      if (state.isLoading) {
        log.d('Skipping network identity refresh: already loading');
        return;
      }

      // Refresh the complete identity history
      await _refreshNetworkIdentities();
    } catch (e) {
      log.e('Error handling network identity activity: $e');
    }
  }

  /// Refresh network identities (used for activity-triggered updates)
  Future<void> _refreshNetworkIdentities() async {
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      log.w('Cannot refresh: Squid not connected');
      return;
    }

    try {
      // Fetch fresh network-wide identities
      final result = await d.SquidService.client.getNetworkIdentities(number: 20, cursor: null);

      if (result != null) {
        final newIdentities = result.edges
            .map((edge) => IdentityDisplayItem.fromNetworkIdentityNode(edge.node))
            .toList();

        // Check if we actually have new identities by comparing with current state
        final hasNewIdentities =
            newIdentities.isNotEmpty &&
            (state.identities.isEmpty || (newIdentities.first.timestamp.isAfter(state.identities.first.timestamp)));

        if (hasNewIdentities) {
          log.i('Found ${newIdentities.length} new network identities');
        }

        state = state.copyWith(
          identities: newIdentities,
          hasNextPage: result.pageInfo.hasNextPage,
          cursor: result.pageInfo.endCursor,
        );
      } else {
        log.w('Received null result from getNetworkIdentities');
      }
    } catch (e) {
      log.e('Error refreshing network identities: $e');
    }
  }

  /// Load the first page of network identities
  Future<void> loadIdentities() async {
    // Prevent concurrent loads
    if (_isLoadingGuard) return;
    _isLoadingGuard = true;

    try {
      await _loadIdentitiesInner();
    } finally {
      _isLoadingGuard = false;
    }
  }

  Future<void> _loadIdentitiesInner() async {
    // Check if we have Squid connection
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);

    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      state = state.copyWith(isLoading: false, error: 'No network connection');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Fetch network-wide identities
      final result = await d.SquidService.client.getNetworkIdentities(number: 20, cursor: null);

      if (result == null) {
        state = state.copyWith(identities: [], isLoading: false, hasNextPage: false, cursor: null);
        return;
      }

      final identities = result.edges.map((edge) => IdentityDisplayItem.fromNetworkIdentityNode(edge.node)).toList();

      state = state.copyWith(
        identities: identities,
        isLoading: false,
        hasNextPage: result.pageInfo.hasNextPage,
        cursor: result.pageInfo.endCursor,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load the next page of network identities
  Future<void> loadMoreIdentities() async {
    if (state.isLoading || !state.hasNextPage) return;

    // Check if we have Squid connection
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      // Fetch more network identities using cursor pagination
      final result = await d.SquidService.client.getNetworkIdentities(number: 20, cursor: state.cursor);

      if (result == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final newIdentities = result.edges.map((edge) => IdentityDisplayItem.fromNetworkIdentityNode(edge.node)).toList();

      state = state.copyWith(
        identities: [...state.identities, ...newIdentities],
        isLoading: false,
        hasNextPage: result.pageInfo.hasNextPage,
        cursor: result.pageInfo.endCursor,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresh the network identities (public method for manual refresh)
  Future<void> refresh() async {
    state = NetworkIdentitiesState(lastActivityId: state.lastActivityId);
    await loadIdentities();
  }
}

/// Server-side filtered network identities notifier
class ServerFilteredNetworkIdentitiesNotifier extends Notifier<NetworkIdentitiesState> {
  Timer? _debounceTimer;

  @override
  NetworkIdentitiesState build() {
    ref.onDispose(() => _debounceTimer?.cancel());

    // Listen to filter changes
    ref.listen(identityFiltersProvider, (previous, next) {
      if (previous != next) {
        _debounceFilterUpdate();
      }
    });

    // Initial load
    Future.microtask(() => _loadNetworkIdentitiesWithFilters());
    return const NetworkIdentitiesState();
  }

  /// Debounce filter updates to avoid excessive API calls
  void _debounceFilterUpdate() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _loadNetworkIdentitiesWithFilters();
    });
  }

  /// Convert Gecko filters to Durt2 filters
  d.IdentityFilters _convertToServerFilters(IdentityFilterCriteria geckoFilters) {
    final serverFilters = d.IdentityFilters(
      nameSearch: geckoFilters.nameSearch,
      statuses: geckoFilters.selectedStatuses,
      startDate: geckoFilters.dateRange.startDate,
      endDate: geckoFilters.dateRange.endDate,
      exactMatchName: geckoFilters.exactMatchName,
    );

    return serverFilters;
  }

  /// Load network identities with current filters
  Future<void> _loadNetworkIdentitiesWithFilters() async {
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      log.e('❌ [IDENTITY DEBUG] No network connection');
      state = state.copyWith(error: 'No network connection');
      return;
    }

    final geckoFilters = ref.read(identityFiltersProvider);
    final hasFilters = geckoFilters.hasActiveFilters;

    // Reset state when switching filter modes to avoid cursor conflicts
    state = state.copyWith(
      isLoading: true,
      error: null,
      hasActiveFilters: hasFilters,
      identities: [], // Clear existing identities when filters change
      cursor: null, // Reset cursor to avoid conflicts
    );

    try {
      if (hasFilters) {
        // Use server-side filtering via Durt2 (always start fresh, no cursor)
        final serverFilters = _convertToServerFilters(geckoFilters);
        final result = await d.SquidService.client.getNetworkIdentitiesFiltered(
          number: 20,
          cursor: null, // Always start fresh to avoid cursor conflicts
          filters: serverFilters,
        );

        if (result != null) {
          final displayItems = result.items
              .map((node) => IdentityDisplayItem.fromFilteredNetworkIdentityNode(node))
              .toList();

          state = state.copyWith(
            identities: displayItems,
            isLoading: false,
            hasNextPage: result.hasNextPage,
            cursor: result.endCursor,
            appliedServerFilters: serverFilters,
          );
        } else {
          state = state.copyWith(
            identities: [],
            isLoading: false,
            hasNextPage: false,
            error: 'Failed to load filtered network identities',
          );
        }
      } else {
        // No filters: use standard efficient approach
        final baseState = ref.read(networkIdentitiesProvider);
        state = state.copyWith(
          identities: baseState.identities,
          isLoading: false,
          hasNextPage: baseState.hasNextPage,
          cursor: baseState.cursor,
          appliedServerFilters: null, // No server filters applied
        );
      }
    } catch (e) {
      log.e('Error loading filtered network identities: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load more network identities (pagination)
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasNextPage) {
      return;
    }

    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      if (state.hasActiveFilters && state.appliedServerFilters != null) {
        // Load more with server filters (use only server-generated cursors)
        final result = await d.SquidService.client.getNetworkIdentitiesFiltered(
          number: 20,
          cursor: state.cursor, // Use the cursor from server filtering results
          filters: state.appliedServerFilters!,
        );

        if (result != null) {
          final newItems = result.items
              .map((node) => IdentityDisplayItem.fromFilteredNetworkIdentityNode(node))
              .toList();

          state = state.copyWith(
            identities: [...state.identities, ...newItems],
            isLoading: false,
            hasNextPage: result.hasNextPage,
            cursor: result.endCursor,
          );
        }
      } else {
        // Load more without filters (delegate to existing provider)
        await ref.read(networkIdentitiesProvider.notifier).loadMoreIdentities();
        final baseState = ref.read(networkIdentitiesProvider);
        state = state.copyWith(
          identities: baseState.identities,
          isLoading: false,
          hasNextPage: baseState.hasNextPage,
          cursor: baseState.cursor,
        );
      }
    } catch (e) {
      log.e('❌ Error loading more network identities: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Refresh network identities
  Future<void> refresh() async {
    state = const NetworkIdentitiesState();
    await _loadNetworkIdentitiesWithFilters();
  }
}

/// Provider for network identities
final networkIdentitiesProvider = NotifierProvider<NetworkIdentitiesNotifier, NetworkIdentitiesState>(
  NetworkIdentitiesNotifier.new,
);

/// Provider for server-filtered network identities
final serverFilteredNetworkIdentitiesProvider =
    NotifierProvider<ServerFilteredNetworkIdentitiesNotifier, NetworkIdentitiesState>(
      ServerFilteredNetworkIdentitiesNotifier.new,
    );

/// Adaptive network identities provider that chooses between server and client filtering
final adaptiveFilteredNetworkIdentitiesProvider = Provider<NetworkIdentitiesState>((ref) {
  final filters = ref.watch(identityFiltersProvider);

  if (filters.hasActiveFilters) {
    // Use server-side filtering for complex filters
    return ref.watch(serverFilteredNetworkIdentitiesProvider);
  } else {
    // Use existing efficient client-side provider for no filters
    return ref.watch(networkIdentitiesProvider);
  }
});

/// Load more network identities (adaptive)
Future<void> loadMoreNetworkIdentities(WidgetRef ref) async {
  final filters = ref.read(identityFiltersProvider);

  if (filters.hasActiveFilters) {
    await ref.read(serverFilteredNetworkIdentitiesProvider.notifier).loadMore();
  } else {
    await ref.read(networkIdentitiesProvider.notifier).loadMoreIdentities();
  }
}

/// Refresh network identities (adaptive)
Future<void> refreshNetworkIdentities(WidgetRef ref) async {
  final filters = ref.read(identityFiltersProvider);

  if (filters.hasActiveFilters) {
    await ref.read(serverFilteredNetworkIdentitiesProvider.notifier).refresh();
  } else {
    await ref.read(networkIdentitiesProvider.notifier).refresh();
  }
}
