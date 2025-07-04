import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  TransactionHistoryNotifier(this.ref, this.address) : super(const TransactionHistoryState()) {
    loadTransactions();
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

  /// Refresh the transaction history
  Future<void> refresh() async {
    state = const TransactionHistoryState();
    await loadTransactions();
  }
}

/// Provider for transaction history
final transactionHistoryProvider =
    StateNotifierProvider.family<TransactionHistoryNotifier, TransactionHistoryState, String>((ref, address) {
      return TransactionHistoryNotifier(ref, address);
    });
