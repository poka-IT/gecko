import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/screens/cesium_profile_view_screen.dart';
import 'package:gecko/screens/myWallets/cesium_profile_screen.dart';
import 'package:gecko/widgets/desktop/desktop_modal.dart';

/// Shows a Cesium+ profile editor inside a desktop modal.
Future<void> showDesktopCesiumProfileModal(BuildContext context, {required String address}) {
  return showDesktopModal(
    context: context,
    title: 'cesiumProfile'.tr(),
    size: DesktopModalSize.large,
    contentPadding: EdgeInsets.zero,
    builder: (context) => CesiumProfileScreen(address: address, embeddedMode: true),
  );
}

/// Shows a read-only Cesium+ profile view inside a desktop modal.
Future<void> showDesktopCesiumProfileViewModal(BuildContext context, {required String address}) {
  return showDesktopModal(
    context: context,
    title: 'viewProfile'.tr(),
    size: DesktopModalSize.large,
    contentPadding: EdgeInsets.zero,
    builder: (context) => CesiumProfileViewScreen(address: address, embeddedMode: true),
  );
}
