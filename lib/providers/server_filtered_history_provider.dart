import 'dart:async';
import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/transaction_display_item.dart';
import 'package:gecko/models/transaction_filters.dart';
import 'package:gecko/providers/base_paginated_provider.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/settings_provider.dart';
import 'package:gecko/providers/transaction_history_providers.dart';
import 'package:gecko/providers/transaction_filters_provider.dart';
import 'package:gecko/providers/providers.dart';

/// Notifier for server-side filtered transaction history
class ServerFilteredHistoryNotifier extends Notifier<PaginatedState<TransactionDisplayItem>> {
  ServerFilteredHistoryNotifier(this._address);
  final String _address;

  Timer? _debounceTimer;
  bool _hasActiveFilters = false;
  d.TransactionFilters? _appliedServerFilters;

  String get address => _address;

  @override
  PaginatedState<TransactionDisplayItem> build() {
    ref.onDispose(() => _debounceTimer?.cancel());

    // Listen to filter changes
    ref.listen(transactionFiltersProvider, (previous, next) {
      if (previous != next) {
        _debounceFilterUpdate();
      }
    });

    // Initial load asynchronously
    Future.microtask(() => _loadTransactionsWithFilters());

    // Start with isLoading: true to avoid flash of "no data" before loading starts
    return const PaginatedState(isLoading: true);
  }

  /// Debounce filter updates to avoid excessive API calls
  void _debounceFilterUpdate() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _loadTransactionsWithFilters();
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
      addresses: geckoFilters.addressOrNameSearch?.isNotEmpty == true ? [geckoFilters.addressOrNameSearch!] : null,
      exactMatchAddress: geckoFilters.exactMatchAddress,
      exactMatchComment: geckoFilters.exactMatchComment,
      exactMatchDirection: geckoFilters.exactMatchDirection,
    );
  }

  /// Load transactions with current filters
  Future<void> _loadTransactionsWithFilters() async {
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      log.e('No network connection for filtered transactions');
      state = state.copyWith(error: 'No network connection');
      return;
    }

    final geckoFilters = ref.read(transactionFiltersProvider);
    _hasActiveFilters = geckoFilters.hasActiveFilters;

    // Reset state when switching filter modes to avoid cursor conflicts
    state = state.copyWith(isLoading: true, error: null, items: [], cursor: null);

    try {
      final genesisTime = await ref.read(genesisTimeProvider.future);
      if (genesisTime == null) {
        state = state.copyWith(isLoading: false, error: 'Storage not ready');
        return;
      }

      if (_hasActiveFilters) {
        // Use server-side filtering via Durt2 (always start fresh, no cursor)
        _appliedServerFilters = _convertToServerFilters(geckoFilters);
        final result = await d.SquidService.client.getAccountHistoryFiltered(
          address,
          number: 20,
          cursor: null,
          filters: _appliedServerFilters!,
        );

        if (result != null) {
          final displayItems = result.items
              .map((node) => TransactionDisplayItem.fromFilteredGraphQLNode(node, address, genesisTime))
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
            error: 'Failed to load filtered transactions',
          );
        }
      } else {
        // No filters: use standard efficient approach
        final baseState = ref.read(transactionHistoryProvider(address));
        state = state.copyWith(
          items: baseState.items,
          isLoading: false,
          hasNextPage: baseState.hasNextPage,
          cursor: baseState.cursor,
        );
      }
    } catch (e) {
      log.e('Error loading filtered transactions: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load more transactions (pagination)
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
      final genesisTime = await ref.read(genesisTimeProvider.future);
      if (genesisTime == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      if (_hasActiveFilters && _appliedServerFilters != null) {
        // Load more with server filters (use only server-generated cursors)
        final result = await d.SquidService.client.getAccountHistoryFiltered(
          address,
          number: 20,
          cursor: state.cursor,
          filters: _appliedServerFilters!,
        );

        if (result != null) {
          final newItems = result.items
              .map((node) => TransactionDisplayItem.fromFilteredGraphQLNode(node, address, genesisTime))
              .toList();

          state = state.copyWith(
            items: [...state.items, ...newItems],
            isLoading: false,
            hasNextPage: result.hasNextPage,
            cursor: result.endCursor,
          );
        }
      } else {
        // Load more without filters (delegate to existing providers)
        final includeUD = ref.read(universalDividendsToggleProvider);
        if (includeUD) {
          await ref.read(combinedHistoryProvider(address).notifier).loadMoreItems();
        } else {
          await ref.read(transfersOnlyHistoryProvider(address).notifier).loadMoreItems();
        }

        final baseState = ref.read(transactionHistoryProvider(address));
        state = state.copyWith(
          items: baseState.items,
          isLoading: false,
          hasNextPage: baseState.hasNextPage,
          cursor: baseState.cursor,
        );
      }
    } catch (e) {
      log.e('Error loading more transactions: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Refresh transactions
  Future<void> refresh() async {
    state = const PaginatedState();
    await _loadTransactionsWithFilters();
  }
}

/// Provider for server-filtered transaction history
final serverFilteredHistoryProvider =
    NotifierProvider.family<ServerFilteredHistoryNotifier, PaginatedState<TransactionDisplayItem>, String>(
      (address) => ServerFilteredHistoryNotifier(address),
    );
