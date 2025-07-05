import 'dart:async';
import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/transaction_display_item.dart';
import 'package:gecko/providers.dart';

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

/// StateNotifier for managing transaction history
class TransactionHistoryNotifier extends StateNotifier<TransactionHistoryState> {
  final Ref ref;
  final String address;
  StreamSubscription<String?>? _activitySubscription;
  String? _lastSeenTransactionId;

  TransactionHistoryNotifier(this.ref, this.address) : super(const TransactionHistoryState()) {
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
                log.i('New activity detected for $address: $transactionId (previous: $_lastSeenTransactionId)');
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

      log.d('Fetching fresh transaction data for $address');
      // Fetch fresh data
      final result = await d.SquidService.client.getAccountHistory(address, number: 20, cursor: null);

      if (result != null) {
        final newTransactions = result.edges.map((edge) {
          return TransactionDisplayItem.fromGraphQLNode(edge.node, address, genesisTime);
        }).toList();

        // Check if we actually have new transactions by comparing with current state
        final hasNewTransactions =
            newTransactions.isNotEmpty &&
            (state.transactions.isEmpty ||
                (newTransactions.first.timestamp.isAfter(state.transactions.first.timestamp)));

        if (hasNewTransactions) {
          log.i('Found ${newTransactions.length} transactions, with newer ones than before');
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
      log.e('Error refreshing transaction history: $e');
    }
  }

  /// Generate a consistent transaction ID from transaction data
  String _generateTransactionId(TransactionDisplayItem transaction) {
    return '${transaction.timestamp.millisecondsSinceEpoch}_${transaction.amount}_${transaction.isReceived}';
  }

  /// Load the first page of transactions
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

      final result = await d.SquidService.client.getAccountHistory(address, number: 20, cursor: null);

      if (result == null) {
        state = state.copyWith(transactions: [], isLoading: false, hasNextPage: false, cursor: null);
        return;
      }

      final transactions = result.edges.map((edge) {
        return TransactionDisplayItem.fromGraphQLNode(edge.node, address, genesisTime);
      }).toList();

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

  /// Load the next page of transactions
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

      final result = await d.SquidService.client.getAccountHistory(address, number: 20, cursor: state.cursor);

      if (result == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final newTransactions = result.edges.map((edge) {
        return TransactionDisplayItem.fromGraphQLNode(edge.node, address, genesisTime);
      }).toList();

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

/// Provider for transaction history
final transactionHistoryProvider =
    StateNotifierProvider.family<TransactionHistoryNotifier, TransactionHistoryState, String>((ref, address) {
      return TransactionHistoryNotifier(ref, address);
    });
