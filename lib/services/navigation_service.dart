import 'package:flutter/material.dart';
import 'package:gecko/screens/profile_view.dart';
import 'package:gecko/widgets/desktop/desktop_utils.dart';
import 'package:gecko/widgets/desktop/modals/profile_modal.dart';
import 'package:gecko/widgets/page_route_no_transition.dart';

/// Centralized navigation service that automatically routes to the correct
/// desktop (modal) or mobile (full-screen) view based on screen width.
///
/// All profile/screen navigation should go through this service to prevent
/// desktop/mobile UX mismatches.
class NavigationService {
  /// Opens a profile view: desktop modal or mobile full-screen.
  ///
  /// If [autoOpenPayment] is true, the payment popup will be opened automatically
  /// (e.g. when a `june://` URI with an amount was scanned via NFC/QR).
  static void openProfile(
    BuildContext context, {
    required String address,
    String? username,
    String? fromAddress,
    bool autoOpenPayment = false,
  }) {
    if (isDesktopLayout(context)) {
      showDesktopProfileModal(context, address: address, username: username);
    } else {
      Navigator.push(
        context,
        PageNoTransit(
          builder: (context) => ProfileViewScreen(
            address: address,
            username: username,
            fromAddress: fromAddress,
            autoOpenPayment: autoOpenPayment,
          ),
        ),
      );
    }
  }

  /// Opens a profile view, replacing the current route (mobile) or showing modal (desktop).
  static void openProfileReplacement(BuildContext context, {required String address, String? username}) {
    if (isDesktopLayout(context)) {
      showDesktopProfileModal(context, address: address, username: username);
    } else {
      Navigator.pushReplacement(
        context,
        PageNoTransit(
          builder: (context) => ProfileViewScreen(address: address, username: username),
        ),
      );
    }
  }
}
