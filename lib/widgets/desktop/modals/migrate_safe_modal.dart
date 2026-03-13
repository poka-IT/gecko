import 'package:flutter/material.dart';
import 'package:gecko/screens/myWallets/migrate_safe.dart';
import 'package:gecko/widgets/desktop/desktop_modal.dart';
import 'package:easy_localization/easy_localization.dart';

/// Shows the migrate safe flow inside a desktop modal.
Future<void> showDesktopMigrateSafeModal(BuildContext context) {
  return showDesktopModal(
    context: context,
    title: 'migrateSafe'.tr(),
    size: DesktopModalSize.medium,
    showCloseButton: true,
    contentPadding: EdgeInsets.zero,
    builder: (context) => const MigrateSafeScreen(embeddedMode: true),
  );
}
