import 'package:gecko/models/transaction_filters.dart';

/// Certification filter criteria for the Gecko UI
class CertificationFilterCriteria {
  final String? issuerSearch;
  final String? receiverSearch;
  final DateRangeFilter dateRange;
  final bool? showActiveOnly; // null = all, true = active only, false = inactive only
  final bool exactMatchIssuer;
  final bool exactMatchReceiver;

  const CertificationFilterCriteria({
    this.issuerSearch,
    this.receiverSearch,
    this.dateRange = const DateRangeFilter(),
    this.showActiveOnly = true, // Default to active certifications only
    this.exactMatchIssuer = false,
    this.exactMatchReceiver = false,
  });

  CertificationFilterCriteria copyWith({
    String? issuerSearch,
    String? receiverSearch,
    DateRangeFilter? dateRange,
    bool? showActiveOnly,
    bool? exactMatchIssuer,
    bool? exactMatchReceiver,
  }) {
    return CertificationFilterCriteria(
      issuerSearch: issuerSearch ?? this.issuerSearch,
      receiverSearch: receiverSearch ?? this.receiverSearch,
      dateRange: dateRange ?? this.dateRange,
      showActiveOnly: showActiveOnly ?? this.showActiveOnly,
      exactMatchIssuer: exactMatchIssuer ?? this.exactMatchIssuer,
      exactMatchReceiver: exactMatchReceiver ?? this.exactMatchReceiver,
    );
  }

  /// Copy with method that allows setting showActiveOnly to null (to show all)
  CertificationFilterCriteria copyWithNullableActive({
    String? issuerSearch,
    String? receiverSearch,
    DateRangeFilter? dateRange,
    bool? showActiveOnly,
    bool clearShowActiveOnly = false,
    bool? exactMatchIssuer,
    bool? exactMatchReceiver,
  }) {
    return CertificationFilterCriteria(
      issuerSearch: issuerSearch ?? this.issuerSearch,
      receiverSearch: receiverSearch ?? this.receiverSearch,
      dateRange: dateRange ?? this.dateRange,
      showActiveOnly: clearShowActiveOnly ? null : (showActiveOnly ?? this.showActiveOnly),
      exactMatchIssuer: exactMatchIssuer ?? this.exactMatchIssuer,
      exactMatchReceiver: exactMatchReceiver ?? this.exactMatchReceiver,
    );
  }

  /// Clear specific filter
  CertificationFilterCriteria clearFilter(String filterType) {
    switch (filterType) {
      case 'issuer':
        return copyWith(issuerSearch: null);
      case 'receiver':
        return copyWith(receiverSearch: null);
      case 'date':
        return copyWith(dateRange: const DateRangeFilter());
      case 'active':
        return copyWithNullableActive(clearShowActiveOnly: true);
      default:
        return this;
    }
  }

  /// Clear all filters but keep default showActiveOnly = true
  CertificationFilterCriteria clearAll() {
    return const CertificationFilterCriteria(showActiveOnly: true);
  }

  /// Clear all filters including showActiveOnly
  CertificationFilterCriteria clearAllIncludingActive() {
    return const CertificationFilterCriteria(showActiveOnly: null);
  }

  /// Check if any filter is active (note: showActiveOnly is always considered active by default)
  bool get hasActiveFilters =>
      issuerSearch?.isNotEmpty == true ||
      receiverSearch?.isNotEmpty == true ||
      dateRange.isActive ||
      showActiveOnly != null; // Always considered active since we default to active-only

  /// Get count of active filters
  int get activeFilterCount {
    int count = 0;
    if (issuerSearch?.isNotEmpty == true) count++;
    if (receiverSearch?.isNotEmpty == true) count++;
    if (dateRange.isActive) count++;
    if (showActiveOnly != null) count++; // Always counted since we default to active-only
    return count;
  }

  /// Get display text for active status filter
  String get activeStatusDisplayText {
    switch (showActiveOnly) {
      case true:
        return "Active only";
      case false:
        return "Inactive only";
      case null:
        return "All certifications";
    }
  }

  /// Toggle between active only, inactive only, and all
  CertificationFilterCriteria toggleActiveStatus() {
    switch (showActiveOnly) {
      case true:
        return copyWithNullableActive(showActiveOnly: false); // true -> false (inactive only)
      case false:
        return copyWithNullableActive(clearShowActiveOnly: true); // false -> null (all)
      case null:
        return copyWith(showActiveOnly: true); // null -> true (active only)
    }
  }

  /// Set to show active certifications only
  CertificationFilterCriteria setActiveOnly() {
    return copyWith(showActiveOnly: true);
  }

  /// Set to show inactive certifications only
  CertificationFilterCriteria setInactiveOnly() {
    return copyWith(showActiveOnly: false);
  }

  /// Set to show all certifications
  CertificationFilterCriteria setShowAll() {
    return copyWithNullableActive(clearShowActiveOnly: true);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CertificationFilterCriteria &&
          runtimeType == other.runtimeType &&
          issuerSearch == other.issuerSearch &&
          receiverSearch == other.receiverSearch &&
          dateRange == other.dateRange &&
          showActiveOnly == other.showActiveOnly &&
          exactMatchIssuer == other.exactMatchIssuer &&
          exactMatchReceiver == other.exactMatchReceiver;

  @override
  int get hashCode =>
      issuerSearch.hashCode ^
      receiverSearch.hashCode ^
      dateRange.hashCode ^
      showActiveOnly.hashCode ^
      exactMatchIssuer.hashCode ^
      exactMatchReceiver.hashCode;

  @override
  String toString() {
    return 'CertificationFilterCriteria{issuerSearch: $issuerSearch, receiverSearch: $receiverSearch, dateRange: $dateRange, showActiveOnly: $showActiveOnly, exactMatchIssuer: $exactMatchIssuer, exactMatchReceiver: $exactMatchReceiver}';
  }
}
