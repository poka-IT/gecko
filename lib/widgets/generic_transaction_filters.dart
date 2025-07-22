import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/transaction_display_item.dart';
import 'package:gecko/models/transaction_filters.dart';
import 'package:gecko/providers/settings_provider.dart';
import 'package:gecko/providers/transaction_history_providers.dart';
import 'package:gecko/providers/transaction_filters_provider.dart';

/// Generic transaction filters widget that adapts to both account and network modes
class GenericTransactionFilters extends ConsumerStatefulWidget {
  const GenericTransactionFilters({super.key, required this.mode, this.address, this.showUDToggle = false});

  final FilterMode mode;
  final String? address; // Only needed for account mode
  final bool showUDToggle; // Whether to show Universal Dividends toggle

  @override
  ConsumerState<GenericTransactionFilters> createState() => _GenericTransactionFiltersState();
}

class _GenericTransactionFiltersState extends ConsumerState<GenericTransactionFilters>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isExpanded = false;

  // Controllers for filters
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();
  final TextEditingController _fromAddressController = TextEditingController();
  final TextEditingController _toAddressController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  // Local state for exact match checkboxes (only applied when clicking "Done")
  bool _localExactMatchAddress = false;
  bool _localExactMatchComment = false;
  bool _localExactMatchDirection = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    // Load current filter values
    _loadCurrentFilters();
  }

  void _loadCurrentFilters() {
    final filters = widget.mode == FilterMode.network
        ? ref.read(networkFiltersProvider)
        : ref.read(transactionFiltersProvider);

    // Clear or set address/name search
    if (filters.addressOrNameSearch?.isNotEmpty == true) {
      _addressController.text = filters.addressOrNameSearch!;
    } else {
      _addressController.clear();
    }

    // Clear or set comment search
    if (filters.commentSearch?.isNotEmpty == true) {
      _commentController.text = filters.commentSearch!;
    } else {
      _commentController.clear();
    }

    _startDate = filters.dateRange.startDate;
    _endDate = filters.dateRange.endDate;

    if (filters.amountRange.minAmount != null) {
      _minAmountController.text = convertBigIntToAmount(filters.amountRange.minAmount).toString();
    } else {
      _minAmountController.clear();
    }
    if (filters.amountRange.maxAmount != null) {
      _maxAmountController.text = convertBigIntToAmount(filters.amountRange.maxAmount).toString();
    } else {
      _maxAmountController.clear();
    }

    // Load direction filters for network mode
    if (widget.mode == FilterMode.network) {
      // Clear or set from address
      if (filters.directionFilter?.fromAddress?.isNotEmpty == true) {
        _fromAddressController.text = filters.directionFilter!.fromAddress!;
      } else {
        _fromAddressController.clear();
      }

      // Clear or set to address
      if (filters.directionFilter?.toAddress?.isNotEmpty == true) {
        _toAddressController.text = filters.directionFilter!.toAddress!;
      } else {
        _toAddressController.clear();
      }
    } else {
      // Clear direction filters when not in network mode
      _fromAddressController.clear();
      _toAddressController.clear();
    }

    // Load exact match states from provider
    _localExactMatchAddress = filters.exactMatchAddress;
    _localExactMatchComment = filters.exactMatchComment;
    _localExactMatchDirection = filters.exactMatchDirection;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _addressController.dispose();
    _commentController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _fromAddressController.dispose();
    _toAddressController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    // Update the appropriate provider state
    if (widget.mode == FilterMode.network) {
      ref.read(networkFilterPanelExpandedProvider.notifier).state = _isExpanded;
    } else {
      ref.read(filterPanelExpandedProvider.notifier).state = _isExpanded;
    }

    if (_isExpanded) {
      // Reload current filter values when opening the panel to sync controllers with provider state
      _loadCurrentFilters();
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _applyAdvancedFilters() {
    final filtersNotifier = widget.mode == FilterMode.network
        ? ref.read(networkFiltersProvider.notifier)
        : ref.read(transactionFiltersProvider.notifier);

    if (widget.mode == FilterMode.account) {
      // Apply account-specific filters
      final addressText = _addressController.text.trim();
      filtersNotifier.updateAddressOrNameSearch(addressText);
    } else {
      // Apply network-specific direction filters
      final fromText = _fromAddressController.text.trim();
      final toText = _toAddressController.text.trim();
      filtersNotifier.updateDirectionFilter(fromText, toText);
    }

    // Apply common filters
    final commentText = _commentController.text.trim();
    filtersNotifier.updateCommentSearch(commentText);

    filtersNotifier.updateDateRange(_startDate, _endDate);

    // Handle amount filters with proper validation
    final minAmountText = _minAmountController.text.trim();
    final maxAmountText = _maxAmountController.text.trim();

    final minAmount = minAmountText.isEmpty ? null : convertAmountToBigInt(double.tryParse(minAmountText) ?? 0);
    final maxAmount = maxAmountText.isEmpty ? null : convertAmountToBigInt(double.tryParse(maxAmountText) ?? 0);

    filtersNotifier.updateAmountRange(minAmount, maxAmount);

    // Apply exact match settings
    filtersNotifier.updateExactMatchAddress(_localExactMatchAddress);
    filtersNotifier.updateExactMatchComment(_localExactMatchComment);
    if (widget.mode == FilterMode.network) {
      filtersNotifier.updateExactMatchDirection(_localExactMatchDirection);
    }
  }

  void _clearAllFilters() {
    final filtersNotifier = widget.mode == FilterMode.network
        ? ref.read(networkFiltersProvider.notifier)
        : ref.read(transactionFiltersProvider.notifier);

    filtersNotifier.clearAllFilters();

    setState(() {
      _addressController.clear();
      _commentController.clear();
      _minAmountController.clear();
      _maxAmountController.clear();
      _fromAddressController.clear();
      _toAddressController.clear();
      _startDate = null;
      _endDate = null;
      // Reset local exact match states
      _localExactMatchAddress = false;
      _localExactMatchComment = false;
      _localExactMatchDirection = false;
    });
  }

  Future<void> _selectDateRange() async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: context.colorScheme),
          child: child!,
        );
      },
    );

    if (dateRange != null) {
      setState(() {
        _startDate = dateRange.start;
        _endDate = dateRange.end;
      });

      final filtersNotifier = widget.mode == FilterMode.network
          ? ref.read(networkFiltersProvider.notifier)
          : ref.read(transactionFiltersProvider.notifier);
      filtersNotifier.updateDateRange(_startDate, _endDate);
    }
  }

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });

    final filtersNotifier = widget.mode == FilterMode.network
        ? ref.read(networkFiltersProvider.notifier)
        : ref.read(transactionFiltersProvider.notifier);
    filtersNotifier.updateDateRange(null, null);
  }

  @override
  Widget build(BuildContext context) {
    final filters = widget.mode == FilterMode.network
        ? ref.watch(networkFiltersProvider)
        : ref.watch(transactionFiltersProvider);

    final hasAdvancedFilters = filters.hasActiveFilters;

    // Check for UDs if in account mode and showUDToggle is true
    bool hasUDs = false;
    bool isUDEnabled = false;
    if (widget.mode == FilterMode.account && widget.showUDToggle && widget.address != null) {
      final combinedState = ref.watch(combinedHistoryProvider(widget.address!));
      hasUDs = combinedState.transactions.any((transaction) => transaction.type == TransactionType.universalDividend);
      isUDEnabled = ref.watch(universalDividendsToggleProvider);
    }

    final totalActiveFilters = hasAdvancedFilters ? filters.activeFilterCount : 0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(2)),
      child: Column(
        children: [
          // Header with filter options
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleExpanded,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(6)),
                decoration: BoxDecoration(
                  color: totalActiveFilters > 0
                      ? context.colorScheme.primary.withValues(alpha: 0.08)
                      : context.colorScheme.surface.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: totalActiveFilters > 0
                        ? context.colorScheme.primary.withValues(alpha: 0.2)
                        : context.colorScheme.outline.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      size: scaleSize(18),
                      color: totalActiveFilters > 0
                          ? context.colorScheme.primary
                          : context.colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: scaleSize(12)),

                    // Filter label and toggles
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            'filters'.tr(),
                            style: scaledTextStyle(
                              fontSize: 14,
                              color: totalActiveFilters > 0
                                  ? context.colorScheme.primary
                                  : context.colorScheme.onSurfaceVariant,
                              fontWeight: totalActiveFilters > 0 ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),

                          // UD toggle for account mode
                          if (widget.mode == FilterMode.account && hasUDs && widget.showUDToggle) ...[
                            SizedBox(width: scaleSize(12)),
                            _buildQuickToggle(
                              'DU',
                              Icons.water_drop,
                              isUDEnabled,
                              () => toggleUniversalDividends(ref, widget.address!),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Active filters count
                    if (totalActiveFilters > 0) ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: scaleSize(8), vertical: scaleSize(4)),
                        decoration: BoxDecoration(
                          color: context.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          totalActiveFilters.toString(),
                          style: scaledTextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(width: scaleSize(8)),
                    ],

                    // Expand/collapse icon
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: _isExpanded ? 0.5 : 0.0,
                      child: Icon(Icons.expand_more, size: scaleSize(20), color: context.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Expanded filter content
          if (_isExpanded)
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: EdgeInsets.only(top: scaleSize(8)),
                  padding: EdgeInsets.all(scaleSize(16)),
                  decoration: BoxDecoration(
                    color: context.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.2), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Address search for account mode OR direction filters for network mode
                      if (widget.mode == FilterMode.account) ...[
                        _buildFilterField(
                          label: 'searchAddressOrName'.tr(),
                          controller: _addressController,
                          hintText: 'enterAddressOrName'.tr(),
                          icon: Icons.person_search,
                          isExactMatch: _localExactMatchAddress,
                          onExactMatchChanged: () {
                            setState(() {
                              _localExactMatchAddress = !_localExactMatchAddress;
                            });
                          },
                        ),
                        SizedBox(height: scaleSize(16)),
                      ] else ...[
                        // Direction filters for network mode
                        _buildFilterField(
                          label: 'fromAddressOrName'.tr(),
                          controller: _fromAddressController,
                          hintText: 'enterFromAddressOrName'.tr(),
                          icon: Icons.call_made,
                          isExactMatch: _localExactMatchDirection,
                          onExactMatchChanged: () {
                            setState(() {
                              _localExactMatchDirection = !_localExactMatchDirection;
                            });
                          },
                        ),
                        SizedBox(height: scaleSize(16)),
                        _buildFilterField(
                          label: 'toAddressOrName'.tr(),
                          controller: _toAddressController,
                          hintText: 'enterToAddressOrName'.tr(),
                          icon: Icons.call_received,
                          isExactMatch: _localExactMatchDirection,
                          onExactMatchChanged: () {
                            setState(() {
                              _localExactMatchDirection = !_localExactMatchDirection;
                            });
                          },
                        ),
                        SizedBox(height: scaleSize(16)),
                      ],

                      // Comment search (common to both modes)
                      _buildFilterField(
                        label: 'searchComment'.tr(),
                        controller: _commentController,
                        hintText: 'enterCommentKeywords'.tr(),
                        icon: Icons.comment_outlined,
                        isExactMatch: _localExactMatchComment,
                        onExactMatchChanged: () {
                          setState(() {
                            _localExactMatchComment = !_localExactMatchComment;
                          });
                        },
                      ),

                      SizedBox(height: scaleSize(16)),

                      // Date range (common to both modes)
                      _buildDateRangeFilter(),

                      SizedBox(height: scaleSize(16)),

                      // Amount range (common to both modes)
                      _buildAmountRangeFilter(),

                      SizedBox(height: scaleSize(16)),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                _clearAllFilters();
                                _toggleExpanded(); // Close the popup after clearing
                              },
                              style: TextButton.styleFrom(foregroundColor: context.colorScheme.onSurfaceVariant),
                              child: Text('clearAll'.tr()),
                            ),
                          ),
                          SizedBox(width: scaleSize(12)),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _applyAdvancedFilters();
                                _toggleExpanded(); // Close the popup after applying
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: Text('done'.tr()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickToggle(String label, IconData icon, bool isActive, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: EdgeInsets.symmetric(horizontal: scaleSize(12), vertical: scaleSize(6)),
          decoration: BoxDecoration(
            color: isActive ? context.colorScheme.primary.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? context.colorScheme.primary.withValues(alpha: 0.4)
                  : context.colorScheme.outline.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: scaleSize(14),
                color: isActive ? context.colorScheme.primary : context.colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: scaleSize(4)),
              Text(
                label,
                style: scaledTextStyle(
                  fontSize: 12,
                  color: isActive ? context.colorScheme.primary : context.colorScheme.onSurfaceVariant,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool? isExactMatch,
    VoidCallback? onExactMatchChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: scaledTextStyle(
                  fontSize: 13,
                  color: context.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isExactMatch != null && onExactMatchChanged != null) ...[
              SizedBox(width: scaleSize(8)),
              InkWell(
                onTap: onExactMatchChanged,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: EdgeInsets.all(scaleSize(4)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: isExactMatch,
                        onChanged: (_) => onExactMatchChanged(),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      SizedBox(width: scaleSize(4)),
                      Text(
                        'exactMatch'.tr(),
                        style: scaledTextStyle(fontSize: 11, color: context.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: scaleSize(6)),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, size: scaleSize(20)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: context.colorScheme.outline.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: context.colorScheme.outline.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: context.colorScheme.primary, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: scaleSize(12), vertical: scaleSize(12)),
            isDense: true,
          ),
          style: scaledTextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'dateRange'.tr(),
          style: scaledTextStyle(
            fontSize: 13,
            color: context.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: scaleSize(6)),
        Row(
          children: [
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _selectDateRange,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: scaleSize(12), vertical: scaleSize(12)),
                    decoration: BoxDecoration(
                      border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.date_range, size: scaleSize(20), color: context.colorScheme.onSurfaceVariant),
                        SizedBox(width: scaleSize(8)),
                        Expanded(
                          child: Text(
                            _startDate != null && _endDate != null
                                ? '${DateFormat('dd/MM/yy').format(_startDate!)} - ${DateFormat('dd/MM/yy').format(_endDate!)}'
                                : 'selectDateRange'.tr(),
                            style: scaledTextStyle(
                              fontSize: 14,
                              color: _startDate != null && _endDate != null
                                  ? context.colorScheme.onSurface
                                  : context.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_startDate != null || _endDate != null) ...[
              SizedBox(width: scaleSize(8)),
              IconButton(
                onPressed: _clearDateRange,
                icon: Icon(Icons.clear, size: scaleSize(20)),
                style: IconButton.styleFrom(
                  backgroundColor: context.colorScheme.errorContainer,
                  foregroundColor: context.colorScheme.onErrorContainer,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildAmountRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'amountRange'.tr(),
          style: scaledTextStyle(
            fontSize: 13,
            color: context.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: scaleSize(6)),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'minimum'.tr(),
                  prefixIcon: Icon(Icons.trending_up, size: scaleSize(20)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: context.colorScheme.outline.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: context.colorScheme.outline.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: context.colorScheme.primary, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: scaleSize(12), vertical: scaleSize(12)),
                  isDense: true,
                ),
                style: scaledTextStyle(fontSize: 14),
              ),
            ),
            SizedBox(width: scaleSize(12)),
            Expanded(
              child: TextField(
                controller: _maxAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'maximum'.tr(),
                  prefixIcon: Icon(Icons.trending_down, size: scaleSize(20)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: context.colorScheme.outline.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: context.colorScheme.outline.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: context.colorScheme.primary, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: scaleSize(12), vertical: scaleSize(12)),
                  isDense: true,
                ),
                style: scaledTextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
