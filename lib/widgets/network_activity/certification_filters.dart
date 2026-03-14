import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/transaction_filters.dart';
import 'package:gecko/providers/certification_filters_provider.dart';

/// Shows the certification filter sheet. Can be called from anywhere.
void showCertificationFilterSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 600),
    builder: (context) => const _CertificationFilterSheetContent(),
  );
}

/// Mobile filter button widget — tapping it opens the filter sheet
class CertificationFilters extends ConsumerWidget {
  const CertificationFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(certificationFiltersProvider);
    final totalActiveFilters = filters.activeFilterCount;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(2)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showCertificationFilterSheet(context),
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
}

/// Self-contained filter sheet content with its own local state
class _CertificationFilterSheetContent extends ConsumerStatefulWidget {
  const _CertificationFilterSheetContent();

  @override
  ConsumerState<_CertificationFilterSheetContent> createState() => _CertificationFilterSheetContentState();
}

class _CertificationFilterSheetContentState extends ConsumerState<_CertificationFilterSheetContent> {
  static final DateTime _minSelectableDate = DateTime(2017, 3, 8);

  late TextEditingController _issuerController;
  late TextEditingController _receiverController;
  bool _exactMatchIssuer = false;
  bool _exactMatchReceiver = false;
  bool? _showActiveOnly;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(certificationFiltersProvider);
    _issuerController = TextEditingController(text: filters.issuerSearch ?? '');
    _receiverController = TextEditingController(text: filters.receiverSearch ?? '');
    _exactMatchIssuer = filters.exactMatchIssuer;
    _exactMatchReceiver = filters.exactMatchReceiver;
    _showActiveOnly = filters.showActiveOnly;
    _startDate = filters.dateRange.startDate;
    _endDate = filters.dateRange.endDate;
  }

  @override
  void dispose() {
    _issuerController.dispose();
    _receiverController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final notifier = ref.read(certificationFiltersProvider.notifier);
    notifier.updateIssuerSearch(_issuerController.text.trim().isEmpty ? null : _issuerController.text.trim());
    notifier.updateReceiverSearch(_receiverController.text.trim().isEmpty ? null : _receiverController.text.trim());
    notifier.updateDateRange(DateRangeFilter(startDate: _startDate, endDate: _endDate));
    notifier.updateExactMatchIssuer(_exactMatchIssuer);
    notifier.updateExactMatchReceiver(_exactMatchReceiver);
    notifier.updateShowActiveOnly(_showActiveOnly);
  }

  void _resetFilters() {
    ref.read(certificationFiltersProvider.notifier).reset();
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
                        'filterCertifications'.tr(),
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
                      _buildSearchField(
                        context,
                        label: 'issuerName'.tr(),
                        controller: _issuerController,
                        hintText: 'searchByIssuerName'.tr(),
                        isExactMatch: _exactMatchIssuer,
                        onExactMatchChanged: () => setState(() => _exactMatchIssuer = !_exactMatchIssuer),
                      ),
                      SizedBox(height: scaleSize(16)),
                      _buildSearchField(
                        context,
                        label: 'receiverName'.tr(),
                        controller: _receiverController,
                        hintText: 'searchByReceiverName'.tr(),
                        isExactMatch: _exactMatchReceiver,
                        onExactMatchChanged: () => setState(() => _exactMatchReceiver = !_exactMatchReceiver),
                      ),
                      SizedBox(height: scaleSize(16)),
                      _buildStatusFilter(context),
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

  Widget _buildSearchField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required String hintText,
    required bool isExactMatch,
    required VoidCallback onExactMatchChanged,
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
        ),
        SizedBox(height: scaleSize(6)),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: scaledTextStyle(
              fontSize: 14,
              color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            prefixIcon: Icon(Icons.person_search, size: scaleSize(20), color: context.colorScheme.onSurfaceVariant),
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
          style: scaledTextStyle(fontSize: 14, color: context.colorScheme.onSurface),
        ),
      ],
    );
  }

  Widget _buildStatusFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'certificationStatus'.tr(),
          style: scaledTextStyle(
            fontSize: 13,
            color: context.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: scaleSize(8)),
        InkWell(
          onTap: () => setState(() => _showActiveOnly = _showActiveOnly == true ? null : true),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: EdgeInsets.all(scaleSize(4)),
            child: Row(
              children: [
                Checkbox(
                  value: _showActiveOnly == true,
                  onChanged: (value) => setState(() => _showActiveOnly = value == true ? true : null),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                SizedBox(width: scaleSize(4)),
                Expanded(
                  child: Text(
                    'showOnlyActiveCertifications'.tr(),
                    style: scaledTextStyle(fontSize: 14, color: context.colorScheme.onSurface),
                  ),
                ),
              ],
            ),
          ),
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
        if (_startDate != null || _endDate != null) ...[
          SizedBox(height: scaleSize(8)),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() {
                _startDate = null;
                _endDate = null;
              }),
              icon: Icon(Icons.clear_all, size: scaleSize(16)),
              label: Text('clearDates'.tr()),
              style: TextButton.styleFrom(
                foregroundColor: context.colorScheme.error,
                padding: EdgeInsets.symmetric(horizontal: scaleSize(8), vertical: scaleSize(4)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateField(BuildContext context, DateTime? date, String placeholder, {required bool isStart}) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: isStart ? _minSelectableDate : (_startDate ?? _minSelectableDate),
          lastDate: isStart ? (_endDate ?? DateTime.now()) : DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            if (isStart) {
              _startDate = picked;
              if (_endDate != null && _endDate!.isBefore(picked)) _endDate = picked;
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
}
