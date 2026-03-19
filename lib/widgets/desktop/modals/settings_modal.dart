import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/widgets/desktop/desktop_modal.dart';
import 'package:gecko/screens/settings.dart';

/// Shows the settings screen inside a desktop modal.
///
/// The settings screen is wrapped in a [Scaffold]-free container that
/// reuses the existing [SettingsScreen] build logic.
Future<void> showDesktopSettingsModal(BuildContext context) {
  return showDesktopModal(
    context: context,
    title: 'parameters'.tr(),
    size: DesktopModalSize.medium,
    contentPadding: EdgeInsets.zero,
    builder: (context) => const _DesktopSettingsContent(),
  );
}

class _DesktopSettingsContent extends ConsumerWidget {
  const _DesktopSettingsContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Embed the full SettingsScreen but inside the modal shell.
    // We use a ClipRRect to respect the modal's rounded corners.
    return ClipRRect(
      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: const SettingsScreen(embeddedMode: true),
      ),
    );
  }
}
