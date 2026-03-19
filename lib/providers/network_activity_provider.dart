import 'dart:async';
import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/base_paginated_provider.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/models/transaction_display_item.dart';
import 'package:gecko/providers/transaction_filters_provider.dart';
import 'package:gecko/providers/settings_provider.dart';
import 'package:gecko/models/transaction_filters.dart';
import 'package:gecko/extensions.dart';

/// Notifier for managing network-wide transaction history with UD support
class NetworkActivityNotifier extends BasePaginatedNotifier<TransactionDisplayItem> {
  @override
  String get persistKey => 'networkActivity_${ref.read(durtProvider).network.name}';

  @override
  String get itemsJsonKey => 'transactions';

  @override
  bool get watchCacheBuster => true;

  @override
  Map<String, dynamic> itemToJson(TransactionDisplayItem item) => item.toJson();

  @override
  TransactionDisplayItem itemFromJson(Map<String, dynamic> json) => TransactionDisplayItem.fromJson(json);

  @override
  Stream<String?>? createSubscription() => d.SquidService.client.subscribeNetworkActivity();

  @override
  Future<PaginatedResult<TransactionDisplayItem>?> fetchPage({required int count, String? cursor}) async {
    // Use fallback genesis time if unavailable (isMigrationTime will default to false)
    final genesisTime = await ref.read(genesisTimeProvider.future) ?? DateTime(2099);
    final includeUDs = ref.read(networkUniversalDividendsToggleProvider);

    List<TransactionDisplayItem> allTransactions = [];

    // Fetch network-wide transfers
    final transferResult = await d.SquidService.client.getNetworkActivity(number: count, cursor: cursor);

    if (transferResult != null) {
      final transferTransactions = transferResult.edges
          .map((edge) => TransactionDisplayItem.fromNetworkActivityNode(edge.node, genesisTime))
          .toList();
      allTransactions.addAll(transferTransactions);
    }

    // Fetch Universal Dividends if enabled (network-wide) - only on first page
    if (includeUDs && cursor == null) {
      final networkUDs = await _fetchNetworkUniversalDividends(genesisTime);
      allTransactions.addAll(networkUDs);
    }

    // Sort all transactions by timestamp (newest first)
    allTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (transferResult == null) {
      log.e('Network activity result is null');
      return null;
    }

    return PaginatedResult(
      items: allTransactions,
      hasNextPage: transferResult.pageInfo.hasNextPage,
      endCursor: transferResult.pageInfo.endCursor,
    );
  }

  /// Fetch network-wide Universal Dividends
  Future<List<TransactionDisplayItem>> _fetchNetworkUniversalDividends(DateTime genesisTime) async {
    try {
      final result = await d.SquidService.client.getNetworkUdHistory(number: 20);

      if (result == null) {
        return [];
      }

      return result.edges.map((edge) {
        final node = edge.node;
        final timestamp = DateTime.parse(node.timestamp.ensureUtcTimestamp());

        return TransactionDisplayItem(
          address: '', // Network view, no specific address
          amount: BigInt.parse(node.amount),
          timestamp: timestamp,
          transactionTime: timestamp,
          dateDelimiter: '',
          isMigrationTime: false,
          comment: null,
          isReceived: false, // Network view, not account-specific
          type: TransactionType.universalDividend,
          fromAddress: '', // UDs don't have a from address
          toAddress: '', // UDs don't have a specific recipient in network view
          fromUsername: null,
          toUsername: null,
        );
      }).toList();
    } catch (e) {
      log.e('Failed to fetch network UDs: $e');
      return [];
    }
  }
}

/// Provider for network activity
final networkActivityProvider = NotifierProvider<NetworkActivityNotifier, PaginatedState<TransactionDisplayItem>>(
  NetworkActivityNotifier.new,
);

/// Provider for Universal Dividends toggle in network view
final networkUniversalDividendsToggleProvider = NotifierProvider<UniversalDividendsToggleNotifier, bool>(
  UniversalDividendsToggleNotifier.new,
);

/// Server-side filtered network activity notifier
class ServerFilteredNetworkActivityNotifier extends Notifier<PaginatedState<TransactionDisplayItem>> {
  Timer? _debounceTimer;
  bool _hasActiveFilters = false;
  d.TransactionFilters? _appliedServerFilters;

  @override
  PaginatedState<TransactionDisplayItem> build() {
    ref.onDispose(() => _debounceTimer?.cancel());

    // Listen to filter changes
    ref.listen(networkFiltersProvider, (previous, next) {
      if (previous != next) {
        _debounceFilterUpdate();
      }
    });

    // React to Squid connection changes: reload when connected
    ref.listen(squidConnectionStatusProvider, (previous, next) {
      if (previous != d.ConnectionStatus.connected && next == d.ConnectionStatus.connected) {
        log.i('Squid connected - loading filtered network activity');
        _loadNetworkActivityWithFilters();
      }
    });

    // Initial load asynchronously
    Future.microtask(() => _loadNetworkActivityWithFilters());

    return const PaginatedState(isLoading: true);
  }

  /// Debounce filter updates to avoid excessive API calls
  void _debounceFilterUpdate() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _loadNetworkActivityWithFilters();
    });
  }

  /// Convert Gecko filters to Durt2 filters
  d.TransactionFilters _convertToServerFilters(TransactionFilterCriteria geckoFilters) {
    return d.TransactionFilters(
      fromAddress: geckoFilters.directionFilter?.fromAddress,
      toAddress: geckoFilters.directionFilter?.toAddress,
      commentSearch: geckoFilters.commentSearch,
      startDate: geckoFilters.dateRange.startDate,
      endDate: geckoFilters.dateRange.endDate,
      minAmount: geckoFilters.amountRange.minAmount,
      maxAmount: geckoFilters.amountRange.maxAmount,
      exactMatchAddress: geckoFilters.exactMatchAddress,
      exactMatchComment: geckoFilters.exactMatchComment,
      exactMatchDirection: geckoFilters.exactMatchDirection,
    );
  }

  /// Load network activity with current filters
  Future<void> _loadNetworkActivityWithFilters() async {
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      log.e('No network connection for filtered network activity');
      state = state.copyWith(isLoading: false, error: 'No network connection');
      return;
    }

    final geckoFilters = ref.read(networkFiltersProvider);
    _hasActiveFilters = geckoFilters.hasActiveFilters;

    // Reset state when switching filter modes to avoid cursor conflicts (like account history does)
    state = state.copyWith(isLoading: true, error: null, items: [], cursor: null);

    try {
      // Use fallback genesis time if unavailable (isMigrationTime will default to false)
      final genesisTime = await ref.read(genesisTimeProvider.future) ?? DateTime(2099);

      if (_hasActiveFilters) {
        // Use server-side filtering via Durt2 (always start fresh, no cursor)
        _appliedServerFilters = _convertToServerFilters(geckoFilters);
        final result = await d.SquidService.client.getNetworkActivityFiltered(
          number: 20,
          cursor: null,
          filters: _appliedServerFilters!,
        );

        if (result != null) {
          final displayItems = result.items
              .map((node) => TransactionDisplayItem.fromNetworkActivityNode(node, genesisTime))
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
            error: 'Failed to load filtered network activity',
          );
        }
      } else {
        // No filters: use standard efficient approach
        final baseState = ref.read(networkActivityProvider);
        state = state.copyWith(
          items: baseState.items,
          isLoading: false,
          hasNextPage: baseState.hasNextPage,
          cursor: baseState.cursor,
        );
      }
    } catch (e) {
      log.e('Error loading filtered network activity: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load more network activity (pagination)
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
      // Use fallback genesis time if unavailable (isMigrationTime will default to false)
      final genesisTime = await ref.read(genesisTimeProvider.future) ?? DateTime(2099);

      if (_hasActiveFilters && _appliedServerFilters != null) {
        // Load more with server filters (use only server-generated cursors)
        final result = await d.SquidService.client.getNetworkActivityFiltered(
          number: 20,
          cursor: state.cursor,
          filters: _appliedServerFilters!,
        );

        if (result != null) {
          final newItems = result.items
              .map((node) => TransactionDisplayItem.fromNetworkActivityNode(node, genesisTime))
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
        await ref.read(networkActivityProvider.notifier).loadMoreItems();
        final baseState = ref.read(networkActivityProvider);
        state = state.copyWith(
          items: baseState.items,
          isLoading: false,
          hasNextPage: baseState.hasNextPage,
          cursor: baseState.cursor,
        );
      }
    } catch (e) {
      log.e('Error loading more network activity: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Refresh network activity
  Future<void> refresh() async {
    state = const PaginatedState();
    await _loadNetworkActivityWithFilters();
  }
}

/// Provider for server-filtered network activity
final serverFilteredNetworkActivityProvider =
    NotifierProvider<ServerFilteredNetworkActivityNotifier, PaginatedState<TransactionDisplayItem>>(
      ServerFilteredNetworkActivityNotifier.new,
    );

/// Adaptive network activity provider that chooses between server and client filtering
final adaptiveFilteredNetworkActivityProvider = Provider<PaginatedState<TransactionDisplayItem>>((ref) {
  final filters = ref.watch(networkFiltersProvider);

  if (filters.hasActiveFilters) {
    // Use server-side filtering for complex filters
    return ref.watch(serverFilteredNetworkActivityProvider);
  } else {
    // Use existing efficient client-side provider for no filters
    return ref.watch(networkActivityProvider);
  }
});

/// Load more network transactions (adaptive)
Future<void> loadMoreNetworkTransactions(WidgetRef ref) async {
  final filters = ref.read(networkFiltersProvider);

  if (filters.hasActiveFilters) {
    await ref.read(serverFilteredNetworkActivityProvider.notifier).loadMore();
  } else {
    await ref.read(networkActivityProvider.notifier).loadMoreItems();
  }
}

/// Refresh network activity (adaptive)
Future<void> refreshNetworkActivity(WidgetRef ref) async {
  final filters = ref.read(networkFiltersProvider);

  if (filters.hasActiveFilters) {
    await ref.read(serverFilteredNetworkActivityProvider.notifier).refresh();
  } else {
    await ref.read(networkActivityProvider.notifier).refresh();
  }
}
