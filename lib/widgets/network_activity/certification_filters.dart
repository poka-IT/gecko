import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/transaction_filters.dart';
import 'package:gecko/providers/certification_filters_provider.dart';

/// Certification filters widget for filtering network certification activity
class CertificationFilters extends ConsumerStatefulWidget {
  const CertificationFilters({super.key});

  @override
  ConsumerState<CertificationFilters> createState() => _CertificationFiltersState();
}

class _CertificationFiltersState extends ConsumerState<CertificationFilters> {
  bool _isExpanded = false;

  // Minimum date for certification filtering (G1 blockchain start)
  static final DateTime _minSelectableDate = DateTime(2017, 3, 8);

  // Controllers for filters
  final TextEditingController _issuerController = TextEditingController();
  final TextEditingController _receiverController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  // Local state for exact match checkboxes (only applied when clicking "Done")
  bool _localExactMatchIssuer = false;
  bool _localExactMatchReceiver = false;

  // Local state for show active only checkbox
  bool? _localShowActiveOnly;

  @override
  void initState() {
    super.initState();
    // Load current filter values
    _loadCurrentFilters();
  }

  void _loadCurrentFilters() {
    if (!mounted) return; // Check if widget is still mounted before using ref

    final filters = ref.read(certificationFiltersProvider);

    // Clear or set issuer search
    try {
      if (filters.issuerSearch?.isNotEmpty == true) {
        _issuerController.text = filters.issuerSearch!;
      } else {
        _issuerController.clear();
      }
    } catch (e) {
      // Controller might be disposed, ignore
    }

    // Clear or set receiver search
    try {
      if (filters.receiverSearch?.isNotEmpty == true) {
        _receiverController.text = filters.receiverSearch!;
      } else {
        _receiverController.clear();
      }
    } catch (e) {
      // Controller might be disposed, ignore
    }

    _startDate = filters.dateRange.startDate;
    _endDate = filters.dateRange.endDate;
    _localExactMatchIssuer = filters.exactMatchIssuer;
    _localExactMatchReceiver = filters.exactMatchReceiver;
    _localShowActiveOnly = filters.showActiveOnly;
  }

  @override
  void dispose() {
    _issuerController.dispose();
    _receiverController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(StateSetter? setModalState) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: _minSelectableDate,
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _startDate) {
      void updateState() {
        _startDate = picked;
        // Ensure end date is not before start date
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      }

      // Update both local state and modal state if available
      setState(updateState);
      if (setModalState != null) {
        setModalState(updateState);
      }
    }
  }

  Future<void> _selectEndDate(StateSetter? setModalState) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? _minSelectableDate,
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _endDate) {
      void updateState() {
        _endDate = picked;
      }

      // Update both local state and modal state if available
      setState(updateState);
      if (setModalState != null) {
        setModalState(updateState);
      }
    }
  }

  void _applyFilters() {
    final notifier = ref.read(certificationFiltersProvider.notifier);

    // Apply issuer search
    notifier.updateIssuerSearch(_issuerController.text.trim().isEmpty ? null : _issuerController.text.trim());

    // Apply receiver search
    notifier.updateReceiverSearch(_receiverController.text.trim().isEmpty ? null : _receiverController.text.trim());

    // Apply date range
    notifier.updateDateRange(DateRangeFilter(startDate: _startDate, endDate: _endDate));

    // Apply exact match settings
    notifier.updateExactMatchIssuer(_localExactMatchIssuer);
    notifier.updateExactMatchReceiver(_localExactMatchReceiver);

    // Apply show active only setting
    notifier.updateShowActiveOnly(_localShowActiveOnly);

    // Collapse the panel
    setState(() {
      _isExpanded = false;
    });
    ref.read(certificationFilterPanelExpandedProvider.notifier).set(false);
  }

  void _resetFilters() {
    ref.read(certificationFiltersProvider.notifier).reset();
    _loadCurrentFilters();
    setState(() {
      _isExpanded = false;
    });
    ref.read(certificationFilterPanelExpandedProvider.notifier).set(false);
  }

  void _toggleExpanded() {
    if (!mounted) return; // Check if widget is still mounted before using ref

    setState(() {
      _isExpanded = !_isExpanded;
    });

    // Update the provider state
    ref.read(certificationFilterPanelExpandedProvider.notifier).set(_isExpanded);

    if (_isExpanded) {
      // Show modal bottom sheet instead of inline expansion
      _showFiltersBottomSheet();
    }
  }

  void _showFiltersBottomSheet() {
    if (!mounted) return;

    // Load current filter values before showing
    _loadCurrentFilters();

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
                        'filterCertifications'.tr(),
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
                      // Issuer search
                      _buildFilterFieldModal(
                        modalContext,
                        setModalState,
                        label: 'issuerName'.tr(),
                        controller: _issuerController,
                        hintText: 'searchByIssuerName'.tr(),
                        icon: Icons.person_search,
                        isExactMatch: _localExactMatchIssuer,
                        onExactMatchChanged: () {
                          setModalState(() {
                            _localExactMatchIssuer = !_localExactMatchIssuer;
                          });
                        },
                      ),

                      SizedBox(height: scaleSize(16)),

                      // Receiver search
                      _buildFilterFieldModal(
                        modalContext,
                        setModalState,
                        label: 'receiverName'.tr(),
                        controller: _receiverController,
                        hintText: 'searchByReceiverName'.tr(),
                        icon: Icons.person_search,
                        isExactMatch: _localExactMatchReceiver,
                        onExactMatchChanged: () {
                          setModalState(() {
                            _localExactMatchReceiver = !_localExactMatchReceiver;
                          });
                        },
                      ),

                      SizedBox(height: scaleSize(16)),

                      // Active status filter
                      _buildStatusFilterModal(modalContext, setModalState),

                      SizedBox(height: scaleSize(16)),

                      // Date range
                      _buildDateRangeFilterModal(modalContext, setModalState),

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
                          _resetFilters();
                          Navigator.of(modalContext).pop();
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
                          _applyFilters();
                          Navigator.of(modalContext).pop();
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
      // Reset expanded state when bottom sheet closes
      if (mounted) {
        setState(() {
          _isExpanded = false;
        });
        ref.read(certificationFilterPanelExpandedProvider.notifier).set(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(certificationFiltersProvider);
    final totalActiveFilters = filters.activeFilterCount;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(2)),
      child: Material(
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
                  color: totalActiveFilters > 0 ? context.colorScheme.primary : context.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: scaleSize(12)),
                Expanded(
                  child: Text(
                    'filters'.tr(),
                    style: scaledTextStyle(
                      fontSize: 14,
                      color: totalActiveFilters > 0
                          ? context.colorScheme.primary
                          : context.colorScheme.onSurfaceVariant,
                      fontWeight: totalActiveFilters > 0 ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
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
                Icon(Icons.tune, size: scaleSize(20), color: context.colorScheme.onSurfaceVariant),
              ],
            ),
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

  Widget _buildStatusFilterModal(BuildContext modalContext, StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'certificationStatus'.tr(),
          style: scaledTextStyle(
            fontSize: 13,
            color: modalContext.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: scaleSize(8)),
        // Simple checkbox for "Show only active certifications"
        InkWell(
          onTap: () {
            setModalState(() {
              _localShowActiveOnly = _localShowActiveOnly == true ? null : true;
            });
          },
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: EdgeInsets.all(scaleSize(4)),
            child: Row(
              children: [
                Checkbox(
                  value: _localShowActiveOnly == true,
                  onChanged: (value) {
                    setModalState(() {
                      _localShowActiveOnly = value == true ? true : null;
                    });
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                SizedBox(width: scaleSize(4)),
                Expanded(
                  child: Text(
                    'showOnlyActiveCertifications'.tr(),
                    style: scaledTextStyle(fontSize: 14, color: modalContext.colorScheme.onSurface),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeFilterModal(BuildContext modalContext, StateSetter setModalState) {
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
                onTap: () => _selectStartDate(setModalState),
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
                          _startDate != null ? DateFormat('dd/MM/yyyy').format(_startDate!) : 'startDate'.tr(),
                          style: scaledTextStyle(
                            fontSize: 14,
                            color: _startDate != null
                                ? modalContext.colorScheme.onSurface
                                : modalContext.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      if (_startDate != null)
                        GestureDetector(
                          onTap: () => setModalState(() => _startDate = null),
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
                onTap: () => _selectEndDate(setModalState),
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
                          _endDate != null ? DateFormat('dd/MM/yyyy').format(_endDate!) : 'endDate'.tr(),
                          style: scaledTextStyle(
                            fontSize: 14,
                            color: _endDate != null
                                ? modalContext.colorScheme.onSurface
                                : modalContext.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      if (_endDate != null)
                        GestureDetector(
                          onTap: () => setModalState(() => _endDate = null),
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
        if (_startDate != null || _endDate != null) ...[
          SizedBox(height: scaleSize(8)),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setModalState(() {
                _startDate = null;
                _endDate = null;
              }),
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
