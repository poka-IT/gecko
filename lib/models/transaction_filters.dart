/// Represents a date range filter
class DateRangeFilter {
  final DateTime? startDate;
  final DateTime? endDate;

  const DateRangeFilter({this.startDate, this.endDate});

  DateRangeFilter copyWith({DateTime? startDate, DateTime? endDate}) {
    return DateRangeFilter(startDate: startDate ?? this.startDate, endDate: endDate ?? this.endDate);
  }

  bool get isActive => startDate != null || endDate != null;

  bool matchesDate(DateTime date) {
    if (!isActive) return true;

    if (startDate != null && date.isBefore(startDate!)) return false;
    if (endDate != null && date.isAfter(endDate!.add(const Duration(days: 1)))) return false;

    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRangeFilter &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => startDate.hashCode ^ endDate.hashCode;
}

/// Represents an amount range filter
class AmountRangeFilter {
  final BigInt? minAmount;
  final BigInt? maxAmount;

  const AmountRangeFilter({this.minAmount, this.maxAmount});

  AmountRangeFilter copyWith({BigInt? minAmount, BigInt? maxAmount}) {
    return AmountRangeFilter(minAmount: minAmount ?? this.minAmount, maxAmount: maxAmount ?? this.maxAmount);
  }

  bool get isActive => minAmount != null || maxAmount != null;

  bool matchesAmount(BigInt amount) {
    if (!isActive) return true;

    if (minAmount != null && amount < minAmount!) return false;
    if (maxAmount != null && amount > maxAmount!) return false;

    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AmountRangeFilter &&
          runtimeType == other.runtimeType &&
          minAmount == other.minAmount &&
          maxAmount == other.maxAmount;

  @override
  int get hashCode => minAmount.hashCode ^ maxAmount.hashCode;
}

/// Complete transaction filter criteria
class TransactionFilterCriteria {
  final String? addressOrNameSearch;
  final String? commentSearch;
  final DateRangeFilter dateRange;
  final AmountRangeFilter amountRange;

  const TransactionFilterCriteria({
    this.addressOrNameSearch,
    this.commentSearch,
    this.dateRange = const DateRangeFilter(),
    this.amountRange = const AmountRangeFilter(),
  });

  TransactionFilterCriteria copyWith({
    String? addressOrNameSearch,
    String? commentSearch,
    DateRangeFilter? dateRange,
    AmountRangeFilter? amountRange,
  }) {
    return TransactionFilterCriteria(
      addressOrNameSearch: addressOrNameSearch ?? this.addressOrNameSearch,
      commentSearch: commentSearch ?? this.commentSearch,
      dateRange: dateRange ?? this.dateRange,
      amountRange: amountRange ?? this.amountRange,
    );
  }

  /// Clear specific filter
  TransactionFilterCriteria clearFilter(String filterType) {
    switch (filterType) {
      case 'address':
        return copyWith(addressOrNameSearch: null);
      case 'comment':
        return copyWith(commentSearch: null);
      case 'date':
        return copyWith(dateRange: const DateRangeFilter());
      case 'amount':
        return copyWith(amountRange: const AmountRangeFilter());
      default:
        return this;
    }
  }

  /// Clear all filters
  TransactionFilterCriteria clearAll() {
    return const TransactionFilterCriteria();
  }

  /// Check if any filter is active
  bool get hasActiveFilters =>
      addressOrNameSearch?.isNotEmpty == true ||
      commentSearch?.isNotEmpty == true ||
      dateRange.isActive ||
      amountRange.isActive;

  /// Get count of active filters
  int get activeFilterCount {
    int count = 0;
    if (addressOrNameSearch?.isNotEmpty == true) count++;
    if (commentSearch?.isNotEmpty == true) count++;
    if (dateRange.isActive) count++;
    if (amountRange.isActive) count++;
    return count;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionFilterCriteria &&
          runtimeType == other.runtimeType &&
          addressOrNameSearch == other.addressOrNameSearch &&
          commentSearch == other.commentSearch &&
          dateRange == other.dateRange &&
          amountRange == other.amountRange;

  @override
  int get hashCode => addressOrNameSearch.hashCode ^ commentSearch.hashCode ^ dateRange.hashCode ^ amountRange.hashCode;
}
