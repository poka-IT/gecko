import 'dart:async';
import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/transaction_display_item.dart';
import 'package:gecko/models/transaction_filters.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/settings_provider.dart';
import 'package:gecko/providers/transaction_history_providers.dart';
import 'package:gecko/providers/transaction_filters_provider.dart';
import 'package:gecko/providers/providers.dart';

/// State for server-filtered transaction history
class ServerFilteredHistoryState {
  final List<TransactionDisplayItem> transactions;
  final bool isLoading;
  final bool hasNextPage;
  final String? cursor;
  final String? error;
  final bool hasActiveFilters;
  final d.TransactionFilters? appliedServerFilters;

  const ServerFilteredHistoryState({
    this.transactions = const [],
    this.isLoading = false,
    this.hasNextPage = true,
    this.cursor,
    this.error,
    this.hasActiveFilters = false,
    this.appliedServerFilters,
  });

  ServerFilteredHistoryState copyWith({
    List<TransactionDisplayItem>? transactions,
    bool? isLoading,
    bool? hasNextPage,
    String? cursor,
    String? error,
    bool? hasActiveFilters,
    d.TransactionFilters? appliedServerFilters,
  }) {
    return ServerFilteredHistoryState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      cursor: cursor ?? this.cursor,
      error: error ?? this.error,
      hasActiveFilters: hasActiveFilters ?? this.hasActiveFilters,
      appliedServerFilters: appliedServerFilters ?? this.appliedServerFilters,
    );
  }
}

/// StateNotifier for server-side filtered transaction history
class ServerFilteredHistoryNotifier extends StateNotifier<ServerFilteredHistoryState> {
  final Ref ref;
  final String address;
  Timer? _debounceTimer;

  ServerFilteredHistoryNotifier(this.ref, this.address) : super(const ServerFilteredHistoryState()) {
    // Listen to filter changes
    ref.listen(transactionFiltersProvider, (previous, next) {
      if (previous != next) {
        _debounceFilterUpdate();
      }
    });

    // Initial load
    _loadTransactionsWithFilters();
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
    final serverFilters = d.TransactionFilters(
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

    return serverFilters;
  }

  /// Load transactions with current filters
  Future<void> _loadTransactionsWithFilters() async {
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      // ignore: avoid_print
      print('❌ [GECKO DEBUG] No network connection');
      state = state.copyWith(error: 'No network connection');
      return;
    }

    final geckoFilters = ref.read(transactionFiltersProvider);
    final hasFilters = geckoFilters.hasActiveFilters;

    // Reset state when switching filter modes to avoid cursor conflicts
    state = state.copyWith(
      isLoading: true,
      error: null,
      hasActiveFilters: hasFilters,
      transactions: [], // Clear existing transactions when filters change
      cursor: null, // Reset cursor to avoid conflicts
    );

    try {
      final genesisTime = await ref.read(genesisTimeProvider.future);

      if (hasFilters) {
        // Use server-side filtering via Durt2 (always start fresh, no cursor)
        final serverFilters = _convertToServerFilters(geckoFilters);
        final result = await d.SquidService.client.getAccountHistoryFiltered(
          address,
          number: 20,
          cursor: null, // Always start fresh to avoid cursor conflicts
          filters: serverFilters,
        );

        if (result != null) {
          final displayItems = result.items
              .map((node) => TransactionDisplayItem.fromFilteredGraphQLNode(node, address, genesisTime))
              .toList();

          state = state.copyWith(
            transactions: displayItems,
            isLoading: false,
            hasNextPage: result.hasNextPage,
            cursor: result.endCursor,
            appliedServerFilters: serverFilters,
          );
        } else {
          state = state.copyWith(
            transactions: [],
            isLoading: false,
            hasNextPage: false,
            error: 'Failed to load filtered transactions',
          );
        }
      } else {
        // No filters: use standard efficient approach
        final baseState = ref.read(transactionHistoryProvider(address));
        state = state.copyWith(
          transactions: baseState.transactions,
          isLoading: false,
          hasNextPage: baseState.hasNextPage,
          cursor: baseState.cursor,
          appliedServerFilters: null,
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

      if (state.hasActiveFilters && state.appliedServerFilters != null) {
        // Load more with server filters (use only server-generated cursors)
        final result = await d.SquidService.client.getAccountHistoryFiltered(
          address,
          number: 20,
          cursor: state.cursor, // Use the cursor from server filtering results
          filters: state.appliedServerFilters!,
        );

        if (result != null) {
          final newItems = result.items
              .map((node) => TransactionDisplayItem.fromFilteredGraphQLNode(node, address, genesisTime))
              .toList();

          state = state.copyWith(
            transactions: [...state.transactions, ...newItems],
            isLoading: false,
            hasNextPage: result.hasNextPage,
            cursor: result.endCursor,
          );
        }
      } else {
        // Load more without filters (delegate to existing providers)
        final includeUD = ref.read(universalDividendsToggleProvider);
        if (includeUD) {
          await ref.read(combinedHistoryProvider(address).notifier).loadMoreTransactions();
        } else {
          await ref.read(transfersOnlyHistoryProvider(address).notifier).loadMoreTransactions();
        }

        final baseState = ref.read(transactionHistoryProvider(address));
        state = state.copyWith(
          transactions: baseState.transactions,
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
    state = const ServerFilteredHistoryState();
    await _loadTransactionsWithFilters();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

/// Provider for server-filtered transaction history
final serverFilteredHistoryProvider =
    StateNotifierProvider.family<ServerFilteredHistoryNotifier, ServerFilteredHistoryState, String>((ref, address) {
      return ServerFilteredHistoryNotifier(ref, address);
    });
