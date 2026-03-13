import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/screens/cesium_profile_view_screen.dart';
import 'package:gecko/widgets/desktop/desktop_modal.dart';

/// Shows a Cesium+ profile inside a desktop modal.
Future<void> showDesktopCesiumProfileModal(BuildContext context, {required String address}) {
  return showDesktopModal(
    context: context,
    title: 'viewProfile'.tr(),
    size: DesktopModalSize.medium,
    contentPadding: EdgeInsets.zero,
    builder: (context) => CesiumProfileViewScreen(address: address, embeddedMode: true),
  );
}
