import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/settings_provider.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';

/// Tappable card that clears all application caches after confirmation.
class ClearCacheSetting extends ConsumerWidget {
  const ClearCacheSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    return InkWell(
      onTap: () async {
        final confirm = await showConfirmationDialog(
          context: context,
          message: 'clearCacheConfirmMessage'.tr(),
          type: ConfirmationDialogType.warning,
        );

        if (confirm) {
          try {
            // Clear cache
            final settingsService = ref.read(settingsServiceProvider);
            await settingsService.clearAllCaches();

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('clearCacheExplanation'.tr()), duration: const Duration(seconds: 2)),
              );
            }
          } catch (e) {
            log.e('Error clearing caches: $e');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('errorClearingCaches'.tr(args: [e.toString()])),
                  backgroundColor: context.geckoColors.danger,
                ),
              );
            }
          }
        }
      },
      child: Padding(
        padding: EdgeInsets.all(scaleSize(isSmallScreen ? 10 : 14)),
        child: Row(
          children: [
            Icon(
              Icons.cleaning_services_rounded,
              color: context.colorScheme.primary,
              size: scaleSize(isSmallScreen ? 20 : 24),
            ),
            ScaledSizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'clearCache'.tr(),
                    style: scaledTextStyle(
                      fontSize: isSmallScreen ? 14 : 15,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  Text(
                    'clearCacheDescription'.tr(),
                    style: scaledTextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
