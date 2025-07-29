// ignore_for_file: avoid_print

import 'dart:async';
import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/transaction_display_item.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers_deprecated/settings_provider.dart';
import 'package:gecko/providers/transaction_filters_provider.dart';
import 'package:gecko/providers/server_filtered_history_provider.dart';

/// State class for transaction history
class TransactionHistoryState {
  final List<TransactionDisplayItem> transactions;
  final bool isLoading;
  final bool hasNextPage;
  final String? error;
  final String? cursor;

  const TransactionHistoryState({
    this.transactions = const [],
    this.isLoading = false,
    this.hasNextPage = false,
    this.error,
    this.cursor,
  });

  TransactionHistoryState copyWith({
    List<TransactionDisplayItem>? transactions,
    bool? isLoading,
    bool? hasNextPage,
    String? error,
    String? cursor,
  }) {
    return TransactionHistoryState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      error: error ?? this.error,
      cursor: cursor ?? this.cursor,
    );
  }
}

/// StateNotifier for managing transfers-only transaction history
class TransfersOnlyHistoryNotifier extends StateNotifier<TransactionHistoryState> {
  final Ref ref;
  final String address;
  StreamSubscription<String?>? _activitySubscription;
  String? _lastSeenTransactionId;

  TransfersOnlyHistoryNotifier(this.ref, this.address) : super(const TransactionHistoryState()) {
    loadTransactions();
    _subscribeToAccountActivity();
  }

  /// Subscribe to account activity (simple subscription that triggers refreshes)
  void _subscribeToAccountActivity() {
    // Check if we have Squid connection
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
                print('New activity detected for $address: $transactionId (previous: $_lastSeenTransactionId)');
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
      // Refresh the complete transaction history
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

      print('🔄 Fetching fresh transfers-only data for $address');

      // Fetch only transfers (simple pagination)
      final result = await d.SquidService.client.getAccountHistory(address, number: 20, cursor: null);

      if (result != null) {
        final newTransactions = result.edges
            .map((edge) => TransactionDisplayItem.fromGraphQLNode(edge.node, address, genesisTime))
            .toList();

        // Check if we actually have new transactions by comparing with current state
        final hasNewTransactions =
            newTransactions.isNotEmpty &&
            (state.transactions.isEmpty ||
                (newTransactions.first.timestamp.isAfter(state.transactions.first.timestamp)));

        if (hasNewTransactions) {
          log.i('Found ${newTransactions.length} new transfers');
        }

        state = state.copyWith(
          transactions: newTransactions,
          hasNextPage: result.pageInfo.hasNextPage,
          cursor: result.pageInfo.endCursor,
        );

        // Update last seen transaction ID with the most recent one
        if (newTransactions.isNotEmpty) {
          _lastSeenTransactionId = _generateTransactionId(newTransactions.first);
        }
      } else {
        log.w('Received null result from getAccountHistory');
      }
    } catch (e) {
      log.e('Error refreshing transfers-only history: $e');
    }
  }

  /// Generate a consistent transaction ID from transaction data
  String _generateTransactionId(TransactionDisplayItem transaction) {
    return '${transaction.timestamp.millisecondsSinceEpoch}_${transaction.amount}_${transaction.isReceived}_${transaction.type.name}';
  }

  /// Load the first page of transfers
  Future<void> loadTransactions() async {
    // Check if we have Squid connection specifically (required for transaction history)
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);

    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      state = state.copyWith(error: 'No network connection');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final genesisTime = await ref.read(genesisTimeProvider.future);

      // Fetch only transfers (simple pagination)
      final result = await d.SquidService.client.getAccountHistory(address, number: 20, cursor: null);

      if (result == null) {
        state = state.copyWith(transactions: [], isLoading: false, hasNextPage: false, cursor: null);
        return;
      }

      final transactions = result.edges
          .map((edge) => TransactionDisplayItem.fromGraphQLNode(edge.node, address, genesisTime))
          .toList();

      // Store the most recent transaction ID for activity detection
      if (transactions.isNotEmpty) {
        _lastSeenTransactionId = _generateTransactionId(transactions.first);
      }

      state = state.copyWith(
        transactions: transactions,
        isLoading: false,
        hasNextPage: result.pageInfo.hasNextPage,
        cursor: result.pageInfo.endCursor,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load the next page of transfers
  Future<void> loadMoreTransactions() async {
    if (state.isLoading || !state.hasNextPage) return;

    // Check if we have Squid connection specifically (required for transaction history)
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final genesisTime = await ref.read(genesisTimeProvider.future);

      // Fetch more transfers using cursor pagination
      final result = await d.SquidService.client.getAccountHistory(address, number: 20, cursor: state.cursor);

      if (result == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final newTransactions = result.edges
          .map((edge) => TransactionDisplayItem.fromGraphQLNode(edge.node, address, genesisTime))
          .toList();

      state = state.copyWith(
        transactions: [...state.transactions, ...newTransactions],
        isLoading: false,
        hasNextPage: result.pageInfo.hasNextPage,
        cursor: result.pageInfo.endCursor,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresh the transaction history (public method for manual refresh)
  Future<void> refresh() async {
    state = const TransactionHistoryState();
    await loadTransactions();
  }

  @override
  void dispose() {
    _activitySubscription?.cancel();
    super.dispose();
  }
}

/// StateNotifier for managing combined transaction history (transfers + UDs)
class CombinedHistoryNotifier extends StateNotifier<TransactionHistoryState> {
  final Ref ref;
  final String address;
  StreamSubscription<String?>? _activitySubscription;
  String? _lastSeenTransactionId;

  CombinedHistoryNotifier(this.ref, this.address) : super(const TransactionHistoryState()) {
    loadTransactions();
    _subscribeToAccountActivity();
  }

  /// Subscribe to account activity (simple subscription that triggers refreshes)
  void _subscribeToAccountActivity() {
    // Check if we have Squid connection
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
                print('New activity detected for $address: $transactionId (previous: $_lastSeenTransactionId)');
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
      // Refresh the complete transaction history
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

      print('Fetching fresh combined data for $address');

      // Fetch both transfers and UDs combined
      final result = await d.SquidService.client.getCombinedAccountHistory(
        address,
        number: 20,
        cursor: null,
        includeUniversalDividends: true,
        beforeTimestamp: null,
      );

      if (result != null) {
        final newTransactions = result.items
            .map((item) {
              if (item is d.Query$GetAccountHistory$transferConnection$edges$node) {
                return TransactionDisplayItem.fromGraphQLNode(item, address, genesisTime);
              } else if (item is d.Query$GetUdHistoryViaIdentity$identityConnection$edges$node$udHistory) {
                return TransactionDisplayItem.fromUdHistoryNode(item, address, genesisTime);
              } else {
                log.e('Unknown item type in combined history: ${item.runtimeType}');
                return null;
              }
            })
            .whereType<TransactionDisplayItem>()
            .toList();

        // Check if we actually have new transactions by comparing with current state
        final hasNewTransactions =
            newTransactions.isNotEmpty &&
            (state.transactions.isEmpty ||
                (newTransactions.first.timestamp.isAfter(state.transactions.first.timestamp)));

        if (hasNewTransactions) {
          log.i('Found ${newTransactions.length} items, with newer ones than before');
        }

        state = state.copyWith(
          transactions: newTransactions,
          hasNextPage: result.hasNextPage,
          cursor: result.endCursor,
        );

        // Update last seen transaction ID with the most recent one
        if (newTransactions.isNotEmpty) {
          _lastSeenTransactionId = _generateTransactionId(newTransactions.first);
        }
      } else {
        log.w('Received null result from getCombinedAccountHistory');
      }
    } catch (e) {
      log.e('Error refreshing combined history: $e');
    }
  }

  /// Generate a consistent transaction ID from transaction data
  String _generateTransactionId(TransactionDisplayItem transaction) {
    return '${transaction.timestamp.millisecondsSinceEpoch}_${transaction.amount}_${transaction.isReceived}_${transaction.type.name}';
  }

  /// Load the first page of combined transactions
  Future<void> loadTransactions() async {
    // Check if we have Squid connection specifically (required for transaction history)
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);

    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      state = state.copyWith(error: 'No network connection');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final genesisTime = await ref.read(genesisTimeProvider.future);

      // Fetch both transfers and UDs combined
      final result = await d.SquidService.client.getCombinedAccountHistory(
        address,
        number: 20,
        cursor: null,
        includeUniversalDividends: true,
        beforeTimestamp: null,
      );

      if (result == null) {
        state = state.copyWith(transactions: [], isLoading: false, hasNextPage: false, cursor: null);
        return;
      }

      final transactions = result.items
          .map((item) {
            if (item is d.Query$GetAccountHistory$transferConnection$edges$node) {
              return TransactionDisplayItem.fromGraphQLNode(item, address, genesisTime);
            } else if (item is d.Query$GetUdHistoryViaIdentity$identityConnection$edges$node$udHistory) {
              return TransactionDisplayItem.fromUdHistoryNode(item, address, genesisTime);
            } else {
              log.e('Unknown item type in combined history: ${item.runtimeType}');
              return null;
            }
          })
          .whereType<TransactionDisplayItem>()
          .toList();

      // Store the most recent transaction ID for activity detection
      if (transactions.isNotEmpty) {
        _lastSeenTransactionId = _generateTransactionId(transactions.first);
      }

      state = state.copyWith(
        transactions: transactions,
        isLoading: false,
        hasNextPage: result.hasNextPage,
        cursor: result.endCursor,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load the next page of combined transactions
  Future<void> loadMoreTransactions() async {
    if (state.isLoading || !state.hasNextPage) return;

    // Check if we have Squid connection specifically (required for transaction history)
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final genesisTime = await ref.read(genesisTimeProvider.future);

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

      // Fetch more combined transactions using timestamp-based pagination
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

      final newTransactions = result.items
          .map((item) {
            if (item is d.Query$GetAccountHistory$transferConnection$edges$node) {
              return TransactionDisplayItem.fromGraphQLNode(item, address, genesisTime);
            } else if (item is d.Query$GetUdHistoryViaIdentity$identityConnection$edges$node$udHistory) {
              return TransactionDisplayItem.fromUdHistoryNode(item, address, genesisTime);
            } else {
              log.e('Unknown item type in combined history: ${item.runtimeType}');
              return null;
            }
          })
          .whereType<TransactionDisplayItem>()
          .toList();

      state = state.copyWith(
        transactions: [...state.transactions, ...newTransactions],
        isLoading: false,
        hasNextPage: result.hasNextPage,
        cursor: result.endCursor,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresh the transaction history (public method for manual refresh)
  Future<void> refresh() async {
    state = const TransactionHistoryState();
    await loadTransactions();
  }

  @override
  void dispose() {
    _activitySubscription?.cancel();
    super.dispose();
  }
}

/// Provider for transfers-only transaction history
final transfersOnlyHistoryProvider =
    StateNotifierProvider.family<TransfersOnlyHistoryNotifier, TransactionHistoryState, String>((ref, address) {
      return TransfersOnlyHistoryNotifier(ref, address);
    });

/// Provider for combined transaction history (transfers + UDs)
final combinedHistoryProvider = StateNotifierProvider.family<CombinedHistoryNotifier, TransactionHistoryState, String>((
  ref,
  address,
) {
  return CombinedHistoryNotifier(ref, address);
});

/// Conditional provider that switches between transfers-only and combined history based on toggle
final transactionHistoryProvider = Provider.family<TransactionHistoryState, String>((ref, address) {
  final includeUD = ref.watch(universalDividendsToggleProvider);

  if (includeUD) {
    return ref.watch(combinedHistoryProvider(address));
  } else {
    return ref.watch(transfersOnlyHistoryProvider(address));
  }
});

/// Toggle universal dividends and switch providers accordingly
void toggleUniversalDividends(WidgetRef ref, String address) {
  ref.read(universalDividendsToggleProvider.notifier).toggle();
  // The conditional provider will automatically switch between providers

  // Trigger scroll to top
  ref.read(scrollToTopProvider.notifier).triggerScrollToTop();
}

/// Refresh transaction history (adaptive - uses server filtering when filters are active)
Future<void> refreshTransactionHistory(WidgetRef ref, String address) async {
  final filters = ref.read(transactionFiltersProvider);

  if (filters.hasActiveFilters) {
    // Use server-side filtering refresh
    await ref.read(serverFilteredHistoryProvider(address).notifier).refresh();
  } else {
    // Use standard approach based on UD toggle
    final includeUD = ref.read(universalDividendsToggleProvider);
    if (includeUD) {
      await ref.read(combinedHistoryProvider(address).notifier).refresh();
    } else {
      await ref.read(transfersOnlyHistoryProvider(address).notifier).refresh();
    }
  }
}

/// Load more transactions (adaptive - uses server filtering when filters are active)
Future<void> loadMoreTransactions(WidgetRef ref, String address) async {
  final filters = ref.read(transactionFiltersProvider);

  if (filters.hasActiveFilters) {
    // Use server-side filtering load more
    await ref.read(serverFilteredHistoryProvider(address).notifier).loadMore();
  } else {
    // Use standard approach based on UD toggle
    final includeUD = ref.read(universalDividendsToggleProvider);
    if (includeUD) {
      await ref.read(combinedHistoryProvider(address).notifier).loadMoreTransactions();
    } else {
      await ref.read(transfersOnlyHistoryProvider(address).notifier).loadMoreTransactions();
    }
  }
}

/// Simple notifier to trigger scroll to top events
class ScrollToTopNotifier extends StateNotifier<int> {
  ScrollToTopNotifier() : super(0);

  void triggerScrollToTop() {
    state = state + 1; // Increment to trigger watchers
  }
}

/// Provider for scroll to top events
final scrollToTopProvider = StateNotifierProvider<ScrollToTopNotifier, int>((ref) {
  return ScrollToTopNotifier();
});

/// Enhanced transaction history provider with adaptive server-side filtering
final filteredTransactionHistoryProvider = Provider.family<TransactionHistoryState, String>((ref, address) {
  final filters = ref.watch(transactionFiltersProvider);

  if (filters.hasActiveFilters) {
    // Use the new server-side filtering for better performance and completeness
    final serverState = ref.watch(serverFilteredHistoryProvider(address));

    // Convert server state to standard TransactionHistoryState format
    return TransactionHistoryState(
      transactions: serverState.transactions,
      isLoading: serverState.isLoading,
      hasNextPage: serverState.hasNextPage,
      cursor: serverState.cursor,
      error: serverState.error,
    );
  } else {
    // No filters: use existing efficient approach
    return ref.watch(transactionHistoryProvider(address));
  }
});
