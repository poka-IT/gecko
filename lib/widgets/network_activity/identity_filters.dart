import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/transaction_filters.dart';
import 'package:gecko/providers/identity_filters_provider.dart';

/// Shows the identity filter sheet. Can be called from anywhere (mobile button or desktop filter bar).
void showIdentityFilterSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 600),
    builder: (context) => const _IdentityFilterSheetContent(),
  );
}

/// Mobile filter button widget — tapping it opens the filter sheet
class IdentityFilters extends ConsumerWidget {
  const IdentityFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(identityFiltersProvider);
    final hasActiveFilters = filters.hasActiveFilters;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(2)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showIdentityFilterSheet(context),
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
  }
}

/// Self-contained filter sheet content with its own local state
class _IdentityFilterSheetContent extends ConsumerStatefulWidget {
  const _IdentityFilterSheetContent();

  @override
  ConsumerState<_IdentityFilterSheetContent> createState() => _IdentityFilterSheetContentState();
}

class _IdentityFilterSheetContentState extends ConsumerState<_IdentityFilterSheetContent> {
  late TextEditingController _nameController;
  bool _exactMatchName = false;
  Set<String> _selectedStatuses = {};
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(identityFiltersProvider);
    _nameController = TextEditingController(text: filters.nameSearch ?? '');
    _exactMatchName = filters.exactMatchName;
    _selectedStatuses = Set.from(filters.selectedStatuses ?? []);
    _startDate = filters.dateRange.startDate;
    _endDate = filters.dateRange.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final notifier = ref.read(identityFiltersProvider.notifier);
    notifier.updateNameSearch(_nameController.text.trim().isEmpty ? null : _nameController.text.trim());
    notifier.updateExactMatchName(_exactMatchName);
    notifier.updateSelectedStatuses(_selectedStatuses.isEmpty ? null : _selectedStatuses.toList());
    notifier.updateDateRange(DateRangeFilter(startDate: _startDate, endDate: _endDate));
  }

  void _resetFilters() {
    ref.read(identityFiltersProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter): () {
          _applyFilters();
          Navigator.pop(context);
        },
      },
      child: Focus(
        autofocus: true,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -2)),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
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
              // Form content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: scaleSize(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNameFilter(context),
                      SizedBox(height: scaleSize(16)),
                      _buildStatusFilters(context),
                      SizedBox(height: scaleSize(16)),
                      _buildDateRange(context),
                      SizedBox(height: scaleSize(100)),
                    ],
                  ),
                ),
              ),
              // Action buttons
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameFilter(BuildContext context) {
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
                controller: _nameController,
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
              onTap: () => setState(() => _exactMatchName = !_exactMatchName),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: EdgeInsets.all(scaleSize(4)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _exactMatchName,
                      onChanged: (_) => setState(() => _exactMatchName = !_exactMatchName),
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

  Widget _buildStatusFilters(BuildContext context) {
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
            final isSelected = _selectedStatuses.contains(status);
            return FilterChip(
              label: Text(_getStatusDisplayText(status)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedStatuses.add(status);
                  } else {
                    _selectedStatuses.remove(status);
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

  Widget _buildDateRange(BuildContext context) {
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
            Expanded(child: _buildDateField(context, _startDate, 'startDate'.tr(), isStart: true)),
            SizedBox(width: scaleSize(12)),
            Expanded(child: _buildDateField(context, _endDate, 'endDate'.tr(), isStart: false)),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField(BuildContext context, DateTime? date, String placeholder, {required bool isStart}) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: isStart ? DateTime(2020) : (_startDate ?? DateTime(2020)),
          lastDate: isStart ? (_endDate ?? DateTime.now()) : DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            if (isStart) {
              _startDate = picked;
            } else {
              _endDate = picked;
            }
          });
        }
      },
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
                date != null ? DateFormat('dd/MM/yyyy').format(date) : placeholder,
                style: scaledTextStyle(
                  fontSize: 14,
                  color: date != null
                      ? context.colorScheme.onSurface
                      : context.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ),
            if (date != null)
              GestureDetector(
                onTap: () => setState(() {
                  if (isStart) {
                    _startDate = null;
                  } else {
                    _endDate = null;
                  }
                }),
                child: Icon(Icons.close, size: scaleSize(16), color: context.colorScheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        border: Border(top: BorderSide(color: context.colorScheme.outline.withValues(alpha: 0.2), width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2))],
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
    );
  }

  String _getStatusDisplayText(String status) {
    return switch (status) {
      'Member' => 'member'.tr(),
      'NotMember' => 'notMember'.tr(),
      'Removed' => 'removed'.tr(),
      'Revoked' => 'revoked'.tr(),
      'Unconfirmed' => 'unconfirmed'.tr(),
      'Unvalidated' => 'unvalidated'.tr(),
      _ => 'unknown'.tr(),
    };
  }
}
