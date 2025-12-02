import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/transaction_filters.dart';
import 'package:gecko/providers/identity_filters_provider.dart';

class IdentityFilters extends ConsumerStatefulWidget {
  const IdentityFilters({super.key});

  @override
  ConsumerState<IdentityFilters> createState() => _IdentityFiltersState();
}

class _IdentityFiltersState extends ConsumerState<IdentityFilters> {
  // Local state for the modal (only applied when "Done" is clicked)
  TextEditingController? _localNameController;
  bool _localExactMatchName = false;
  Set<String> _localSelectedStatuses = {};
  DateTime? _localStartDate;
  DateTime? _localEndDate;

  @override
  void initState() {
    super.initState();
  }

  void _initializeLocalState() {
    final filters = ref.read(identityFiltersProvider);

    // Initialize local state with current provider values
    _localNameController?.dispose();
    _localNameController = TextEditingController(text: filters.nameSearch ?? '');
    _localExactMatchName = filters.exactMatchName;
    _localSelectedStatuses = Set.from(filters.selectedStatuses ?? []);
    _localStartDate = filters.dateRange.startDate;
    _localEndDate = filters.dateRange.endDate;
  }

  void _applyFilters() {
    final notifier = ref.read(identityFiltersProvider.notifier);

    // Apply all local state to the provider
    notifier.updateNameSearch(
      _localNameController?.text.trim().isEmpty == true ? null : _localNameController?.text.trim(),
    );
    notifier.updateExactMatchName(_localExactMatchName);
    notifier.updateSelectedStatuses(_localSelectedStatuses.isEmpty ? null : _localSelectedStatuses.toList());
    notifier.updateDateRange(DateRangeFilter(startDate: _localStartDate, endDate: _localEndDate));
  }

  void _resetFilters() {
    ref.read(identityFiltersProvider.notifier).reset();
    _initializeLocalState(); // Reset local state too
  }

  @override
  void dispose() {
    _localNameController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final filters = ref.watch(identityFiltersProvider);
        final hasActiveFilters = filters.hasActiveFilters;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(2)),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showFiltersBottomSheet(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(6)),
                decoration: BoxDecoration(
                  color: hasActiveFilters
                      ? context.colorScheme.primary.withValues(alpha: 0.08)
                      : context.colorScheme.surface.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasActiveFilters
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
                      color: hasActiveFilters ? context.colorScheme.primary : context.colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: scaleSize(12)),
                    Expanded(
                      child: Text(
                        'filters'.tr(),
                        style: scaledTextStyle(
                          fontSize: 14,
                          color: hasActiveFilters ? context.colorScheme.primary : context.colorScheme.onSurfaceVariant,
                          fontWeight: hasActiveFilters ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (hasActiveFilters) ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: scaleSize(8), vertical: scaleSize(4)),
                        decoration: BoxDecoration(
                          color: context.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          filters.activeFilterCount.toString(),
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
      },
    );
  }

  void _showFiltersBottomSheet(BuildContext context) {
    // Initialize local state before showing modal
    _initializeLocalState();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Don't use Consumer here - we manage state locally

          return Container(
            height: MediaQuery.of(context).size.height * 0.8, // 80% of screen height
            decoration: BoxDecoration(
              color: context.colorScheme.surface,
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
                    color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
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
                          'filterIdentities'.tr(),
                          style: scaledTextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: context.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, size: scaleSize(24)),
                        style: IconButton.styleFrom(
                          backgroundColor: context.colorScheme.surfaceContainer,
                          foregroundColor: context.colorScheme.onSurfaceVariant,
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
                        // Name search
                        _buildSimpleNameFilter(context, setModalState),
                        SizedBox(height: scaleSize(16)),

                        // Status filters
                        _buildSimpleStatusFilters(context, setModalState),
                        SizedBox(height: scaleSize(16)),

                        // Date range
                        _buildSimpleDateRange(context, setModalState),
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
                    color: context.colorScheme.surface,
                    border: Border(
                      top: BorderSide(color: context.colorScheme.outline.withValues(alpha: 0.2), width: 1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.fromLTRB(
                    scaleSize(16),
                    scaleSize(16),
                    scaleSize(16),
                    scaleSize(16) + MediaQuery.of(context).padding.bottom,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            _resetFilters();
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: context.colorScheme.onSurfaceVariant,
                            padding: EdgeInsets.symmetric(vertical: scaleSize(10)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'clearAll'.tr(),
                            style: scaledTextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: scaleSize(12)),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Apply all filters before closing
                            _applyFilters();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colorScheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: EdgeInsets.symmetric(vertical: scaleSize(10)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            shadowColor: context.colorScheme.primary.withValues(alpha: 0.3),
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
          );
        },
      ),
    );
  }

  Widget _buildSimpleNameFilter(BuildContext context, StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'nameSearch'.tr(),
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
                controller: _localNameController,
                onChanged: (value) {
                  // No need to update provider here - will be applied on "Done"
                },
                decoration: InputDecoration(
                  hintText: 'searchByName'.tr(),
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
                ),
                style: scaledTextStyle(fontSize: 14),
              ),
            ),

            SizedBox(width: scaleSize(8)),
            InkWell(
              onTap: () => setModalState(() => _localExactMatchName = !_localExactMatchName),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: EdgeInsets.all(scaleSize(4)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _localExactMatchName,
                      onChanged: (_) => setModalState(() => _localExactMatchName = !_localExactMatchName),
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
        ),
      ],
    );
  }

  Widget _buildSimpleStatusFilters(BuildContext context, StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'identityStatus'.tr(),
          style: scaledTextStyle(
            fontSize: 13,
            color: context.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),

        SizedBox(height: scaleSize(8)),

        Wrap(
          spacing: scaleSize(8),
          runSpacing: scaleSize(8),
          children: ['Member', 'NotMember', 'Removed', 'Revoked', 'Unconfirmed', 'Unvalidated'].map((status) {
            final isSelected = _localSelectedStatuses.contains(status);
            return FilterChip(
              label: Text(_getStatusDisplayText(status)),
              selected: isSelected,
              onSelected: (selected) {
                setModalState(() {
                  if (selected) {
                    _localSelectedStatuses.add(status);
                  } else {
                    _localSelectedStatuses.remove(status);
                  }
                });
              },
              selectedColor: context.colorScheme.primaryContainer,
              checkmarkColor: context.colorScheme.primary,
              backgroundColor: context.colorScheme.surfaceContainerHighest,
              side: BorderSide(
                color: isSelected
                    ? context.colorScheme.primary.withValues(alpha: 0.3)
                    : context.colorScheme.outline.withValues(alpha: 0.3),
              ),
              labelStyle: scaledTextStyle(
                fontSize: 12,
                color: isSelected ? context.colorScheme.primary : context.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSimpleDateRange(BuildContext context, StateSetter setModalState) {
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
                    border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: scaleSize(16), color: context.colorScheme.onSurfaceVariant),
                      SizedBox(width: scaleSize(8)),
                      Expanded(
                        child: Text(
                          _localStartDate != null
                              ? DateFormat('dd/MM/yyyy').format(_localStartDate!)
                              : 'startDate'.tr(),
                          style: scaledTextStyle(
                            fontSize: 14,
                            color: _localStartDate != null
                                ? context.colorScheme.onSurface
                                : context.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      if (_localStartDate != null)
                        GestureDetector(
                          onTap: () => setModalState(() => _localStartDate = null),
                          child: Icon(Icons.close, size: scaleSize(16), color: context.colorScheme.onSurfaceVariant),
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
                    border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: scaleSize(16), color: context.colorScheme.onSurfaceVariant),
                      SizedBox(width: scaleSize(8)),
                      Expanded(
                        child: Text(
                          _localEndDate != null ? DateFormat('dd/MM/yyyy').format(_localEndDate!) : 'endDate'.tr(),
                          style: scaledTextStyle(
                            fontSize: 14,
                            color: _localEndDate != null
                                ? context.colorScheme.onSurface
                                : context.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      if (_localEndDate != null)
                        GestureDetector(
                          onTap: () => setModalState(() => _localEndDate = null),
                          child: Icon(Icons.close, size: scaleSize(16), color: context.colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectStartDate(StateSetter setModalState) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _localStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: _localEndDate ?? DateTime.now(),
    );

    if (date != null) {
      setModalState(() => _localStartDate = date);
    }
  }

  Future<void> _selectEndDate(StateSetter setModalState) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _localEndDate ?? DateTime.now(),
      firstDate: _localStartDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setModalState(() => _localEndDate = date);
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status) {
      case 'Member':
        return 'member'.tr();
      case 'NotMember':
        return 'notMember'.tr();
      case 'Removed':
        return 'removed'.tr();
      case 'Revoked':
        return 'revoked'.tr();
      case 'Unconfirmed':
        return 'unconfirmed'.tr();
      case 'Unvalidated':
        return 'unvalidated'.tr();
      case 'Unknown':
        return 'unknown'.tr();
      default:
        return 'unknown'.tr();
    }
  }
}
