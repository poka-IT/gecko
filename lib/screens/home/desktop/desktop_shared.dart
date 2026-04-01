import 'package:durt2/durt2.dart' as d;
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/services/navigation_service.dart';
import 'package:timeago/timeago.dart' as timeago;

// ─── Data classes ───

enum DesktopSearchSuggestionType { address, identity, cesiumPlus }

class DesktopSearchSuggestion {
  const DesktopSearchSuggestion({required this.address, required this.username, required this.type});

  final String address;
  final String? username;
  final DesktopSearchSuggestionType type;
}

class ActivityMetricDetail {
  final String label;
  final String value;

  const ActivityMetricDetail({required this.label, required this.value});
}

class DesktopSafeWalletGroup {
  const DesktopSafeWalletGroup({required this.safe, required this.wallets, required this.isCurrent});

  final d.SafeEntity safe;
  final List<d.WalletEntity> wallets;
  final bool isCurrent;
}

// ─── Helper functions ───

Widget buildDesktopGlassCard(BuildContext context, {required Widget child, EdgeInsets? padding}) {
  return Container(
    clipBehavior: Clip.hardEdge,
    padding: padding ?? const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          context.colorScheme.surface.withValues(alpha: 0.92),
          context.colorScheme.surfaceContainer.withValues(alpha: 0.68),
        ],
      ),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.08)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 18, offset: const Offset(0, 10))],
    ),
    child: child,
  );
}

Widget buildDesktopPanelShell(BuildContext context, {required Widget child}) {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: context.colorScheme.surface.withValues(alpha: 0.58),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.08)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 32, offset: const Offset(0, 18))],
    ),
    child: child,
  );
}

String desktopRelativeTime(BuildContext context, DateTime dateTime) {
  final locale = Localizations.localeOf(context).languageCode;
  return timeago.format(dateTime, locale: locale);
}

/// Wraps a child widget to navigate to a profile on tap, with pointer cursor.
Widget buildClickableProfile(BuildContext context, {required String address, String? username, required Widget child}) {
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: () => NavigationService.openProfile(
        context,
        address: address,
        username: username?.isNotEmpty == true ? username : null,
      ),
      child: child,
    ),
  );
}

Widget buildCompactProfileLabel(
  BuildContext context, {
  required String text,
  required bool isAddressLabel,
  required TextStyle style,
  TextAlign textAlign = TextAlign.start,
}) {
  final label = Text(text, style: style, overflow: TextOverflow.ellipsis, textAlign: textAlign, maxLines: 1);

  if (!isAddressLabel) {
    return label;
  }

  return Tooltip(
    message: text,
    waitDuration: const Duration(milliseconds: 80),
    preferBelow: true,
    verticalOffset: 24,
    child: label,
  );
}

Widget buildEmptyTabState(BuildContext context, IconData icon, String message) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 40, color: context.colorScheme.onSurface.withValues(alpha: 0.2)),
        const SizedBox(height: 8),
        Text(
          message,
          style: scaledTextStyle(fontSize: 12, color: context.colorScheme.onSurface.withValues(alpha: 0.4)),
        ),
      ],
    ),
  );
}
