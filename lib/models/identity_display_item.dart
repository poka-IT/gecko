import 'package:durt2/durt2.dart'
    show Query$GetNetworkIdentities$identities$edges$node, Query$GetNetworkIdentitiesFiltered$identities$edges$node;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';

class IdentityDisplayItem {
  final String name;
  final String? accountId;
  final String? accountRemovedId;
  final String status;
  final DateTime timestamp;
  final String dateDelimiter;
  final int? blockHeight;
  final DateTime? blockTimestamp;

  IdentityDisplayItem({
    required this.name,
    this.accountId,
    this.accountRemovedId,
    required this.status,
    required this.timestamp,
    required this.dateDelimiter,
    this.blockHeight,
    this.blockTimestamp,
  });

  factory IdentityDisplayItem.fromNetworkIdentityNode(Query$GetNetworkIdentities$identities$edges$node node) {
    // Parse the creation timestamp from blockchain format
    final DateTime creationTime = DateTime.fromMillisecondsSinceEpoch(node.createdOn * 1000, isUtc: true).toLocal();

    // Use block timestamp if available, otherwise fall back to creation time
    final DateTime? blockTime = node.createdIn?.block?.timestamp != null
        ? node.createdIn!.block!.timestamp.parseBlockTimestamp()
        : null;

    final DateTime displayTime = blockTime ?? creationTime;
    final String dateDelimiter = _calculateDateDelimiter(displayTime);

    return IdentityDisplayItem(
      name: node.name,
      accountId: node.accountId,
      accountRemovedId: node.accountRemoved?.id,
      status: node.status,
      timestamp: displayTime,
      dateDelimiter: dateDelimiter,
      blockHeight: node.createdIn?.block?.height,
      blockTimestamp: blockTime,
    );
  }

  factory IdentityDisplayItem.fromFilteredNetworkIdentityNode(
    Query$GetNetworkIdentitiesFiltered$identities$edges$node node,
  ) {
    // Parse the creation timestamp from blockchain format
    final DateTime creationTime = DateTime.fromMillisecondsSinceEpoch(node.createdOn * 1000, isUtc: true).toLocal();

    // Use block timestamp if available, otherwise fall back to creation time
    final DateTime? blockTime = node.createdIn?.block?.timestamp != null
        ? node.createdIn!.block!.timestamp.parseBlockTimestamp()
        : null;

    final DateTime displayTime = blockTime ?? creationTime;
    final String dateDelimiter = _calculateDateDelimiter(displayTime);

    return IdentityDisplayItem(
      name: node.name,
      accountId: node.accountId,
      accountRemovedId: node.accountRemoved?.id,
      status: node.status,
      timestamp: displayTime,
      dateDelimiter: dateDelimiter,
      blockHeight: node.createdIn?.block?.height,
      blockTimestamp: blockTime,
    );
  }

  static String _calculateDateDelimiter(DateTime timestamp) {
    final now = DateTime.now();

    // Compare calendar dates, not 24-hour periods
    final nowDate = DateTime(now.year, now.month, now.day);
    final timestampDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    final daysDifference = nowDate.difference(timestampDate).inDays;

    if (daysDifference == 0) {
      return "today".tr();
    } else if (daysDifference == 1) {
      return "yesterday".tr();
    } else if (daysDifference < 7) {
      return "daysAgo".tr(args: [daysDifference.toString()]);
    } else {
      final locale = Localizations.localeOf(homeContext).languageCode;
      // Format verbose: "mardi 23 mars" ou "Tuesday 23 March"
      final formatPattern = timestamp.year == now.year
          ? 'EEEE d MMMM' // if same year, use "EEEE d MMMM"
          : 'EEEE d MMMM y'; // if different year, use "EEEE d MMMM y"
      final formatted = DateFormat(formatPattern, locale).format(timestamp);
      // Capitalize the first letter of each word (day and month)
      return formatted
          .split(' ')
          .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word)
          .join(' ');
    }
  }

  /// Get display text for status
  String get displayStatus {
    switch (status) {
      case 'Member':
        return "member".tr();
      case 'NotMember':
        return "notMember".tr();
      case 'Removed':
        return "removed".tr();
      case 'Revoked':
        return "revoked".tr();
      case 'Unconfirmed':
        return "unconfirmed".tr();
      case 'Unvalidated':
        return "unvalidated".tr();
      case 'Unknown':
        return "unknown".tr();
      default:
        return "unknown".tr();
    }
  }

  /// Get appropriate color for status
  Color getStatusColor() {
    switch (status) {
      case 'Member':
        return Colors.green;
      case 'Unconfirmed':
        return Colors.blue;
      case 'NotMember':
        return Colors.orange;
      case 'Removed':
        return Colors.orange;
      case 'Revoked':
        return Colors.red;
      case 'Unvalidated':
        return Colors.grey;
      case 'Unknown':
        return Colors.grey;
      default:
        return Colors.red;
    }
  }

  /// Get appropriate icon for status
  IconData getStatusIcon() {
    switch (status) {
      case 'Member':
        return Icons.verified_user;
      case 'Unconfirmed':
        return Icons.person_add;
      case 'NotMember':
        return Icons.person;
      case 'Removed':
        return Icons.person_remove;
      case 'Revoked':
        return Icons.cancel;
      case 'Unvalidated':
        return Icons.person_off;
      case 'Unknown':
      default:
        return Icons.help_outline;
    }
  }

  /// Get the most relevant account ID (active account or removed account)
  String? get relevantAccountId => accountId ?? accountRemovedId;

  /// Check if this identity has an active account
  bool get hasActiveAccount => accountId != null;

  /// Check if this identity was removed
  bool get wasRemoved => accountRemovedId != null && accountId == null;
}
