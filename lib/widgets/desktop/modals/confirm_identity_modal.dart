import 'package:flutter/material.dart';
import 'package:gecko/screens/identity/confirm_identity.dart';
import 'package:gecko/widgets/desktop/desktop_modal.dart';
import 'package:easy_localization/easy_localization.dart';

/// Shows the confirm identity flow inside a desktop modal.
Future<void> showDesktopConfirmIdentityModal(BuildContext context, {required String address, VoidCallback? onBack}) {
  return showDesktopModal(
    context: context,
    title: 'chooseIdentityName'.tr(),
    size: DesktopModalSize.medium,
    showCloseButton: true,
    contentPadding: EdgeInsets.zero,
    onBack: onBack,
    builder: (context) => ConfirmIdentityScreen(address: address, embeddedMode: true),
  );
}
