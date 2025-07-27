import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/certification_filters.dart';
import 'package:gecko/models/transaction_filters.dart';

/// Notifier for certification filter criteria
class CertificationFiltersNotifier extends StateNotifier<CertificationFilterCriteria> {
  CertificationFiltersNotifier() : super(const CertificationFilterCriteria(showActiveOnly: null));

  /// Update issuer search filter
  void updateIssuerSearch(String? issuerSearch) {
    state = state.copyWith(issuerSearch: issuerSearch?.isNotEmpty == true ? issuerSearch : null);
  }

  /// Update receiver search filter
  void updateReceiverSearch(String? receiverSearch) {
    state = state.copyWith(receiverSearch: receiverSearch?.isNotEmpty == true ? receiverSearch : null);
  }

  /// Update date range filter
  void updateDateRange(DateRangeFilter dateRange) {
    state = state.copyWith(dateRange: dateRange);
  }

  /// Update show active only setting
  void updateShowActiveOnly(bool? showActiveOnly) {
    if (showActiveOnly == null) {
      state = state.copyWithNullableActive(clearShowActiveOnly: true);
    } else {
      state = state.copyWithNullableActive(showActiveOnly: showActiveOnly);
    }
  }

  /// Update exact match issuer setting
  void updateExactMatchIssuer(bool exactMatch) {
    state = state.copyWith(exactMatchIssuer: exactMatch);
  }

  /// Update exact match receiver setting
  void updateExactMatchReceiver(bool exactMatch) {
    state = state.copyWith(exactMatchReceiver: exactMatch);
  }

  /// Toggle active status (cycles through active -> inactive -> all -> active)
  void toggleActiveStatus() {
    state = state.toggleActiveStatus();
  }

  /// Set to show active certifications only
  void setActiveOnly() {
    state = state.setActiveOnly();
  }

  /// Set to show inactive certifications only
  void setInactiveOnly() {
    state = state.setInactiveOnly();
  }

  /// Set to show all certifications
  void setShowAll() {
    state = state.setShowAll();
  }

  /// Clear a specific filter
  void clearFilter(String filterType) {
    state = state.clearFilter(filterType);
  }

  /// Reset all filters (keep default showActiveOnly = null to show all)
  void reset() {
    state = const CertificationFilterCriteria(showActiveOnly: null);
  }

  /// Reset all filters including showActiveOnly
  void resetAll() {
    state = state.clearAllIncludingActive();
  }
}

/// Provider for certification filter criteria
final certificationFiltersProvider = StateNotifierProvider<CertificationFiltersNotifier, CertificationFilterCriteria>((
  ref,
) {
  return CertificationFiltersNotifier();
});

/// Provider for certification filter panel expansion state
final certificationFilterPanelExpandedProvider = StateProvider<bool>((ref) => false);
