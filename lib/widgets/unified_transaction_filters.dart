import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/transaction_display_item.dart';
import 'package:gecko/providers/settings_provider.dart';
import 'package:gecko/providers/transaction_history_providers.dart';
import 'package:gecko/providers/transaction_filters_provider.dart';

/// Unified transaction filters widget combining UD toggle and advanced filters
class UnifiedTransactionFilters extends ConsumerStatefulWidget {
  const UnifiedTransactionFilters({super.key, required this.address});

  final String address;

  @override
  ConsumerState<UnifiedTransactionFilters> createState() => _UnifiedTransactionFiltersState();
}

class _UnifiedTransactionFiltersState extends ConsumerState<UnifiedTransactionFilters>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isExpanded = false;
  bool _hasCheckedForUDs = false;

  // Controllers for advanced filters
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  // No debounce timers needed - filters apply only on "Done"

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
    final filters = ref.read(transactionFiltersProvider);
    _addressController.text = filters.addressOrNameSearch ?? '';
    _commentController.text = filters.commentSearch ?? '';
    _startDate = filters.dateRange.startDate;
    _endDate = filters.dateRange.endDate;

    if (filters.amountRange.minAmount != null) {
      _minAmountController.text = convertBigIntToAmount(filters.amountRange.minAmount).toString();
    }
    if (filters.amountRange.maxAmount != null) {
      _maxAmountController.text = convertBigIntToAmount(filters.amountRange.maxAmount).toString();
    }
  }

  @override
  void dispose() {
    // Note: Not resetting filterPanelExpandedProvider here to avoid ref usage after disposal
    // The provider will clean up automatically when no longer watched

    _animationController.dispose();
    _addressController.dispose();
    _commentController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    // Update the provider state
    ref.read(filterPanelExpandedProvider.notifier).state = _isExpanded;

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _applyAdvancedFilters() {
    final filtersNotifier = ref.read(transactionFiltersProvider.notifier);

    // Apply address/name filter
    filtersNotifier.updateAddressOrNameSearch(_addressController.text);

    // Apply comment filter
    filtersNotifier.updateCommentSearch(_commentController.text);

    // Apply date range filter
    filtersNotifier.updateDateRange(_startDate, _endDate);

    // Apply amount range filter
    final minAmount = _minAmountController.text.isEmpty
        ? null
        : convertAmountToBigInt(double.tryParse(_minAmountController.text));
    final maxAmount = _maxAmountController.text.isEmpty
        ? null
        : convertAmountToBigInt(double.tryParse(_maxAmountController.text));
    filtersNotifier.updateAmountRange(minAmount, maxAmount);
  }

  void _clearAllFilters() {
    final filtersNotifier = ref.read(transactionFiltersProvider.notifier);
    filtersNotifier.clearAllFilters();

    setState(() {
      _addressController.clear();
      _commentController.clear();
      _minAmountController.clear();
      _maxAmountController.clear();
      _startDate = null;
      _endDate = null;
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
      final filtersNotifier = ref.read(transactionFiltersProvider.notifier);
      filtersNotifier.updateDateRange(_startDate, _endDate);
    }
  }

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    final filtersNotifier = ref.read(transactionFiltersProvider.notifier);
    filtersNotifier.updateDateRange(null, null);
  }

  @override
  Widget build(BuildContext context) {
    final isUDEnabled = ref.watch(universalDividendsToggleProvider);
    final hasAdvancedFilters = ref.watch(transactionFiltersProvider).hasActiveFilters;

    // Check if UDs are available
    final combinedState = ref.watch(combinedHistoryProvider(widget.address));
    final hasUDs = combinedState.transactions.any(
      (transaction) => transaction.type == TransactionType.universalDividend,
    );

    // Animate in when UDs are detected for the first time
    if (hasUDs && !_hasCheckedForUDs) {
      _hasCheckedForUDs = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _animationController.forward();
        }
      });
    }

    final totalActiveFilters =
        (hasAdvancedFilters ? ref.read(transactionFiltersProvider).activeFilterCount : 0) +
        (hasUDs && isUDEnabled ? 1 : 0);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: scaleSize(16),
        vertical: scaleSize(2),
      ), // Further reduced vertical margin
      child: Column(
        children: [
          // Unified header with all filter options - always visible
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleExpanded,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: scaleSize(16),
                  vertical: scaleSize(6),
                ), // Further reduced vertical padding
                decoration: BoxDecoration(
                  color: totalActiveFilters > 0
                      ? context.colorScheme.primary.withValues(alpha: 0.08) // More subtle when active
                      : context.colorScheme.surface.withValues(alpha: 0.95), // Semi-transparent background
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: totalActiveFilters > 0
                        ? context.colorScheme.primary.withValues(alpha: 0.2) // More subtle border
                        : context.colorScheme.outline.withValues(alpha: 0.1), // Very subtle border
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

                    // Quick filters in the header
                    Expanded(
                      child: Row(
                        children: [
                          // Advanced filters indicator first
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

                          // UD toggle to the right if available
                          if (hasUDs) ...[
                            SizedBox(width: scaleSize(12)),
                            _buildQuickToggle(
                              'DU',
                              Icons.water_drop,
                              isUDEnabled,
                              () => toggleUniversalDividends(ref, widget.address),
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

          // Expanded advanced filters - animated only when expanded
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
                      // Address/Name search
                      _buildFilterField(
                        label: 'searchAddressOrName'.tr(),
                        controller: _addressController,
                        hintText: 'enterAddressOrName'.tr(),
                        icon: Icons.person_search,
                      ),

                      SizedBox(height: scaleSize(16)),

                      // Comment search
                      _buildFilterField(
                        label: 'searchComment'.tr(),
                        controller: _commentController,
                        hintText: 'enterCommentKeywords'.tr(),
                        icon: Icons.comment_outlined,
                      ),

                      SizedBox(height: scaleSize(16)),

                      // Date range
                      _buildDateRangeFilter(),

                      SizedBox(height: scaleSize(16)),

                      // Amount range
                      _buildAmountRangeFilter(),

                      SizedBox(height: scaleSize(16)),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: (hasAdvancedFilters || (hasUDs && isUDEnabled))
                                  ? () {
                                      _clearAllFilters();
                                      if (hasUDs && isUDEnabled) {
                                        toggleUniversalDividends(ref, widget.address);
                                      }
                                      _toggleExpanded(); // Close the popup after clearing
                                    }
                                  : null,
                              style: TextButton.styleFrom(foregroundColor: context.colorScheme.onSurfaceVariant),
                              child: Text('clearAll'.tr()),
                            ),
                          ),
                          SizedBox(width: scaleSize(12)),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _applyAdvancedFilters();
                                _toggleExpanded(); // This will close and update the provider
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: scaledTextStyle(
            fontSize: 13,
            color: context.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: scaleSize(6)),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, size: scaleSize(18)),
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
              borderSide: BorderSide(color: context.colorScheme.primary),
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
                        Icon(Icons.date_range, size: scaleSize(18), color: context.colorScheme.onSurfaceVariant),
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
                                  : context.colorScheme.onSurfaceVariant,
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
                icon: Icon(Icons.clear, size: scaleSize(18)),
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
                  hintText: 'min'.tr(),
                  prefixIcon: Icon(Icons.trending_up, size: scaleSize(18)),
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
                    borderSide: BorderSide(color: context.colorScheme.primary),
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
                  hintText: 'max'.tr(),
                  prefixIcon: Icon(Icons.trending_down, size: scaleSize(18)),
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
                    borderSide: BorderSide(color: context.colorScheme.primary),
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
