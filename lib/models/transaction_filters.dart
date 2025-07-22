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

/// Filter mode for different activity views
enum FilterMode { account, network }

/// Direction filter for network activity (from/to addresses)
class DirectionFilter {
  final String? fromAddress;
  final String? toAddress;

  const DirectionFilter({this.fromAddress, this.toAddress});

  DirectionFilter copyWith({String? fromAddress, String? toAddress}) {
    return DirectionFilter(fromAddress: fromAddress ?? this.fromAddress, toAddress: toAddress ?? this.toAddress);
  }

  bool get isActive => fromAddress?.isNotEmpty == true || toAddress?.isNotEmpty == true;

  bool matchesDirection(
    String? transactionFromAddress,
    String? transactionToAddress,
    String? fromUsername,
    String? toUsername,
  ) {
    if (!isActive) return true;

    bool fromMatches = true;
    bool toMatches = true;

    // Check "from" filter
    if (fromAddress?.isNotEmpty == true) {
      final searchTerm = fromAddress!.toLowerCase();
      fromMatches =
          transactionFromAddress?.toLowerCase().contains(searchTerm) == true ||
          fromUsername?.toLowerCase().contains(searchTerm) == true;
    }

    // Check "to" filter
    if (toAddress?.isNotEmpty == true) {
      final searchTerm = toAddress!.toLowerCase();
      toMatches =
          transactionToAddress?.toLowerCase().contains(searchTerm) == true ||
          toUsername?.toLowerCase().contains(searchTerm) == true;
    }

    return fromMatches && toMatches;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DirectionFilter &&
          runtimeType == other.runtimeType &&
          fromAddress == other.fromAddress &&
          toAddress == other.toAddress;

  @override
  int get hashCode => fromAddress.hashCode ^ toAddress.hashCode;
}

/// Complete transaction filter criteria
class TransactionFilterCriteria {
  final String? addressOrNameSearch;
  final String? commentSearch;
  final DateRangeFilter dateRange;
  final AmountRangeFilter amountRange;
  final FilterMode mode;
  final DirectionFilter? directionFilter;
  final bool exactMatchAddress;
  final bool exactMatchComment;
  final bool exactMatchDirection;

  const TransactionFilterCriteria({
    this.addressOrNameSearch,
    this.commentSearch,
    this.dateRange = const DateRangeFilter(),
    this.amountRange = const AmountRangeFilter(),
    this.mode = FilterMode.account,
    this.directionFilter,
    this.exactMatchAddress = false,
    this.exactMatchComment = false,
    this.exactMatchDirection = false,
  });

  TransactionFilterCriteria copyWith({
    String? addressOrNameSearch,
    String? commentSearch,
    DateRangeFilter? dateRange,
    AmountRangeFilter? amountRange,
    FilterMode? mode,
    DirectionFilter? directionFilter,
    bool? exactMatchAddress,
    bool? exactMatchComment,
    bool? exactMatchDirection,
  }) {
    return TransactionFilterCriteria(
      addressOrNameSearch: addressOrNameSearch ?? this.addressOrNameSearch,
      commentSearch: commentSearch ?? this.commentSearch,
      dateRange: dateRange ?? this.dateRange,
      amountRange: amountRange ?? this.amountRange,
      mode: mode ?? this.mode,
      directionFilter: directionFilter ?? this.directionFilter,
      exactMatchAddress: exactMatchAddress ?? this.exactMatchAddress,
      exactMatchComment: exactMatchComment ?? this.exactMatchComment,
      exactMatchDirection: exactMatchDirection ?? this.exactMatchDirection,
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
      case 'direction':
        return copyWith(directionFilter: const DirectionFilter());
      default:
        return this;
    }
  }

  /// Clear all filters
  TransactionFilterCriteria clearAll() {
    return TransactionFilterCriteria(mode: mode);
  }

  /// Check if any filter is active
  bool get hasActiveFilters =>
      addressOrNameSearch?.isNotEmpty == true ||
      commentSearch?.isNotEmpty == true ||
      dateRange.isActive ||
      amountRange.isActive ||
      (mode == FilterMode.network && directionFilter?.isActive == true);

  /// Get count of active filters
  int get activeFilterCount {
    int count = 0;
    if (addressOrNameSearch?.isNotEmpty == true) count++;
    if (commentSearch?.isNotEmpty == true) count++;
    if (dateRange.isActive) count++;
    if (amountRange.isActive) count++;
    if (mode == FilterMode.network && directionFilter?.isActive == true) count++;
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
          amountRange == other.amountRange &&
          mode == other.mode &&
          directionFilter == other.directionFilter &&
          exactMatchAddress == other.exactMatchAddress &&
          exactMatchComment == other.exactMatchComment &&
          exactMatchDirection == other.exactMatchDirection;

  @override
  int get hashCode =>
      addressOrNameSearch.hashCode ^
      commentSearch.hashCode ^
      dateRange.hashCode ^
      amountRange.hashCode ^
      mode.hashCode ^
      directionFilter.hashCode ^
      exactMatchAddress.hashCode ^
      exactMatchComment.hashCode ^
      exactMatchDirection.hashCode;
}
