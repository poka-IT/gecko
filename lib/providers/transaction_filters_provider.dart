import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/transaction_filters.dart';

/// StateNotifier for managing transaction filter criteria
/// All actual filtering is done server-side via durt2 SquidService
class TransactionFiltersNotifier extends StateNotifier<TransactionFilterCriteria> {
  TransactionFiltersNotifier([FilterMode mode = FilterMode.account]) : super(TransactionFilterCriteria(mode: mode));

  /// Update address or name search filter
  void updateAddressOrNameSearch(String search) {
    final trimmed = search.trim();
    final result = trimmed.isEmpty ? null : trimmed;

    // Force copyWith to accept null by creating new instance - PRESERVE EXACT MATCH FLAGS!
    state = TransactionFilterCriteria(
      addressOrNameSearch: result,
      commentSearch: state.commentSearch,
      dateRange: state.dateRange,
      amountRange: state.amountRange,
      mode: state.mode,
      directionFilter: state.directionFilter,
      exactMatchAddress: state.exactMatchAddress,
      exactMatchComment: state.exactMatchComment,
      exactMatchDirection: state.exactMatchDirection,
    );
  }

  /// Update comment search filter
  void updateCommentSearch(String search) {
    final trimmed = search.trim();
    final result = trimmed.isEmpty ? null : trimmed;

    // Force copyWith to accept null by creating new instance - PRESERVE EXACT MATCH FLAGS!
    state = TransactionFilterCriteria(
      addressOrNameSearch: state.addressOrNameSearch,
      commentSearch: result,
      dateRange: state.dateRange,
      amountRange: state.amountRange,
      mode: state.mode,
      directionFilter: state.directionFilter,
      exactMatchAddress: state.exactMatchAddress,
      exactMatchComment: state.exactMatchComment,
      exactMatchDirection: state.exactMatchDirection,
    );
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

  /// Update direction filter (for network mode)
  void updateDirectionFilter(String fromAddress, String toAddress) {
    if (state.mode == FilterMode.network) {
      final cleanFromAddress = fromAddress.trim().isEmpty ? null : fromAddress.trim();
      final cleanToAddress = toAddress.trim().isEmpty ? null : toAddress.trim();

      DirectionFilter? newDirectionFilter;
      // If both addresses are null, clear the entire direction filter
      if (cleanFromAddress == null && cleanToAddress == null) {
        newDirectionFilter = null;
      } else {
        newDirectionFilter = DirectionFilter(fromAddress: cleanFromAddress, toAddress: cleanToAddress);
      }

      // Force update with new instance to handle null properly - PRESERVE EXACT MATCH FLAGS!
      state = TransactionFilterCriteria(
        addressOrNameSearch: state.addressOrNameSearch,
        commentSearch: state.commentSearch,
        dateRange: state.dateRange,
        amountRange: state.amountRange,
        mode: state.mode,
        directionFilter: newDirectionFilter,
        exactMatchAddress: state.exactMatchAddress,
        exactMatchComment: state.exactMatchComment,
        exactMatchDirection: state.exactMatchDirection,
      );
    }
  }

  /// Update from address filter (network mode)
  void updateFromAddress(String? fromAddress) {
    if (state.mode == FilterMode.network) {
      final currentDirection = state.directionFilter ?? const DirectionFilter();
      state = state.copyWith(
        directionFilter: currentDirection.copyWith(
          fromAddress: fromAddress?.trim().isEmpty == true ? null : fromAddress?.trim(),
        ),
      );
    }
  }

  /// Update to address filter (network mode)
  void updateToAddress(String? toAddress) {
    if (state.mode == FilterMode.network) {
      final currentDirection = state.directionFilter ?? const DirectionFilter();
      state = state.copyWith(
        directionFilter: currentDirection.copyWith(
          toAddress: toAddress?.trim().isEmpty == true ? null : toAddress?.trim(),
        ),
      );
    }
  }

  /// Update exact match settings
  void updateExactMatchAddress(bool exactMatch) {
    state = state.copyWith(exactMatchAddress: exactMatch);
  }

  void updateExactMatchComment(bool exactMatch) {
    state = state.copyWith(exactMatchComment: exactMatch);
  }

  void updateExactMatchDirection(bool exactMatch) {
    state = state.copyWith(exactMatchDirection: exactMatch);
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
    state = TransactionFilterCriteria(mode: state.mode);
  }

  /// Switch filter mode
  void switchMode(FilterMode mode) {
    state = TransactionFilterCriteria(mode: mode);
  }
}

/// Provider for transaction filter criteria (account mode)
final transactionFiltersProvider = StateNotifierProvider<TransactionFiltersNotifier, TransactionFilterCriteria>((ref) {
  return TransactionFiltersNotifier(FilterMode.account);
});

/// Provider for network activity filter criteria
final networkFiltersProvider = StateNotifierProvider<TransactionFiltersNotifier, TransactionFilterCriteria>((ref) {
  return TransactionFiltersNotifier(FilterMode.network);
});

/// Provider to track if the filter panel is expanded/open
final filterPanelExpandedProvider = StateProvider<bool>((ref) => false);

/// Provider to track if the network filter panel is expanded/open
final networkFilterPanelExpandedProvider = StateProvider<bool>((ref) => false);

/// Utility functions for filter management

/// Convert double amount to BigInt (assuming 2 decimal places like Duniter)
BigInt? convertAmountToBigInt(double amount) {
  return BigInt.from((amount * 100).round());
}

/// Convert BigInt amount to double (assuming 2 decimal places like Duniter)
double convertBigIntToAmount(BigInt? amount) {
  if (amount == null) return 0.0;
  return amount.toDouble() / 100;
}
