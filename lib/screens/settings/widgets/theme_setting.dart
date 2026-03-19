import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/theme_provider.dart';

/// Theme mode selector (light / system / dark).
class ThemeSetting extends ConsumerWidget {
  const ThemeSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('theme'.tr(), style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color)),
        ScaledSizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Consumer(
                builder: (context, ref, _) {
                  final currentThemeSetting = ref.watch(themeProvider);
                  return SegmentedButton<ThemeModeSetting>(
                    segments: <ButtonSegment<ThemeModeSetting>>[
                      ButtonSegment(
                        value: ThemeModeSetting.light,
                        label: Text('light'.tr()),
                        icon: const Icon(Icons.light_mode),
                      ),
                      ButtonSegment(
                        value: ThemeModeSetting.system,
                        label: Text('system'.tr()),
                        icon: const Icon(Icons.brightness_auto),
                      ),
                      ButtonSegment(
                        value: ThemeModeSetting.dark,
                        label: Text('dark'.tr()),
                        icon: const Icon(Icons.dark_mode),
                      ),
                    ],
                    selected: {currentThemeSetting},
                    onSelectionChanged: (Set<ThemeModeSetting> newSelection) {
                      ref.read(themeProvider.notifier).setThemeMode(newSelection.first);
                    },
                    style: SegmentedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      selectedForegroundColor: Theme.of(context).colorScheme.onPrimary,
                      selectedBackgroundColor: Theme.of(context).colorScheme.primary,
                      padding: EdgeInsets.symmetric(horizontal: scaleSize(8), vertical: scaleSize(8)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
