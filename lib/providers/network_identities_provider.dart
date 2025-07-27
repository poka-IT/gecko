import 'dart:async';
import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers.dart';
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

  const NetworkIdentitiesState({
    this.identities = const [],
    this.isLoading = false,
    this.hasNextPage = true,
    this.cursor,
    this.error,
    this.hasActiveFilters = false,
    this.appliedServerFilters,
  });

  NetworkIdentitiesState copyWith({
    List<IdentityDisplayItem>? identities,
    bool? isLoading,
    bool? hasNextPage,
    String? cursor,
    String? error,
    bool? hasActiveFilters,
    d.IdentityFilters? appliedServerFilters,
  }) {
    return NetworkIdentitiesState(
      identities: identities ?? this.identities,
      isLoading: isLoading ?? this.isLoading,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      cursor: cursor ?? this.cursor,
      error: error ?? this.error,
      hasActiveFilters: hasActiveFilters ?? this.hasActiveFilters,
      appliedServerFilters: appliedServerFilters ?? this.appliedServerFilters,
    );
  }
}

/// StateNotifier for managing network-wide identity activity
class NetworkIdentitiesNotifier extends StateNotifier<NetworkIdentitiesState> {
  final Ref ref;
  StreamSubscription<String?>? _networkIdentitiesSubscription;
  String? _lastSeenIdentityId;

  NetworkIdentitiesNotifier(this.ref) : super(const NetworkIdentitiesState()) {
    loadIdentities();
    _subscribeToNetworkIdentities();
  }

  /// Subscribe to network-wide identity activity (triggers refreshes when new identities are created)
  void _subscribeToNetworkIdentities() {
    // Check if we have Squid connection
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      log.w('Cannot subscribe to network identities: Squid not connected');
      return;
    }

    try {
      _networkIdentitiesSubscription = d.SquidService.client.subscribeNetworkIdentities().listen(
        (identityId) {
          if (identityId != null && identityId != _lastSeenIdentityId) {
            _lastSeenIdentityId = identityId;
            _onNetworkIdentityActivity();
          } else if (identityId != null) {
            log.d('Received known identity ID: $identityId');
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

        // Update last seen identity ID with the most recent one
        if (newIdentities.isNotEmpty) {
          _lastSeenIdentityId = _generateIdentityId(newIdentities.first);
        }
      } else {
        log.w('Received null result from getNetworkIdentities');
      }
    } catch (e) {
      log.e('Error refreshing network identities: $e');
    }
  }

  /// Generate a consistent identity ID from identity data
  String _generateIdentityId(IdentityDisplayItem identity) {
    return '${identity.name}_${identity.timestamp.millisecondsSinceEpoch}_${identity.status.name}';
  }

  /// Load the first page of network identities
  Future<void> loadIdentities() async {
    // Check if we have Squid connection
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);

    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      state = state.copyWith(error: 'No network connection');
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

      // Store the most recent identity ID for activity detection
      if (identities.isNotEmpty) {
        _lastSeenIdentityId = _generateIdentityId(identities.first);
      }
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
    state = const NetworkIdentitiesState();
    await loadIdentities();
  }

  @override
  void dispose() {
    _networkIdentitiesSubscription?.cancel();
    super.dispose();
  }
}

/// Server-side filtered network identities notifier
class ServerFilteredNetworkIdentitiesNotifier extends StateNotifier<NetworkIdentitiesState> {
  final Ref ref;
  Timer? _debounceTimer;

  ServerFilteredNetworkIdentitiesNotifier(this.ref) : super(const NetworkIdentitiesState()) {
    // Listen to filter changes
    ref.listen(identityFiltersProvider, (previous, next) {
      if (previous != next) {
        _debounceFilterUpdate();
      }
    });

    // Initial load
    _loadNetworkIdentitiesWithFilters();
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
      // ignore: avoid_print
      print('❌ [IDENTITY DEBUG] No network connection');
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
      // ignore: avoid_print
      print('❌ [IDENTITY DEBUG] Error in loadMore: $e');
      log.e('Error loading more network identities: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Refresh network identities
  Future<void> refresh() async {
    state = const NetworkIdentitiesState();
    await _loadNetworkIdentitiesWithFilters();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

/// Provider for network identities
final networkIdentitiesProvider = StateNotifierProvider<NetworkIdentitiesNotifier, NetworkIdentitiesState>((ref) {
  return NetworkIdentitiesNotifier(ref);
});

/// Provider for server-filtered network identities
final serverFilteredNetworkIdentitiesProvider =
    StateNotifierProvider<ServerFilteredNetworkIdentitiesNotifier, NetworkIdentitiesState>((ref) {
      return ServerFilteredNetworkIdentitiesNotifier(ref);
    });

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
