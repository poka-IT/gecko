import 'package:flutter/material.dart';

class ResponsiveBreakpoints {
  static const double compact = 600;
  static const double medium = 840;
  static const double expanded = 1200;

  static bool isCompact(BuildContext context) => MediaQuery.sizeOf(context).width < compact;

  static bool isMedium(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= compact && w < expanded;
  }

  static bool isExpanded(BuildContext context) => MediaQuery.sizeOf(context).width >= expanded;

  /// Returns adaptive column count for grid layouts
  static int gridColumns(BuildContext context, {int compactCols = 2}) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= expanded) return compactCols + 4;
    if (w >= medium) return compactCols + 2;
    if (w >= compact) return compactCols + 1;
    return compactCols;
  }
}
