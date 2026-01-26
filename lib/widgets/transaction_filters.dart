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
class TransactionFilters extends ConsumerStatefulWidget {
  const TransactionFilters({super.key, required this.mode, this.address});

  final FilterMode mode;
  final String? address; // Only needed for account mode

  @override
  ConsumerState<TransactionFilters> createState() => _TransactionFiltersState();
}

class _TransactionFiltersState extends ConsumerState<TransactionFilters> {
  bool _isExpanded = false;

  // Minimum date for transaction filtering (G1 blockchain start)
  static final DateTime _minSelectableDate = DateTime(2017, 3, 8);

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
    // Load current filter values
    _loadCurrentFilters();
  }

  void _loadCurrentFilters() {
    if (!mounted) return; // Check if widget is still mounted before using ref

    final filters = widget.mode == FilterMode.network
        ? ref.read(networkFiltersProvider)
        : ref.read(transactionFiltersProvider);

    // Clear or set address/name search
    try {
      if (filters.addressOrNameSearch?.isNotEmpty == true) {
        _addressController.text = filters.addressOrNameSearch!;
      } else {
        _addressController.clear();
      }
    } catch (e) {
      // Controller might be disposed, ignore
    }

    // Clear or set comment search (disabled for network mode)
    try {
      if (widget.mode == FilterMode.network) {
        _commentController.clear();
      } else if (filters.commentSearch?.isNotEmpty == true) {
        _commentController.text = filters.commentSearch!;
      } else {
        _commentController.clear();
      }
    } catch (e) {
      // Controller might be disposed, ignore
    }

    _startDate = filters.dateRange.startDate;
    _endDate = filters.dateRange.endDate;

    // Clear or set amount range
    try {
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
    } catch (e) {
      // Controllers might be disposed, ignore
    }

    // Load direction filters for network mode
    try {
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
    } catch (e) {
      // Controllers might be disposed, ignore
    }

    // Load exact match states from provider
    _localExactMatchAddress = filters.exactMatchAddress;
    _localExactMatchComment = filters.exactMatchComment;
    _localExactMatchDirection = filters.exactMatchDirection;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _commentController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _fromAddressController.dispose();
    _toAddressController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    if (!mounted) return; // Check if widget is still mounted before using ref

    setState(() {
      _isExpanded = !_isExpanded;
    });

    // Update the appropriate provider state
    if (widget.mode == FilterMode.network) {
      ref.read(networkFilterPanelExpandedProvider.notifier).set(_isExpanded);
    } else {
      ref.read(filterPanelExpandedProvider.notifier).set(_isExpanded);
    }

    if (_isExpanded) {
      // Show modal bottom sheet instead of inline expansion
      _showFiltersBottomSheet();
    }
  }

  void _showFiltersBottomSheet() {
    if (!mounted) return;

    // Load current filter values before showing
    _loadCurrentFilters();

    // Create local controllers for the modal to avoid using disposed parent controllers
    final modalAddressController = TextEditingController(text: _addressController.text);
    final modalCommentController = TextEditingController(text: _commentController.text);
    final modalMinAmountController = TextEditingController(text: _minAmountController.text);
    final modalMaxAmountController = TextEditingController(text: _maxAmountController.text);
    final modalFromAddressController = TextEditingController(text: _fromAddressController.text);
    final modalToAddressController = TextEditingController(text: _toAddressController.text);

    // Local state for dates and exact match (copy from parent)
    DateTime? modalStartDate = _startDate;
    DateTime? modalEndDate = _endDate;
    bool modalExactMatchAddress = _localExactMatchAddress;
    bool modalExactMatchComment = _localExactMatchComment;
    bool modalExactMatchDirection = _localExactMatchDirection;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow full height control
      backgroundColor: Colors.transparent,
      isDismissible: true, // Allow dismissal by tapping outside
      enableDrag: true, // Allow drag to dismiss
      builder: (context) => StatefulBuilder(
        builder: (modalContext, setModalState) => Container(
          height: MediaQuery.of(modalContext).size.height * 0.8, // 80% of screen height
          decoration: BoxDecoration(
            color: modalContext.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -2)),
            ],
          ),
          child: Column(
            children: [
              // Handle bar for dragging
              Container(
                margin: EdgeInsets.only(top: scaleSize(12)),
                width: scaleSize(40),
                height: scaleSize(4),
                decoration: BoxDecoration(
                  color: modalContext.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: EdgeInsets.all(scaleSize(16)),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'advancedFilters'.tr(),
                        style: scaledTextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: modalContext.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(modalContext),
                      icon: Icon(Icons.close, size: scaleSize(24)),
                      style: IconButton.styleFrom(
                        backgroundColor: modalContext.colorScheme.surfaceContainer,
                        foregroundColor: modalContext.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: scaleSize(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Address search for account mode OR direction filters for network mode
                      if (widget.mode == FilterMode.account) ...[
                        _buildFilterFieldModal(
                          modalContext,
                          setModalState,
                          label: 'searchAddressOrName'.tr(),
                          controller: modalAddressController,
                          hintText: 'enterAddressOrName'.tr(),
                          icon: Icons.person_search,
                          isExactMatch: modalExactMatchAddress,
                          onExactMatchChanged: () {
                            setModalState(() {
                              modalExactMatchAddress = !modalExactMatchAddress;
                            });
                          },
                        ),
                        SizedBox(height: scaleSize(16)),
                      ] else if (widget.mode == FilterMode.network) ...[
                        _buildFilterFieldModal(
                          modalContext,
                          setModalState,
                          label: 'fromAddressOrName'.tr(),
                          controller: modalFromAddressController,
                          hintText: 'enterFromAddressOrName'.tr(),
                          icon: Icons.call_made,
                          isExactMatch: modalExactMatchDirection,
                          onExactMatchChanged: () {
                            setModalState(() {
                              modalExactMatchDirection = !modalExactMatchDirection;
                            });
                          },
                        ),
                        SizedBox(height: scaleSize(16)),
                        _buildFilterFieldModal(
                          modalContext,
                          setModalState,
                          label: 'toAddressOrName'.tr(),
                          controller: modalToAddressController,
                          hintText: 'enterToAddressOrName'.tr(),
                          icon: Icons.call_received,
                          isExactMatch: modalExactMatchDirection,
                          onExactMatchChanged: () {
                            setModalState(() {
                              modalExactMatchDirection = !modalExactMatchDirection;
                            });
                          },
                        ),
                        SizedBox(height: scaleSize(16)),
                      ],

                      // Comment search
                      _buildFilterFieldModal(
                        modalContext,
                        setModalState,
                        label: 'searchComment'.tr(),
                        controller: modalCommentController,
                        hintText: widget.mode == FilterMode.network
                            ? 'commentFilterDisabledNetwork'.tr()
                            : 'enterCommentKeywords'.tr(),
                        icon: Icons.comment_outlined,
                        isExactMatch: modalExactMatchComment,
                        onExactMatchChanged: widget.mode == FilterMode.network
                            ? null
                            : () {
                                setModalState(() {
                                  modalExactMatchComment = !modalExactMatchComment;
                                });
                              },
                        enabled: widget.mode != FilterMode.network,
                      ),

                      SizedBox(height: scaleSize(16)),

                      // Date range
                      _buildDateRangeFilterModalWithState(
                        modalContext,
                        setModalState,
                        startDate: modalStartDate,
                        endDate: modalEndDate,
                        onStartDateChanged: (date) {
                          setModalState(() {
                            modalStartDate = date;
                          });
                        },
                        onEndDateChanged: (date) {
                          setModalState(() {
                            modalEndDate = date;
                          });
                        },
                      ),

                      SizedBox(height: scaleSize(16)),

                      // Amount range
                      _buildAmountRangeFilterModalWithControllers(
                        modalContext,
                        setModalState,
                        minController: modalMinAmountController,
                        maxController: modalMaxAmountController,
                      ),

                      SizedBox(height: scaleSize(16)),

                      // Bottom padding to ensure content is not hidden behind sticky buttons
                      SizedBox(height: scaleSize(100)),
                    ],
                  ),
                ),
              ),

              // Sticky action buttons at bottom
              Container(
                decoration: BoxDecoration(
                  color: modalContext.colorScheme.surface,
                  border: Border(
                    top: BorderSide(color: modalContext.colorScheme.outline.withValues(alpha: 0.2), width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2)),
                  ],
                ),
                padding: EdgeInsets.fromLTRB(
                  scaleSize(16),
                  scaleSize(16),
                  scaleSize(16),
                  scaleSize(16) + MediaQuery.of(modalContext).padding.bottom,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          // Clear all modal controllers
                          modalAddressController.clear();
                          modalCommentController.clear();
                          modalMinAmountController.clear();
                          modalMaxAmountController.clear();
                          modalFromAddressController.clear();
                          modalToAddressController.clear();
                          setModalState(() {
                            modalStartDate = null;
                            modalEndDate = null;
                            modalExactMatchAddress = false;
                            modalExactMatchComment = false;
                            modalExactMatchDirection = false;
                          });
                          // Apply the cleared filters
                          _clearAllFilters();
                          Navigator.pop(modalContext);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: modalContext.colorScheme.onSurfaceVariant,
                          padding: EdgeInsets.symmetric(vertical: scaleSize(10)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'clearAll'.tr(),
                          style: scaledTextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: modalContext.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: scaleSize(12)),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Apply filters using modal controller values
                          _applyAdvancedFiltersFromModal(
                            addressText: modalAddressController.text,
                            commentText: modalCommentController.text,
                            minAmountText: modalMinAmountController.text,
                            maxAmountText: modalMaxAmountController.text,
                            fromAddressText: modalFromAddressController.text,
                            toAddressText: modalToAddressController.text,
                            startDate: modalStartDate,
                            endDate: modalEndDate,
                            exactMatchAddress: modalExactMatchAddress,
                            exactMatchComment: modalExactMatchComment,
                            exactMatchDirection: modalExactMatchDirection,
                          );
                          Navigator.pop(modalContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: modalContext.colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          padding: EdgeInsets.symmetric(vertical: scaleSize(10)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          shadowColor: modalContext.colorScheme.primary.withValues(alpha: 0.3),
                        ),
                        child: Text(
                          'done'.tr(),
                          style: scaledTextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      // Note: We intentionally do NOT dispose the modal controllers here.
      // Disposing them while the modal animation is completing can cause
      // "TextEditingController was used after being disposed" errors.
      // The controllers will be garbage collected when they're no longer referenced.

      // Reset expanded state when bottom sheet closes
      if (mounted) {
        setState(() {
          _isExpanded = false;
        });
        // Only update provider if widget is still mounted
        if (widget.mode == FilterMode.network) {
          ref.read(networkFilterPanelExpandedProvider.notifier).set(false);
        } else {
          ref.read(filterPanelExpandedProvider.notifier).set(false);
        }
      }
    });
  }

  /// Apply filters from modal values (avoids using potentially disposed parent controllers)
  void _applyAdvancedFiltersFromModal({
    required String addressText,
    required String commentText,
    required String minAmountText,
    required String maxAmountText,
    required String fromAddressText,
    required String toAddressText,
    required DateTime? startDate,
    required DateTime? endDate,
    required bool exactMatchAddress,
    required bool exactMatchComment,
    required bool exactMatchDirection,
  }) {
    if (!mounted) return;

    final filtersNotifier = widget.mode == FilterMode.network
        ? ref.read(networkFiltersProvider.notifier)
        : ref.read(transactionFiltersProvider.notifier);

    if (widget.mode == FilterMode.account) {
      filtersNotifier.updateAddressOrNameSearch(addressText.trim());
    } else {
      filtersNotifier.updateDirectionFilter(fromAddressText.trim(), toAddressText.trim());
    }

    if (widget.mode != FilterMode.network) {
      filtersNotifier.updateCommentSearch(commentText.trim());
    } else {
      filtersNotifier.updateCommentSearch('');
    }

    filtersNotifier.updateDateRange(startDate, endDate);

    final minAmount = minAmountText.trim().isEmpty
        ? null
        : convertAmountToBigInt(double.tryParse(minAmountText.trim()) ?? 0);
    final maxAmount = maxAmountText.trim().isEmpty
        ? null
        : convertAmountToBigInt(double.tryParse(maxAmountText.trim()) ?? 0);

    filtersNotifier.updateAmountRange(minAmount, maxAmount);

    filtersNotifier.updateExactMatchAddress(exactMatchAddress);
    filtersNotifier.updateExactMatchComment(exactMatchComment);
    if (widget.mode == FilterMode.network) {
      filtersNotifier.updateExactMatchDirection(exactMatchDirection);
    }
  }

  void _clearAllFilters() {
    if (!mounted) return; // Check if widget is still mounted before using ref

    final filtersNotifier = widget.mode == FilterMode.network
        ? ref.read(networkFiltersProvider.notifier)
        : ref.read(transactionFiltersProvider.notifier);

    filtersNotifier.clearAllFilters();

    if (mounted) {
      setState(() {
        try {
          _addressController.clear();
          _commentController.clear();
          _minAmountController.clear();
          _maxAmountController.clear();
          _fromAddressController.clear();
          _toAddressController.clear();
        } catch (e) {
          // Controllers might be disposed, ignore
        }
        _startDate = null;
        _endDate = null;
        // Reset local exact match states
        _localExactMatchAddress = false;
        _localExactMatchComment = false;
        _localExactMatchDirection = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = widget.mode == FilterMode.network
        ? ref.watch(networkFiltersProvider)
        : ref.watch(transactionFiltersProvider);

    final hasAdvancedFilters = filters.hasActiveFilters;

    // Check for UDs if in account mode
    bool hasUDs = false;
    bool isUDEnabled = false;
    if (widget.mode == FilterMode.account && widget.address != null) {
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
                          if (widget.mode == FilterMode.account && hasUDs) ...[
                            SizedBox(width: scaleSize(12)),
                            _buildQuickToggle(
                              'udShort'.tr(),
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

                    // Filter icon
                    Icon(Icons.tune, size: scaleSize(20), color: context.colorScheme.onSurfaceVariant),
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

  Widget _buildFilterFieldModal(
    BuildContext modalContext,
    StateSetter setModalState, {
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool isExactMatch,
    VoidCallback? onExactMatchChanged,
    bool enabled = true,
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
                  color: modalContext.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onExactMatchChanged != null && enabled) ...[
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
                        style: scaledTextStyle(fontSize: 11, color: modalContext.colorScheme.onSurfaceVariant),
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
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: scaledTextStyle(
              fontSize: 14,
              color: enabled
                  ? modalContext.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
                  : modalContext.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            prefixIcon: Icon(
              icon,
              size: scaleSize(20),
              color: enabled
                  ? modalContext.colorScheme.onSurfaceVariant
                  : modalContext.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: modalContext.colorScheme.outline.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: modalContext.colorScheme.outline.withValues(alpha: 0.3)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: modalContext.colorScheme.outline.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: modalContext.colorScheme.primary, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: scaleSize(12), vertical: scaleSize(12)),
            isDense: true,
          ),
          style: scaledTextStyle(
            fontSize: 14,
            color: enabled
                ? modalContext.colorScheme.onSurface
                : modalContext.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountRangeFilterModalWithControllers(
    BuildContext modalContext,
    StateSetter setModalState, {
    required TextEditingController minController,
    required TextEditingController maxController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'amountRange'.tr(),
          style: scaledTextStyle(
            fontSize: 13,
            color: modalContext.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: scaleSize(6)),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: minController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'minimum'.tr(),
                  hintStyle: scaledTextStyle(
                    fontSize: 14,
                    color: modalContext.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  prefixIcon: Icon(Icons.trending_up, size: scaleSize(20)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: modalContext.colorScheme.outline.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: modalContext.colorScheme.outline.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: modalContext.colorScheme.primary, width: 2),
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
                controller: maxController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'maximum'.tr(),
                  hintStyle: scaledTextStyle(
                    fontSize: 14,
                    color: modalContext.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  prefixIcon: Icon(Icons.trending_down, size: scaleSize(20)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: modalContext.colorScheme.outline.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: modalContext.colorScheme.outline.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: modalContext.colorScheme.primary, width: 2),
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

  Widget _buildDateRangeFilterModalWithState(
    BuildContext modalContext,
    StateSetter setModalState, {
    required DateTime? startDate,
    required DateTime? endDate,
    required void Function(DateTime?) onStartDateChanged,
    required void Function(DateTime?) onEndDateChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'dateRange'.tr(),
          style: scaledTextStyle(
            fontSize: 13,
            color: modalContext.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: scaleSize(8)),

        Row(
          children: [
            // Start date field
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate ?? DateTime.now(),
                    firstDate: _minSelectableDate,
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(colorScheme: context.colorScheme),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    onStartDateChanged(picked);
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: scaleSize(12), vertical: scaleSize(12)),
                  decoration: BoxDecoration(
                    border: Border.all(color: modalContext.colorScheme.outline.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: scaleSize(16), color: modalContext.colorScheme.onSurfaceVariant),
                      SizedBox(width: scaleSize(8)),
                      Expanded(
                        child: Text(
                          startDate != null ? DateFormat('dd/MM/yyyy').format(startDate) : 'startDate'.tr(),
                          style: scaledTextStyle(
                            fontSize: 14,
                            color: startDate != null
                                ? modalContext.colorScheme.onSurface
                                : modalContext.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      if (startDate != null)
                        GestureDetector(
                          onTap: () => onStartDateChanged(null),
                          child: Icon(
                            Icons.close,
                            size: scaleSize(16),
                            color: modalContext.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(width: scaleSize(12)),

            // End date field
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: endDate ?? DateTime.now(),
                    firstDate: _minSelectableDate,
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(colorScheme: context.colorScheme),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    onEndDateChanged(picked);
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: scaleSize(12), vertical: scaleSize(12)),
                  decoration: BoxDecoration(
                    border: Border.all(color: modalContext.colorScheme.outline.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: scaleSize(16), color: modalContext.colorScheme.onSurfaceVariant),
                      SizedBox(width: scaleSize(8)),
                      Expanded(
                        child: Text(
                          endDate != null ? DateFormat('dd/MM/yyyy').format(endDate) : 'endDate'.tr(),
                          style: scaledTextStyle(
                            fontSize: 14,
                            color: endDate != null
                                ? modalContext.colorScheme.onSurface
                                : modalContext.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      if (endDate != null)
                        GestureDetector(
                          onTap: () => onEndDateChanged(null),
                          child: Icon(
                            Icons.close,
                            size: scaleSize(16),
                            color: modalContext.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // Clear all dates button
        if (startDate != null || endDate != null) ...[
          SizedBox(height: scaleSize(8)),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                onStartDateChanged(null);
                onEndDateChanged(null);
              },
              icon: Icon(Icons.clear_all, size: scaleSize(16)),
              label: Text('clearDates'.tr()),
              style: TextButton.styleFrom(
                foregroundColor: modalContext.colorScheme.error,
                padding: EdgeInsets.symmetric(horizontal: scaleSize(8), vertical: scaleSize(4)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
