import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/bottom_app_bar_provider.dart';

/// Service for managing snackbar notifications.
///
/// This service provides consistent snackbar styling and behavior
/// throughout the application, with automatic bottom app bar margin handling.
class SnackbarService {
  /// Shows a general message snackbar.
  static void showMessage(BuildContext context, {required String message, int duration = 4, double fontSize = 14}) {
    _showSnackBar(
      context,
      message: message,
      duration: duration,
      backgroundColor: context.colorScheme.onSurface,
      textColor: context.colorScheme.surfaceContainer,
      fontSize: fontSize,
    );
  }

  /// Shows a snackbar for address copied to clipboard.
  static void showAddressCopied(BuildContext context) {
    _showSnackBar(
      context,
      message: "thisAddressHasBeenCopiedToClipboard".tr(),
      duration: 4,
      backgroundColor: context.colorScheme.onSurface,
      textColor: context.colorScheme.surfaceContainer,
      fontSize: 13,
    );
  }

  /// Shows a snackbar for mnemonic copied to clipboard.
  static void showMnemonicCopied(BuildContext context) {
    _showSnackBar(
      context,
      message: "thisMnemonicHasBeenCopiedToClipboard".tr(),
      duration: 4,
      backgroundColor: context.colorScheme.onSurface,
      textColor: context.colorScheme.surfaceContainer,
      fontSize: 13,
    );
  }

  /// Shows a success snackbar with green styling.
  static void showSuccess(BuildContext context, {required String message, int duration = 4}) {
    _showSnackBar(
      context,
      message: message,
      duration: duration,
      backgroundColor: Colors.green.shade700,
      textColor: Colors.white,
      fontSize: 14,
    );
  }

  /// Shows an error snackbar with red styling.
  static void showError(BuildContext context, {required String message, int duration = 4}) {
    _showSnackBar(
      context,
      message: message,
      duration: duration,
      backgroundColor: Colors.red.shade700,
      textColor: Colors.white,
      fontSize: 14,
    );
  }

  /// Shows a warning snackbar with orange styling.
  static void showWarning(BuildContext context, {required String message, int duration = 4}) {
    _showSnackBar(
      context,
      message: message,
      duration: duration,
      backgroundColor: Colors.orange.shade700,
      textColor: Colors.white,
      fontSize: 14,
    );
  }

  /// Private helper method to create and show snackbars with consistent styling.
  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required int duration,
    required Color backgroundColor,
    required Color textColor,
    required double fontSize,
  }) {
    final snackBar = SnackBar(
      backgroundColor: backgroundColor,
      padding: EdgeInsets.all(scaleSize(19)),
      content: Text(
        message,
        style: scaledTextStyle(fontSize: fontSize, color: textColor),
      ),
      duration: Duration(seconds: duration),
      behavior: SnackBarBehavior.floating,
      margin: _getSnackBarMargin(context),
    );
    context.showDismissibleSnackBar(snackBar);
  }

  /// Calculates appropriate snackbar margin considering bottom app bar.
  static EdgeInsets _getSnackBarMargin(BuildContext context) {
    try {
      final container = ProviderScope.containerOf(context);
      final bottomBarState = container.read(bottomAppBarProvider);
      final isBottomBarVisible = bottomBarState.isBottomBarActuallyVisible;
      final bottomMargin = isBottomBarVisible
          ? scaleSize(67) +
                16.0 // Bottom bar height + standard margin
          : 16.0;
      return EdgeInsets.only(left: 16, right: 16, top: 16, bottom: bottomMargin);
    } catch (e) {
      // Fallback to standard margin if provider is not available
      return const EdgeInsets.all(16);
    }
  }
}
