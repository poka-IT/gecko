import 'package:flutter/material.dart';

/// Shared desktop breakpoint — single source of truth for all desktop layout decisions.
const double desktopBreakpoint = 900;

/// Returns true when the current screen width is >= the desktop breakpoint.
bool isDesktopLayout(BuildContext context) {
  return MediaQuery.of(context).size.width >= desktopBreakpoint;
}
