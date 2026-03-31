import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/main.dart';
import 'package:gecko/screens/certification_queue_screen.dart';
import 'package:gecko/widgets/desktop/desktop_modal.dart';

/// Shows the certification queue inside a desktop modal.
Future<void> showDesktopCertificationQueueModal(
  BuildContext context, {
  required String issuerAddress,
  VoidCallback? onBack,
}) {
  return showDesktopModal(
    context: context,
    title: 'certificationQueue'.tr(),
    size: DesktopModalSize.medium,
    contentPadding: EdgeInsets.zero,
    onBack: onBack,
    builder: (modalContext) => DesktopModalScope(
      reopenCurrentModal: () =>
          showDesktopCertificationQueueModal(Gecko.navigatorContext!, issuerAddress: issuerAddress, onBack: onBack),
      child: CertificationQueueScreen(issuerAddress: issuerAddress, embeddedMode: true),
    ),
  );
}
