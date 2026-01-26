import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/identity_filters.dart';
import 'package:gecko/models/transaction_filters.dart';

/// Notifier for identity filter criteria
class IdentityFiltersNotifier extends Notifier<IdentityFilterCriteria> {
  @override
  IdentityFilterCriteria build() {
    return const IdentityFilterCriteria();
  }

  /// Update name search filter
  void updateNameSearch(String? nameSearch) {
    state = state.copyWith(nameSearch: nameSearch?.isNotEmpty == true ? nameSearch : null);
  }

  /// Update selected statuses filter
  void updateSelectedStatuses(List<String>? statuses) {
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
  void toggleStatus(String status) {
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
final identityFiltersProvider = NotifierProvider<IdentityFiltersNotifier, IdentityFilterCriteria>(IdentityFiltersNotifier.new);

/// Notifier for identity filter panel expansion state
class IdentityFilterPanelExpandedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void set(bool value) => state = value;
}

/// Provider for identity filter panel expansion state
final identityFilterPanelExpandedProvider = NotifierProvider<IdentityFilterPanelExpandedNotifier, bool>(IdentityFilterPanelExpandedNotifier.new);
