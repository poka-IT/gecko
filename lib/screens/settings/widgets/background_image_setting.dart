import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/settings_provider.dart';

/// Toggle for the home-screen background image.
class BackgroundImageSetting extends ConsumerWidget {
  const BackgroundImageSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showImage = ref.watch(backgroundImageProvider);

    return InkWell(
      onTap: () => ref.read(backgroundImageProvider.notifier).toggle(),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: scaleSize(4)),
        child: Row(
          children: [
            Icon(Icons.image_outlined, color: context.colorScheme.primary, size: scaleSize(24)),
            ScaledSizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'showBackgroundImage'.tr(),
                    style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  Text(
                    'showBackgroundImageDescription'.tr(),
                    style: scaledTextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ],
              ),
            ),
            Switch(
              value: showImage,
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
              onChanged: (_) => ref.read(backgroundImageProvider.notifier).toggle(),
            ),
          ],
        ),
      ),
    );
  }
}
