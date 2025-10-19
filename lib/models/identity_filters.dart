import 'package:gecko/models/transaction_filters.dart';

/// Identity filter criteria for the Gecko UI
class IdentityFilterCriteria {
  final String? nameSearch;
  final List<String>? selectedStatuses;
  final DateRangeFilter dateRange;
  final bool exactMatchName;

  const IdentityFilterCriteria({
    this.nameSearch,
    this.selectedStatuses,
    this.dateRange = const DateRangeFilter(),
    this.exactMatchName = false,
  });

  IdentityFilterCriteria copyWith({
    String? nameSearch,
    List<String>? selectedStatuses,
    DateRangeFilter? dateRange,
    bool? exactMatchName,
  }) {
    return IdentityFilterCriteria(
      nameSearch: nameSearch ?? this.nameSearch,
      selectedStatuses: selectedStatuses ?? this.selectedStatuses,
      dateRange: dateRange ?? this.dateRange,
      exactMatchName: exactMatchName ?? this.exactMatchName,
    );
  }

  /// Clear specific filter
  IdentityFilterCriteria clearFilter(String filterType) {
    switch (filterType) {
      case 'name':
        return copyWith(nameSearch: null);
      case 'status':
        return copyWith(selectedStatuses: null);
      case 'date':
        return copyWith(dateRange: const DateRangeFilter());
      default:
        return this;
    }
  }

  /// Clear all filters
  IdentityFilterCriteria clearAll() {
    return const IdentityFilterCriteria();
  }

  /// Check if any filter is active
  bool get hasActiveFilters =>
      nameSearch?.isNotEmpty == true || selectedStatuses?.isNotEmpty == true || dateRange.isActive;

  /// Get count of active filters
  int get activeFilterCount {
    int count = 0;
    if (nameSearch?.isNotEmpty == true) count++;
    if (selectedStatuses?.isNotEmpty == true) count++;
    if (dateRange.isActive) count++;
    return count;
  }

  /// Check if a specific status is selected
  bool isStatusSelected(String status) {
    return selectedStatuses?.contains(status) ?? false;
  }

  /// Toggle a status selection
  IdentityFilterCriteria toggleStatus(String status) {
    final currentStatuses = selectedStatuses?.toList() ?? <String>[];

    if (currentStatuses.contains(status)) {
      currentStatuses.remove(status);
    } else {
      currentStatuses.add(status);
    }

    return copyWith(selectedStatuses: currentStatuses.isEmpty ? null : currentStatuses);
  }

  /// Select all available statuses
  IdentityFilterCriteria selectAllStatuses() {
    return copyWith(
      selectedStatuses: [
        'Member',
        'NotMember',
        'Removed',
        'Revoked',
        'Unconfirmed',
        'Unvalidated',
      ].where((status) => status != 'Unknown').toList(),
    );
  }

  /// Clear all status selections
  IdentityFilterCriteria clearAllStatuses() {
    return copyWith(selectedStatuses: null);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IdentityFilterCriteria &&
          runtimeType == other.runtimeType &&
          nameSearch == other.nameSearch &&
          _listsEqual(selectedStatuses, other.selectedStatuses) &&
          dateRange == other.dateRange &&
          exactMatchName == other.exactMatchName;

  @override
  int get hashCode =>
      nameSearch.hashCode ^ _listHashCode(selectedStatuses) ^ dateRange.hashCode ^ exactMatchName.hashCode;

  /// Compare two lists for equality
  bool _listsEqual<T>(List<T>? a, List<T>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;

    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Generate hash code for a list
  int _listHashCode<T>(List<T>? list) {
    if (list == null) return 0;
    int hash = 0;
    for (final item in list) {
      hash ^= item.hashCode;
    }
    return hash;
  }

  @override
  String toString() {
    return 'IdentityFilterCriteria{nameSearch: $nameSearch, selectedStatuses: $selectedStatuses, dateRange: $dateRange, exactMatchName: $exactMatchName}';
  }
}
