import 'dart:async';
import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/base_paginated_provider.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/models/identity_display_item.dart';
import 'package:gecko/providers/identity_filters_provider.dart';
import 'package:gecko/models/identity_filters.dart';

/// Notifier for managing network-wide identity activity
class NetworkIdentitiesNotifier extends BasePaginatedNotifier<IdentityDisplayItem> {
  @override
  String get persistKey => 'networkIdentities_${ref.read(durtProvider).network.name}';

  @override
  String get itemsJsonKey => 'identities';

  @override
  Map<String, dynamic> itemToJson(IdentityDisplayItem item) => item.toJson();

  @override
  IdentityDisplayItem itemFromJson(Map<String, dynamic> json) => IdentityDisplayItem.fromJson(json);

  @override
  Stream<String?>? createSubscription() => d.SquidService.client.subscribeNetworkIdentities();

  @override
  Future<PaginatedResult<IdentityDisplayItem>?> fetchPage({required int count, String? cursor}) async {
    final result = await d.SquidService.client.getNetworkIdentities(number: count, cursor: cursor);
    if (result == null) return null;

    final items = result.edges.map((edge) => IdentityDisplayItem.fromNetworkIdentityNode(edge.node)).toList();

    return PaginatedResult(
      items: items,
      hasNextPage: result.pageInfo.hasNextPage,
      endCursor: result.pageInfo.endCursor,
    );
  }
}

/// Server-side filtered network identities notifier
class ServerFilteredNetworkIdentitiesNotifier extends Notifier<PaginatedState<IdentityDisplayItem>> {
  Timer? _debounceTimer;
  bool _hasActiveFilters = false;
  d.IdentityFilters? _appliedServerFilters;

  @override
  PaginatedState<IdentityDisplayItem> build() {
    ref.onDispose(() => _debounceTimer?.cancel());

    // Listen to filter changes
    ref.listen(identityFiltersProvider, (previous, next) {
      if (previous != next) {
        _debounceFilterUpdate();
      }
    });

    // Initial load
    Future.microtask(() => _loadNetworkIdentitiesWithFilters());
    return const PaginatedState(isLoading: true);
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
    return d.IdentityFilters(
      nameSearch: geckoFilters.nameSearch,
      statuses: geckoFilters.selectedStatuses,
      startDate: geckoFilters.dateRange.startDate,
      endDate: geckoFilters.dateRange.endDate,
      exactMatchName: geckoFilters.exactMatchName,
    );
  }

  /// Load network identities with current filters
  Future<void> _loadNetworkIdentitiesWithFilters() async {
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      log.e('No network connection for filtered identities');
      state = state.copyWith(error: 'No network connection');
      return;
    }

    final geckoFilters = ref.read(identityFiltersProvider);
    _hasActiveFilters = geckoFilters.hasActiveFilters;

    // Reset state when switching filter modes to avoid cursor conflicts
    state = state.copyWith(isLoading: true, error: null, items: [], cursor: null);

    try {
      if (_hasActiveFilters) {
        // Use server-side filtering via Durt2 (always start fresh, no cursor)
        _appliedServerFilters = _convertToServerFilters(geckoFilters);
        final result = await d.SquidService.client.getNetworkIdentitiesFiltered(
          number: 20,
          cursor: null,
          filters: _appliedServerFilters!,
        );

        if (result != null) {
          final displayItems = result.items
              .map((node) => IdentityDisplayItem.fromFilteredNetworkIdentityNode(node))
              .toList();

          state = state.copyWith(
            items: displayItems,
            isLoading: false,
            hasNextPage: result.hasNextPage,
            cursor: result.endCursor,
          );
        } else {
          state = state.copyWith(
            items: [],
            isLoading: false,
            hasNextPage: false,
            error: 'Failed to load filtered network identities',
          );
        }
      } else {
        // No filters: use standard efficient approach
        final baseState = ref.read(networkIdentitiesProvider);
        state = state.copyWith(
          items: baseState.items,
          isLoading: false,
          hasNextPage: baseState.hasNextPage,
          cursor: baseState.cursor,
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
      if (_hasActiveFilters && _appliedServerFilters != null) {
        // Load more with server filters (use only server-generated cursors)
        final result = await d.SquidService.client.getNetworkIdentitiesFiltered(
          number: 20,
          cursor: state.cursor,
          filters: _appliedServerFilters!,
        );

        if (result != null) {
          final newItems = result.items
              .map((node) => IdentityDisplayItem.fromFilteredNetworkIdentityNode(node))
              .toList();

          state = state.copyWith(
            items: [...state.items, ...newItems],
            isLoading: false,
            hasNextPage: result.hasNextPage,
            cursor: result.endCursor,
          );
        }
      } else {
        // Load more without filters (delegate to existing provider)
        await ref.read(networkIdentitiesProvider.notifier).loadMoreItems();
        final baseState = ref.read(networkIdentitiesProvider);
        state = state.copyWith(
          items: baseState.items,
          isLoading: false,
          hasNextPage: baseState.hasNextPage,
          cursor: baseState.cursor,
        );
      }
    } catch (e) {
      log.e('Error loading more network identities: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Refresh network identities
  Future<void> refresh() async {
    state = const PaginatedState();
    await _loadNetworkIdentitiesWithFilters();
  }
}

/// Provider for network identities
final networkIdentitiesProvider = NotifierProvider<NetworkIdentitiesNotifier, PaginatedState<IdentityDisplayItem>>(
  NetworkIdentitiesNotifier.new,
);

/// Provider for server-filtered network identities
final serverFilteredNetworkIdentitiesProvider =
    NotifierProvider<ServerFilteredNetworkIdentitiesNotifier, PaginatedState<IdentityDisplayItem>>(
      ServerFilteredNetworkIdentitiesNotifier.new,
    );

/// Adaptive network identities provider that chooses between server and client filtering
final adaptiveFilteredNetworkIdentitiesProvider = Provider<PaginatedState<IdentityDisplayItem>>((ref) {
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
    await ref.read(networkIdentitiesProvider.notifier).loadMoreItems();
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
