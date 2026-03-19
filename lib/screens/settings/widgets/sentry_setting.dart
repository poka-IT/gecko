import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/services/config_service.dart';

/// Sentry error-reporting toggle.
class SentrySetting extends StatefulWidget {
  const SentrySetting({super.key});

  @override
  State<SentrySetting> createState() => _SentrySettingState();
}

class _SentrySettingState extends State<SentrySetting> {
  @override
  Widget build(BuildContext context) {
    final config = ConfigService(configBox);
    final sentryEnabled = config.sentryEnabled;

    return InkWell(
      onTap: () {
        final newValue = !sentryEnabled;
        config.sentryEnabled = newValue;
        if (mounted) {
          setState(() {});
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: scaleSize(4)),
        child: Row(
          children: [
            Icon(Icons.bug_report_outlined, color: context.colorScheme.primary, size: scaleSize(24)),
            ScaledSizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'sendErrorReports'.tr(),
                    style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  Text(
                    'sendErrorReportsDescription'.tr(),
                    style: scaledTextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                  ScaledSizedBox(height: 2),
                  Text(
                    'requiresRestart'.tr(),
                    style: scaledTextStyle(
                      fontSize: 11,
                      color: context.colorScheme.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: sentryEnabled,
              thumbColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                if (states.contains(WidgetState.selected)) {
                  return context.colorScheme.primary;
                }
                return Colors.grey[400];
              }),
              trackColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                if (!states.contains(WidgetState.selected)) {
                  return Colors.grey[300];
                }
                return null;
              }),
              onChanged: (bool value) {
                config.sentryEnabled = value;
                if (mounted) {
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
