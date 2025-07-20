import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/transaction_filters.dart';
import 'package:gecko/models/transaction_display_item.dart';

/// StateNotifier for managing transaction filter criteria
class TransactionFiltersNotifier extends StateNotifier<TransactionFilterCriteria> {
  TransactionFiltersNotifier() : super(const TransactionFilterCriteria());

  /// Update address or name search filter
  void updateAddressOrNameSearch(String? search) {
    state = state.copyWith(addressOrNameSearch: search?.trim().isEmpty == true ? null : search?.trim());
  }

  /// Update comment search filter
  void updateCommentSearch(String? search) {
    state = state.copyWith(commentSearch: search?.trim().isEmpty == true ? null : search?.trim());
  }

  /// Update date range filter
  void updateDateRange(DateTime? startDate, DateTime? endDate) {
    state = state.copyWith(
      dateRange: DateRangeFilter(startDate: startDate, endDate: endDate),
    );
  }

  /// Update amount range filter
  void updateAmountRange(BigInt? minAmount, BigInt? maxAmount) {
    state = state.copyWith(
      amountRange: AmountRangeFilter(minAmount: minAmount, maxAmount: maxAmount),
    );
  }

  /// Clear specific filter
  void clearFilter(String filterType) {
    state = state.clearFilter(filterType);
  }

  /// Clear all filters
  void clearAllFilters() {
    state = state.clearAll();
  }

  /// Reset to empty state
  void reset() {
    state = const TransactionFilterCriteria();
  }
}

/// Provider for transaction filter criteria
final transactionFiltersProvider = StateNotifierProvider<TransactionFiltersNotifier, TransactionFilterCriteria>((ref) {
  return TransactionFiltersNotifier();
});

/// Provider to track if the filter panel is expanded/open
final filterPanelExpandedProvider = StateProvider<bool>((ref) => false);

/// Helper function to apply filters to a list of transactions
List<TransactionDisplayItem> applyTransactionFilters(
  List<TransactionDisplayItem> transactions,
  TransactionFilterCriteria filters,
) {
  if (!filters.hasActiveFilters) return transactions;

  return transactions.where((transaction) {
    // Apply address or name search filter
    if (filters.addressOrNameSearch?.isNotEmpty == true) {
      final searchTerm = filters.addressOrNameSearch!.toLowerCase();
      final addressMatches = transaction.address.toLowerCase().contains(searchTerm);
      final usernameMatches = transaction.username?.toLowerCase().contains(searchTerm) ?? false;

      if (!addressMatches && !usernameMatches) return false;
    }

    // Apply comment search filter
    if (filters.commentSearch?.isNotEmpty == true) {
      final searchTerm = filters.commentSearch!.toLowerCase();
      final commentMatches = transaction.comment?.toLowerCase().contains(searchTerm) ?? false;

      if (!commentMatches) return false;
    }

    // Apply date range filter
    if (!filters.dateRange.matchesDate(transaction.timestamp)) return false;

    // Apply amount range filter
    if (!filters.amountRange.matchesAmount(transaction.amount)) return false;

    return true;
  }).toList();
}

/// Parameters for filtered transactions provider
class FilteredTransactionsParams {
  final String address;
  final List<TransactionDisplayItem> transactions;

  const FilteredTransactionsParams({required this.address, required this.transactions});
}

/// Provider that applies filters to a transaction list
final filteredTransactionsProvider = Provider.family<List<TransactionDisplayItem>, FilteredTransactionsParams>((
  ref,
  params,
) {
  final filters = ref.watch(transactionFiltersProvider);
  return applyTransactionFilters(params.transactions, filters);
});

/// Utility functions for filter management

/// Convert double amount to BigInt (assuming 2 decimal places like Duniter)
BigInt? convertAmountToBigInt(double? amount) {
  if (amount == null) return null;
  return BigInt.from((amount * 100).round());
}

/// Convert BigInt amount to double (assuming 2 decimal places like Duniter)
double convertBigIntToAmount(BigInt? amount) {
  if (amount == null) return 0.0;
  return amount.toDouble() / 100.0;
}

/// Check if a search term matches an address (supports partial matches)
bool matchesAddress(String address, String searchTerm) {
  return address.toLowerCase().contains(searchTerm.toLowerCase());
}

/// Check if a search term matches a username
bool matchesUsername(String? username, String searchTerm) {
  if (username == null) return false;
  return username.toLowerCase().contains(searchTerm.toLowerCase());
}

/// Check if a search term matches a comment
bool matchesComment(String? comment, String searchTerm) {
  if (comment == null) return false;
  return comment.toLowerCase().contains(searchTerm.toLowerCase());
}
