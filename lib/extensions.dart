import 'package:flutter/material.dart';

/// Parses a blockchain timestamp string to local DateTime.
/// Handles timestamps with or without timezone info (appends 'Z' if missing).
extension BlockTimestampParsing on String {
  DateTime parseBlockTimestamp() {
    final hasTimezone = endsWith('Z') || contains('+') || contains('-');
    return DateTime.parse(hasTimezone ? this : '${this}Z').toLocal();
  }

  /// Returns the raw UTC string, ensuring timezone marker is present.
  String ensureUtcTimestamp() {
    final hasTimezone = endsWith('Z') || contains('+') || contains('-');
    return hasTimezone ? this : '${this}Z';
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
