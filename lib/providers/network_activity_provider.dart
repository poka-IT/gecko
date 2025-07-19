// ignore_for_file: avoid_print

import 'dart:async';
import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers.dart';
import 'package:gecko/models/transaction_display_item.dart';

/// State for network activity history
class NetworkActivityState {
  final List<TransactionDisplayItem> transactions;
  final bool isLoading;
  final bool hasNextPage;
  final String? cursor;
  final String? error;

  const NetworkActivityState({
    this.transactions = const [],
    this.isLoading = false,
    this.hasNextPage = true,
    this.cursor,
    this.error,
  });

  NetworkActivityState copyWith({
    List<TransactionDisplayItem>? transactions,
    bool? isLoading,
    bool? hasNextPage,
    String? cursor,
    String? error,
  }) {
    return NetworkActivityState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      cursor: cursor ?? this.cursor,
      error: error ?? this.error,
    );
  }
}

/// StateNotifier for managing network-wide transaction history
class NetworkActivityNotifier extends StateNotifier<NetworkActivityState> {
  final Ref ref;
  StreamSubscription<String?>? _networkActivitySubscription;
  String? _lastSeenTransactionId;

  NetworkActivityNotifier(this.ref) : super(const NetworkActivityState()) {
    loadTransactions();
    _subscribeToNetworkActivity();
  }

  /// Subscribe to network-wide activity (triggers refreshes when new transactions occur)
  void _subscribeToNetworkActivity() {
    // Check if we have Squid connection
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      log.w('Cannot subscribe to network activity: Squid not connected');
      return;
    }

    try {
      _networkActivitySubscription = d.SquidService.client.subscribeNetworkActivity().listen(
        (transactionId) {
          if (transactionId != null && transactionId != _lastSeenTransactionId) {
            print('New network activity detected: $transactionId (previous: $_lastSeenTransactionId)');
            _lastSeenTransactionId = transactionId;
            _onNetworkActivity();
          } else if (transactionId != null) {
            log.d('Received known transaction ID: $transactionId');
          }
        },
        onError: (error) {
          log.e('Network activity subscription error: $error');
        },
      );
    } catch (e) {
      log.e('Failed to setup network activity subscription: $e');
    }
  }

  /// Handle network activity by refreshing the transaction history
  void _onNetworkActivity() async {
    try {
      // Don't refresh if we're already loading
      if (state.isLoading) {
        log.d('Skipping network activity refresh: already loading');
        return;
      }

      // Refresh the complete transaction history
      await _refreshNetworkActivity();
    } catch (e) {
      log.e('Error handling network activity: $e');
    }
  }

  /// Refresh network activity (used for activity-triggered updates)
  Future<void> _refreshNetworkActivity() async {
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      log.w('Cannot refresh: Squid not connected');
      return;
    }

    try {
      final genesisTime = await ref.read(genesisTimeProvider.future);

      print('🔄 Fetching fresh network activity data');

      // Fetch fresh network-wide transactions
      final result = await d.SquidService.client.getNetworkActivity(number: 20, cursor: null);

      if (result != null) {
        final newTransactions = result.edges
            .map((edge) => TransactionDisplayItem.fromNetworkActivityNode(edge.node, genesisTime))
            .toList();

        // Check if we actually have new transactions by comparing with current state
        final hasNewTransactions =
            newTransactions.isNotEmpty &&
            (state.transactions.isEmpty ||
                (newTransactions.first.timestamp.isAfter(state.transactions.first.timestamp)));

        if (hasNewTransactions) {
          log.i('Found ${newTransactions.length} new network transactions');
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
        log.w('Received null result from getNetworkActivity');
      }
    } catch (e) {
      log.e('Error refreshing network activity: $e');
    }
  }

  /// Generate a consistent transaction ID from transaction data
  String _generateTransactionId(TransactionDisplayItem transaction) {
    return '${transaction.timestamp.millisecondsSinceEpoch}_${transaction.amount}_${transaction.isReceived}_${transaction.type.name}';
  }

  /// Load the first page of network transactions
  Future<void> loadTransactions() async {
    // Check if we have Squid connection
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);

    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      state = state.copyWith(error: 'No network connection');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final genesisTime = await ref.read(genesisTimeProvider.future);

      // Fetch network-wide transactions
      final result = await d.SquidService.client.getNetworkActivity(number: 20, cursor: null);

      if (result == null) {
        print('🔴 Network activity result is null');
        state = state.copyWith(transactions: [], isLoading: false, hasNextPage: false, cursor: null);
        return;
      }

      print('🟢 Network activity loaded: ${result.edges.length} transactions');

      // Convert network activity nodes to TransactionDisplayItems for network view
      final transactions = result.edges
          .map((edge) => TransactionDisplayItem.fromNetworkActivityNode(edge.node, genesisTime))
          .toList();

      state = state.copyWith(
        transactions: transactions,
        isLoading: false,
        hasNextPage: result.pageInfo.hasNextPage,
        cursor: result.pageInfo.endCursor,
      );

      // Store the most recent transaction ID for activity detection
      if (transactions.isNotEmpty) {
        _lastSeenTransactionId = _generateTransactionId(transactions.first);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load the next page of network transactions
  Future<void> loadMoreTransactions() async {
    if (state.isLoading || !state.hasNextPage) return;

    // Check if we have Squid connection
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final genesisTime = await ref.read(genesisTimeProvider.future);

      // Fetch more network transactions using cursor pagination
      final result = await d.SquidService.client.getNetworkActivity(number: 20, cursor: state.cursor);

      if (result == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final newTransactions = result.edges
          .map((edge) => TransactionDisplayItem.fromNetworkActivityNode(edge.node, genesisTime))
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

  /// Refresh the network activity (public method for manual refresh)
  Future<void> refresh() async {
    state = const NetworkActivityState();
    await loadTransactions();
  }

  @override
  void dispose() {
    _networkActivitySubscription?.cancel();
    super.dispose();
  }
}

/// Provider for network activity
final networkActivityProvider = StateNotifierProvider<NetworkActivityNotifier, NetworkActivityState>((ref) {
  return NetworkActivityNotifier(ref);
});

/// Load more network transactions
Future<void> loadMoreNetworkTransactions(WidgetRef ref) async {
  await ref.read(networkActivityProvider.notifier).loadMoreTransactions();
}

/// Refresh network activity
Future<void> refreshNetworkActivity(WidgetRef ref) async {
  await ref.read(networkActivityProvider.notifier).refresh();
}
