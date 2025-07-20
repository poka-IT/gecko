import 'dart:async';
import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/transaction_display_item.dart';
import 'package:gecko/models/transaction_filters.dart';
import 'package:gecko/providers.dart';
import 'package:gecko/providers/settings_provider.dart';
import 'package:gecko/providers/transaction_filters_provider.dart';

/// Helper function to build GraphQL where clause from filter criteria
d.Input$TransferBoolExp _buildTransferWhereClause(String address, TransactionFilterCriteria filters) {
  // Base filter: transactions involving the address
  final baseFilter = d.Input$TransferBoolExp(
    $_or: [
      d.Input$TransferBoolExp(fromId: d.Input$StringComparisonExp($_eq: address)),
      d.Input$TransferBoolExp(toId: d.Input$StringComparisonExp($_eq: address)),
    ],
  );

  // If no advanced filters, return base filter
  if (!filters.hasActiveFilters) {
    return baseFilter;
  }

  // Build advanced filters
  List<d.Input$TransferBoolExp> andConditions = [baseFilter];

  // Address or name search filter
  if (filters.addressOrNameSearch?.isNotEmpty == true) {
    final searchTerm = '%${filters.addressOrNameSearch}%';
    andConditions.add(
      d.Input$TransferBoolExp(
        $_or: [
          // Search in addresses
          d.Input$TransferBoolExp(fromId: d.Input$StringComparisonExp($_ilike: searchTerm)),
          d.Input$TransferBoolExp(toId: d.Input$StringComparisonExp($_ilike: searchTerm)),
          // Search in identity names
          d.Input$TransferBoolExp(
            from: d.Input$AccountBoolExp(
              identity: d.Input$IdentityBoolExp(name: d.Input$StringComparisonExp($_ilike: searchTerm)),
            ),
          ),
          d.Input$TransferBoolExp(
            to: d.Input$AccountBoolExp(
              identity: d.Input$IdentityBoolExp(name: d.Input$StringComparisonExp($_ilike: searchTerm)),
            ),
          ),
        ],
      ),
    );
  }

  // Comment search filter
  if (filters.commentSearch?.isNotEmpty == true) {
    final commentSearchTerm = '%${filters.commentSearch}%';
    andConditions.add(
      d.Input$TransferBoolExp(
        comment: d.Input$TxCommentBoolExp(remark: d.Input$StringComparisonExp($_ilike: commentSearchTerm)),
      ),
    );
  }

  // Date range filter
  if (filters.dateRange.isActive) {
    if (filters.dateRange.startDate != null) {
      andConditions.add(
        d.Input$TransferBoolExp(
          timestamp: d.Input$TimestamptzComparisonExp($_gte: filters.dateRange.startDate!.toIso8601String()),
        ),
      );
    }
    if (filters.dateRange.endDate != null) {
      // Add one day to include the entire end date
      final endDateTime = filters.dateRange.endDate!.add(const Duration(days: 1));
      andConditions.add(
        d.Input$TransferBoolExp(timestamp: d.Input$TimestamptzComparisonExp($_lt: endDateTime.toIso8601String())),
      );
    }
  }

  // Amount range filter
  if (filters.amountRange.isActive) {
    if (filters.amountRange.minAmount != null) {
      andConditions.add(
        d.Input$TransferBoolExp(amount: d.Input$NumericComparisonExp($_gte: filters.amountRange.minAmount.toString())),
      );
    }
    if (filters.amountRange.maxAmount != null) {
      andConditions.add(
        d.Input$TransferBoolExp(amount: d.Input$NumericComparisonExp($_lte: filters.amountRange.maxAmount.toString())),
      );
    }
  }

  return d.Input$TransferBoolExp($_and: andConditions);
}

/// Extended state class for filtered transaction history with query tracking
class FilteredTransactionHistoryState {
  final List<TransactionDisplayItem> transactions;
  final bool isLoading;
  final bool hasNextPage;
  final String? error;
  final String? cursor;
  final bool isFiltered; // Track if this data is filtered

  const FilteredTransactionHistoryState({
    this.transactions = const [],
    this.isLoading = false,
    this.hasNextPage = false,
    this.error,
    this.cursor,
    this.isFiltered = false,
  });

  FilteredTransactionHistoryState copyWith({
    List<TransactionDisplayItem>? transactions,
    bool? isLoading,
    bool? hasNextPage,
    String? error,
    String? cursor,
    bool? isFiltered,
  }) {
    return FilteredTransactionHistoryState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      error: error ?? this.error,
      cursor: cursor ?? this.cursor,
      isFiltered: isFiltered ?? this.isFiltered,
    );
  }
}

/// Enhanced StateNotifier that handles both UD toggle and advanced filters with fresh queries
class FilteredTransactionHistoryNotifier extends StateNotifier<FilteredTransactionHistoryState> {
  final Ref ref;
  final String address;
  StreamSubscription<String?>? _activitySubscription;
  String? _lastSeenTransactionId;

  FilteredTransactionHistoryNotifier(this.ref, this.address) : super(const FilteredTransactionHistoryState()) {
    loadTransactions();
    _subscribeToAccountActivity();
  }

  /// Subscribe to account activity
  void _subscribeToAccountActivity() {
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      log.w('Cannot subscribe to account activity: Squid not connected');
      return;
    }

    try {
      _activitySubscription = d.SquidService.client
          .subscribeAccountActivity(address)
          .listen(
            (transactionId) {
              if (transactionId != null && transactionId != _lastSeenTransactionId) {
                _lastSeenTransactionId = transactionId;
                _onAccountActivity();
              } else if (transactionId != null) {
                log.d('Received known transaction ID: $transactionId');
              }
            },
            onError: (error) {
              log.e('Activity subscription error: $error');
            },
          );
    } catch (e) {
      log.e('Failed to setup activity subscription: $e');
    }
  }

  /// Handle account activity by refreshing the transaction history
  void _onAccountActivity() async {
    try {
      await _refreshTransactionHistory();
    } catch (e) {
      log.e('Error handling account activity: $e');
    }
  }

  /// Refresh transaction history (used for activity-triggered updates)
  Future<void> _refreshTransactionHistory() async {
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      log.w('Cannot refresh: Squid not connected');
      return;
    }

    try {
      final genesisTime = await ref.read(genesisTimeProvider.future);
      final includeUD = ref.read(universalDividendsToggleProvider);
      final filters = ref.read(transactionFiltersProvider);

      List<TransactionDisplayItem> newTransactions;

      if (filters.hasActiveFilters) {
        // Use the new filtered GraphQL query for refresh as well
        final whereClause = _buildTransferWhereClause(address, filters);
        final result = await d.SquidService.client.getFilteredAccountHistory(
          number: 100,
          cursor: null,
          where: whereClause,
        );

        if (result != null) {
          newTransactions = result.edges
              .map((edge) => TransactionDisplayItem.fromFilteredGraphQLNode(edge.node, address, genesisTime))
              .toList();
        } else {
          newTransactions = [];
        }
      } else {
        // No advanced filters, use normal pagination
        if (includeUD) {
          final result = await d.SquidService.client.getCombinedAccountHistory(
            address,
            number: 20,
            cursor: null,
            includeUniversalDividends: true,
            beforeTimestamp: null,
          );

          if (result != null) {
            newTransactions = result.items
                .map((item) => _convertGraphQLItemToTransaction(item, genesisTime))
                .whereType<TransactionDisplayItem>()
                .toList();
          } else {
            newTransactions = [];
          }
        } else {
          final result = await d.SquidService.client.getAccountHistory(address, number: 20, cursor: null);

          if (result != null) {
            newTransactions = result.edges
                .map((edge) => TransactionDisplayItem.fromGraphQLNode(edge.node, address, genesisTime))
                .toList();
          } else {
            newTransactions = [];
          }
        }
      }

      // Check if we actually have new transactions
      final hasNewTransactions =
          newTransactions.isNotEmpty &&
          (state.transactions.isEmpty || (newTransactions.first.timestamp.isAfter(state.transactions.first.timestamp)));

      if (hasNewTransactions) {
        log.i('Found ${newTransactions.length} new filtered transactions');
      }

      state = state.copyWith(
        transactions: newTransactions,
        hasNextPage: !filters.hasActiveFilters, // No pagination when filtering
        cursor: filters.hasActiveFilters ? null : 'loaded',
        isFiltered: filters.hasActiveFilters,
      );

      // Update last seen transaction ID with the most recent one
      if (newTransactions.isNotEmpty) {
        _lastSeenTransactionId = _generateTransactionId(newTransactions.first);
      }
    } catch (e) {
      log.e('Error refreshing filtered history: $e');
    }
  }

  /// Convert GraphQL item to TransactionDisplayItem
  TransactionDisplayItem? _convertGraphQLItemToTransaction(dynamic item, DateTime genesisTime) {
    if (item is d.Query$GetAccountHistory$transferConnection$edges$node) {
      return TransactionDisplayItem.fromGraphQLNode(item, address, genesisTime);
    } else if (item is d.Query$GetUdHistoryViaIdentity$identityConnection$edges$node$udHistory) {
      return TransactionDisplayItem.fromUdHistoryNode(item, address, genesisTime);
    } else {
      log.e('Unknown item type in combined history: ${item.runtimeType}');
      return null;
    }
  }

  /// Generate a consistent transaction ID from transaction data
  String _generateTransactionId(TransactionDisplayItem transaction) {
    return '${transaction.timestamp.millisecondsSinceEpoch}_${transaction.amount}_${transaction.isReceived}_${transaction.type.name}';
  }

  /// Load transactions with current filter state
  Future<void> loadTransactions() async {
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);

    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      state = state.copyWith(error: 'No network connection');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final genesisTime = await ref.read(genesisTimeProvider.future);
      final includeUD = ref.read(universalDividendsToggleProvider);
      final filters = ref.read(transactionFiltersProvider);

      List<TransactionDisplayItem> transactions;
      bool hasNextPage = true;
      String? cursor;

      if (filters.hasActiveFilters) {
        // Use the new filtered GraphQL query
        final whereClause = _buildTransferWhereClause(address, filters);
        final result = await d.SquidService.client.getFilteredAccountHistory(
          number: 100, // Fetch more when filtering to ensure good results
          cursor: null,
          where: whereClause,
        );

        if (result == null) {
          transactions = [];
          hasNextPage = false;
          cursor = null;
        } else {
          transactions = result.edges
              .map((edge) => TransactionDisplayItem.fromFilteredGraphQLNode(edge.node, address, genesisTime))
              .toList();
          hasNextPage = result.pageInfo.hasNextPage;
          cursor = result.pageInfo.endCursor;
        }
      } else {
        // No advanced filters, use normal pagination
        if (includeUD) {
          final result = await d.SquidService.client.getCombinedAccountHistory(
            address,
            number: 20,
            cursor: null,
            includeUniversalDividends: true,
            beforeTimestamp: null,
          );

          if (result == null) {
            transactions = [];
            hasNextPage = false;
            cursor = null;
          } else {
            transactions = result.items
                .map((item) => _convertGraphQLItemToTransaction(item, genesisTime))
                .whereType<TransactionDisplayItem>()
                .toList();
            hasNextPage = result.hasNextPage;
            cursor = result.endCursor;
          }
        } else {
          final result = await d.SquidService.client.getAccountHistory(address, number: 20, cursor: null);

          if (result == null) {
            transactions = [];
            hasNextPage = false;
            cursor = null;
          } else {
            transactions = result.edges
                .map((edge) => TransactionDisplayItem.fromGraphQLNode(edge.node, address, genesisTime))
                .toList();
            hasNextPage = result.pageInfo.hasNextPage;
            cursor = result.pageInfo.endCursor;
          }
        }
      }

      // Store the most recent transaction ID for activity detection
      if (transactions.isNotEmpty) {
        _lastSeenTransactionId = _generateTransactionId(transactions.first);
      }

      state = state.copyWith(
        transactions: transactions,
        isLoading: false,
        hasNextPage: hasNextPage,
        cursor: cursor,
        isFiltered: filters.hasActiveFilters,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load more transactions (only available when not filtering)
  Future<void> loadMoreTransactions() async {
    if (state.isLoading || !state.hasNextPage || state.isFiltered) return;

    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final genesisTime = await ref.read(genesisTimeProvider.future);
      final includeUD = ref.read(universalDividendsToggleProvider);

      List<TransactionDisplayItem> newTransactions;

      if (includeUD) {
        // Convert cursor (timestamp string) to DateTime for pagination
        DateTime? beforeTimestamp;
        if (state.cursor != null) {
          try {
            beforeTimestamp = state.cursor!.endsWith('Z') || state.cursor!.contains('+') || state.cursor!.contains('-')
                ? DateTime.parse(state.cursor!)
                : DateTime.parse('${state.cursor!}Z');
          } catch (e) {
            log.e('Error parsing cursor timestamp: ${state.cursor}');
          }
        }

        final result = await d.SquidService.client.getCombinedAccountHistory(
          address,
          number: 20,
          cursor: null,
          includeUniversalDividends: true,
          beforeTimestamp: beforeTimestamp,
        );

        if (result == null) {
          state = state.copyWith(isLoading: false);
          return;
        }

        newTransactions = result.items
            .map((item) => _convertGraphQLItemToTransaction(item, genesisTime))
            .whereType<TransactionDisplayItem>()
            .toList();

        state = state.copyWith(
          transactions: [...state.transactions, ...newTransactions],
          isLoading: false,
          hasNextPage: result.hasNextPage,
          cursor: result.endCursor,
        );
      } else {
        final result = await d.SquidService.client.getAccountHistory(address, number: 20, cursor: state.cursor);

        if (result == null) {
          state = state.copyWith(isLoading: false);
          return;
        }

        newTransactions = result.edges
            .map((edge) => TransactionDisplayItem.fromGraphQLNode(edge.node, address, genesisTime))
            .toList();

        state = state.copyWith(
          transactions: [...state.transactions, ...newTransactions],
          isLoading: false,
          hasNextPage: result.pageInfo.hasNextPage,
          cursor: result.pageInfo.endCursor,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresh the transaction history (public method for manual refresh)
  Future<void> refresh() async {
    state = const FilteredTransactionHistoryState();
    await loadTransactions();
  }

  /// Reload data when filters change
  Future<void> onFiltersChanged() async {
    log.i('🔍 Filters changed, reloading data for $address');
    await refresh();
  }

  @override
  void dispose() {
    _activitySubscription?.cancel();
    super.dispose();
  }
}

/// Provider for enhanced filtered transaction history with query-level filtering
final enhancedFilteredTransactionHistoryProvider =
    StateNotifierProvider.family<FilteredTransactionHistoryNotifier, FilteredTransactionHistoryState, String>((
      ref,
      address,
    ) {
      final notifier = FilteredTransactionHistoryNotifier(ref, address);

      // Listen to filter changes and reload data
      ref.listen<TransactionFilterCriteria>(transactionFiltersProvider, (previous, current) {
        if (previous != current) {
          notifier.onFiltersChanged();
        }
      });

      // Listen to UD toggle changes and reload data
      ref.listen<bool>(universalDividendsToggleProvider, (previous, current) {
        if (previous != current) {
          notifier.onFiltersChanged();
        }
      });

      return notifier;
    });

/// Helper functions for filtered transaction management

/// Refresh filtered transaction history
Future<void> refreshFilteredTransactionHistory(WidgetRef ref, String address) async {
  await ref.read(enhancedFilteredTransactionHistoryProvider(address).notifier).refresh();
}

/// Load more filtered transactions
Future<void> loadMoreFilteredTransactions(WidgetRef ref, String address) async {
  await ref.read(enhancedFilteredTransactionHistoryProvider(address).notifier).loadMoreTransactions();
}
