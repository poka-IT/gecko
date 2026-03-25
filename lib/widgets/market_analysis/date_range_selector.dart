import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/services/snackbar_service.dart';

/// Widget for selecting a date range using presets or a custom calendar picker.
///
/// Provides three preset shortcuts (30, 90, 365 days) and a custom range button
/// that opens a calendar dialog. Enforces a maximum 365-day range (D-02).
class DateRangeSelector extends ConsumerWidget {
  const DateRangeSelector({
    super.key,
    required this.onDateRangeSelected,
    this.startDate,
    this.endDate,
  });

  /// Callback invoked when a valid date range is selected.
  final void Function(DateTime start, DateTime end) onDateRangeSelected;

  /// Currently selected start date, if any.
  final DateTime? startDate;

  /// Currently selected end date, if any.
  final DateTime? endDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preset shortcuts row
        Wrap(
          spacing: scaleSize(8),
          runSpacing: scaleSize(8),
          children: [
            _presetButton(context, 'days30'.tr(), 30),
            _presetButton(context, 'days90'.tr(), 90),
            _presetButton(context, 'days365'.tr(), 365),
          ],
        ),
        ScaledSizedBox(height: 12),
        // Custom range button
        OutlinedButton.icon(
          onPressed: () => _openCustomRangePicker(context),
          icon: Icon(Icons.calendar_month, size: scaleSize(18)),
          label: Text(
            'customRange'.tr(),
            style: scaledTextStyle(fontSize: 14),
          ),
        ),
        // Display current selection
        if (startDate != null && endDate != null) ...[
          ScaledSizedBox(height: 8),
          Text(
            '${DateFormat.yMMMd().format(startDate!)} - ${DateFormat.yMMMd().format(endDate!)}',
            style: scaledTextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );
  }

  Widget _presetButton(BuildContext context, String label, int days) {
    final now = DateTime.now();
    final presetStart = now.subtract(Duration(days: days));

    // Check if this preset is currently active
    final isActive = startDate != null &&
        endDate != null &&
        startDate!.difference(presetStart).inDays.abs() <= 1 &&
        endDate!.difference(now).inDays.abs() <= 1;

    return isActive
        ? ElevatedButton(
            onPressed: () => onDateRangeSelected(presetStart, now),
            child: Text(label, style: scaledTextStyle(fontSize: 13)),
          )
        : OutlinedButton(
            onPressed: () => onDateRangeSelected(presetStart, now),
            child: Text(label, style: scaledTextStyle(fontSize: 13)),
          );
  }

  Future<void> _openCustomRangePicker(BuildContext context) async {
    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.range,
        firstDate: DateTime(2022),
        lastDate: DateTime.now(),
      ),
      dialogSize: Size(scaleSize(325), scaleSize(400)),
      value: [startDate, endDate],
    );

    if (results == null || results.length < 2 || results[0] == null || results[1] == null) {
      return;
    }

    final selectedStart = results[0]!;
    final selectedEnd = results[1]!;
    final days = selectedEnd.difference(selectedStart).inDays;

    if (days > 365) {
      if (!context.mounted) return;
      SnackbarService.showMessage(context, message: 'dateRangeExceeds365'.tr());
      return;
    }

    onDateRangeSelected(selectedStart, selectedEnd);
  }
}
