import 'package:flutter/material.dart';
import 'package:gecko/providers/gecko_colors.dart';

/// Parses a blockchain timestamp string to local DateTime.
/// Handles timestamps with or without timezone info (appends 'Z' if missing).
extension BlockTimestampParsing on String {
  /// Check if this ISO 8601 string already contains timezone info.
  /// Avoids false positives from date separators (e.g. "2024-02-16").
  bool get _hasTimezoneInfo {
    if (endsWith('Z')) return true;
    // Look for +/- timezone offset only AFTER the 'T' separator
    final tIndex = indexOf('T');
    if (tIndex == -1) return false;
    final timePart = substring(tIndex + 1);
    return timePart.contains('+') || timePart.contains('-');
  }

  DateTime parseBlockTimestamp() {
    return DateTime.parse(_hasTimezoneInfo ? this : '${this}Z').toLocal();
  }

  /// Returns the raw UTC string, ensuring timezone marker is present.
  String ensureUtcTimestamp() {
    return _hasTimezoneInfo ? this : '${this}Z';
  }
}

extension IterableExtension<T> on Iterable<T> {
  /// The first element satisfying [test], or `null` if there are none.
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

extension ExtendedBuildContext on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;

  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Is dark mode currently enabled?
  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;

  /// Access the GeckoColors ThemeExtension for semantic color tokens.
  GeckoColors get geckoColors => Theme.of(this).extension<GeckoColors>()!;
}

/// Extension to make SnackBars dismissible by tapping
extension DismissibleSnackBar on BuildContext {
  /// Show a SnackBar that can be dismissed by tapping on it
  void showDismissibleSnackBar(SnackBar snackBar) {
    // Wrap the original content in a GestureDetector
    final dismissibleSnackBar = SnackBar(
      content: GestureDetector(
        onTap: () {
          // Safely hide the snackbar with null check
          final scaffoldMessenger = ScaffoldMessenger.maybeOf(this);
          scaffoldMessenger?.hideCurrentSnackBar();
        },
        behavior: HitTestBehavior.opaque,
        child: snackBar.content,
      ),
      backgroundColor: snackBar.backgroundColor,
      elevation: snackBar.elevation,
      margin: snackBar.margin,
      padding: snackBar.padding,
      width: snackBar.width,
      shape: snackBar.shape,
      behavior: snackBar.behavior,
      action: snackBar.action,
      actionOverflowThreshold: snackBar.actionOverflowThreshold,
      showCloseIcon: snackBar.showCloseIcon,
      closeIconColor: snackBar.closeIconColor,
      duration: snackBar.duration,
      animation: snackBar.animation,
      onVisible: snackBar.onVisible,
      clipBehavior: snackBar.clipBehavior,
      dismissDirection: snackBar.dismissDirection,
    );

    // Safely show the snackbar with null check
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(this);
    scaffoldMessenger?.showSnackBar(dismissibleSnackBar);
  }
}
