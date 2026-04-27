import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';

/// Danger-zone card: delete all safes after confirmation.
class DeleteSafesSetting extends ConsumerWidget {
  const DeleteSafesSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final hasSafes = ref.watch(walletServiceProvider).safeBox.getAll().isNotEmpty;

    return InkWell(
      key: keyDeleteAllWallets,
      onTap: hasSafes
          ? () async {
              log.w('Oublier tous mes coffres');
              final answer = await showConfirmationDialog(
                context: context,
                message: 'areYouSureForgetAllSafes'.tr(),
                type: ConfirmationDialogType.warning,
              );
              if (answer) {
                final success = await ref.read(walletActionsProvider.notifier).deleteAllWallets();
                if (success && context.mounted) {
                  await AppNavigator.pushAndRemoveUntilWithFader(
                    context,
                    RouteNames.home,
                    (Route<dynamic> route) => false,
                  );
                }
              }
            }
          : null,
      child: Padding(
        padding: EdgeInsets.all(scaleSize(isSmallScreen ? 10 : 14)),
        child: Row(
          children: [
            Icon(
              Icons.delete_forever_rounded,
              color: hasSafes
                  ? context.geckoColors.deleteAction
                  : context.colorScheme.onSurface.withValues(alpha: 0.38),
              size: scaleSize(isSmallScreen ? 20 : 24),
            ),
            ScaledSizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'forgetAllMySafes'.tr(),
                    style: scaledTextStyle(
                      fontSize: isSmallScreen ? 14 : 15,
                      color: hasSafes
                          ? context.geckoColors.deleteAction
                          : context.colorScheme.onSurface.withValues(alpha: 0.38),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'forgetAllMySafesHint'.tr(),
                    style: scaledTextStyle(
                      fontSize: isSmallScreen ? 11 : 12,
                      color: context.colorScheme.onSurface.withValues(alpha: hasSafes ? 0.5 : 0.38),
                    ),
                    softWrap: true,
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
