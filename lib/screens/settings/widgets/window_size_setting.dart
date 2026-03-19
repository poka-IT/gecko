import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/services/config_service.dart';
import 'package:window_manager/window_manager.dart';

/// Toggle to bypass minimum window size constraint (desktop only).
class WindowSizeSetting extends StatefulWidget {
  const WindowSizeSetting({super.key});

  @override
  State<WindowSizeSetting> createState() => _WindowSizeSettingState();
}

class _WindowSizeSettingState extends State<WindowSizeSetting> {
  @override
  Widget build(BuildContext context) {
    final config = ConfigService(configBox);
    final bypass = config.bypassMinWindowSize;

    return InkWell(
      onTap: () async {
        final newValue = !bypass;
        config.bypassMinWindowSize = newValue;
        if (newValue) {
          await windowManager.setMinimumSize(const Size(0, 0));
        } else {
          await windowManager.setMinimumSize(const Size(800, 600));
        }
        if (mounted) {
          setState(() {});
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: scaleSize(4)),
        child: Row(
          children: [
            Icon(Icons.aspect_ratio_rounded, color: context.colorScheme.primary, size: scaleSize(24)),
            ScaledSizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'bypassMinWindowSize'.tr(),
                    style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  Text(
                    'bypassMinWindowSizeDescription'.tr(),
                    style: scaledTextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ],
              ),
            ),
            Switch(
              value: bypass,
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
              onChanged: (bool value) async {
                config.bypassMinWindowSize = value;
                if (value) {
                  await windowManager.setMinimumSize(const Size(0, 0));
                } else {
                  await windowManager.setMinimumSize(const Size(800, 600));
                }
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
