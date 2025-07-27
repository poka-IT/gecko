import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durt2/durt2.dart' show Enum$IdentityStatusEnum;
import 'package:gecko/models/identity_filters.dart';
import 'package:gecko/models/transaction_filters.dart';

/// Notifier for identity filter criteria
class IdentityFiltersNotifier extends StateNotifier<IdentityFilterCriteria> {
  IdentityFiltersNotifier() : super(const IdentityFilterCriteria());

  /// Update name search filter
  void updateNameSearch(String? nameSearch) {
    state = state.copyWith(nameSearch: nameSearch?.isNotEmpty == true ? nameSearch : null);
  }

  /// Update selected statuses filter
  void updateSelectedStatuses(List<Enum$IdentityStatusEnum>? statuses) {
    state = state.copyWith(selectedStatuses: statuses?.isNotEmpty == true ? statuses : null);
  }

  /// Update date range filter
  void updateDateRange(DateRangeFilter dateRange) {
    state = state.copyWith(dateRange: dateRange);
  }

  /// Update exact match name setting
  void updateExactMatchName(bool exactMatch) {
    state = state.copyWith(exactMatchName: exactMatch);
  }

  /// Toggle a specific status
  void toggleStatus(Enum$IdentityStatusEnum status) {
    state = state.toggleStatus(status);
  }

  /// Select all statuses
  void selectAllStatuses() {
    state = state.selectAllStatuses();
  }

  /// Clear all status selections
  void clearAllStatuses() {
    state = state.clearAllStatuses();
  }

  /// Clear a specific filter
  void clearFilter(String filterType) {
    state = state.clearFilter(filterType);
  }

  /// Reset all filters
  void reset() {
    state = const IdentityFilterCriteria();
  }
}

/// Provider for identity filter criteria
final identityFiltersProvider = StateNotifierProvider<IdentityFiltersNotifier, IdentityFilterCriteria>((ref) {
  return IdentityFiltersNotifier();
});

/// Provider for identity filter panel expansion state
final identityFilterPanelExpandedProvider = StateProvider<bool>((ref) => false);
