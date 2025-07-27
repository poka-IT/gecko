import 'package:durt2/durt2.dart'
    show
        Query$GetNetworkIdentities$identityConnection$edges$node,
        Query$GetNetworkIdentitiesFiltered$identityConnection$edges$node,
        Enum$IdentityStatusEnum;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';

class IdentityDisplayItem {
  final String name;
  final String? accountId;
  final String? accountRemovedId;
  final Enum$IdentityStatusEnum status;
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

  factory IdentityDisplayItem.fromNetworkIdentityNode(Query$GetNetworkIdentities$identityConnection$edges$node node) {
    // Parse the creation timestamp from blockchain format
    final DateTime creationTime = DateTime.fromMillisecondsSinceEpoch(node.createdOn * 1000, isUtc: true).toLocal();

    // Use block timestamp if available, otherwise fall back to creation time
    final DateTime? blockTime = node.createdIn?.block?.timestamp != null
        ? (node.createdIn!.block!.timestamp.endsWith('Z') ||
                  node.createdIn!.block!.timestamp.contains('+') ||
                  node.createdIn!.block!.timestamp.contains('-')
              ? DateTime.parse(node.createdIn!.block!.timestamp).toLocal()
              : DateTime.parse('${node.createdIn!.block!.timestamp}Z').toLocal())
        : null;

    final DateTime displayTime = blockTime ?? creationTime;
    final String dateDelimiter = _calculateDateDelimiter(displayTime);

    return IdentityDisplayItem(
      name: node.name,
      accountId: node.accountId,
      accountRemovedId: node.accountRemoved?.id,
      status: _parseStatus(node.status?.name),
      timestamp: displayTime,
      dateDelimiter: dateDelimiter,
      blockHeight: node.createdIn?.block?.height,
      blockTimestamp: blockTime,
    );
  }

  factory IdentityDisplayItem.fromFilteredNetworkIdentityNode(
    Query$GetNetworkIdentitiesFiltered$identityConnection$edges$node node,
  ) {
    // Parse the creation timestamp from blockchain format
    final DateTime creationTime = DateTime.fromMillisecondsSinceEpoch(node.createdOn * 1000, isUtc: true).toLocal();

    // Use block timestamp if available, otherwise fall back to creation time
    final DateTime? blockTime = node.createdIn?.block?.timestamp != null
        ? (node.createdIn!.block!.timestamp.endsWith('Z') ||
                  node.createdIn!.block!.timestamp.contains('+') ||
                  node.createdIn!.block!.timestamp.contains('-')
              ? DateTime.parse(node.createdIn!.block!.timestamp).toLocal()
              : DateTime.parse('${node.createdIn!.block!.timestamp}Z').toLocal())
        : null;

    final DateTime displayTime = blockTime ?? creationTime;
    final String dateDelimiter = _calculateDateDelimiter(displayTime);

    return IdentityDisplayItem(
      name: node.name,
      accountId: node.accountId,
      accountRemovedId: node.accountRemoved?.id,
      status: _parseStatus(node.status?.name),
      timestamp: displayTime,
      dateDelimiter: dateDelimiter,
      blockHeight: node.createdIn?.block?.height,
      blockTimestamp: blockTime,
    );
  }

  /// Parse status string to IdentityStatus enum
  static Enum$IdentityStatusEnum _parseStatus(String? statusString) {
    if (statusString == null) return Enum$IdentityStatusEnum.UNCONFIRMED;

    switch (statusString.toUpperCase()) {
      case 'MEMBER':
        return Enum$IdentityStatusEnum.MEMBER;
      case 'NOTMEMBER':
        return Enum$IdentityStatusEnum.NOTMEMBER;
      case 'REMOVED':
        return Enum$IdentityStatusEnum.REMOVED;
      case 'REVOKED':
        return Enum$IdentityStatusEnum.REVOKED;
      case 'UNCONFIRMED':
        return Enum$IdentityStatusEnum.UNCONFIRMED;
      case 'UNVALIDATED':
        return Enum$IdentityStatusEnum.UNVALIDATED;
      default:
        return Enum$IdentityStatusEnum.UNCONFIRMED; // Default fallback
    }
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
      case Enum$IdentityStatusEnum.MEMBER:
        return "member".tr();
      case Enum$IdentityStatusEnum.NOTMEMBER:
        return "notMember".tr();
      case Enum$IdentityStatusEnum.REMOVED:
        return "removed".tr();
      case Enum$IdentityStatusEnum.REVOKED:
        return "revoked".tr();
      case Enum$IdentityStatusEnum.UNCONFIRMED:
        return "unconfirmed".tr();
      case Enum$IdentityStatusEnum.UNVALIDATED:
        return "unvalidated".tr();
      case Enum$IdentityStatusEnum.$unknown:
        return "unknown".tr();
    }
  }

  /// Get appropriate color for status
  Color getStatusColor() {
    switch (status) {
      case Enum$IdentityStatusEnum.MEMBER:
        return Colors.green;
      case Enum$IdentityStatusEnum.UNCONFIRMED:
        return Colors.blue;
      case Enum$IdentityStatusEnum.NOTMEMBER:
        return Colors.orange;
      case Enum$IdentityStatusEnum.REMOVED:
        return Colors.orange;
      case Enum$IdentityStatusEnum.REVOKED:
        return Colors.red;
      case Enum$IdentityStatusEnum.UNVALIDATED:
        return Colors.grey;
      case Enum$IdentityStatusEnum.$unknown:
        return Colors.grey;
    }
  }

  /// Get appropriate icon for status
  IconData getStatusIcon() {
    switch (status) {
      case Enum$IdentityStatusEnum.MEMBER:
        return Icons.verified_user;
      case Enum$IdentityStatusEnum.UNCONFIRMED:
        return Icons.person_add;
      case Enum$IdentityStatusEnum.NOTMEMBER:
        return Icons.person;
      case Enum$IdentityStatusEnum.REMOVED:
        return Icons.person_remove;
      case Enum$IdentityStatusEnum.REVOKED:
        return Icons.cancel;
      case Enum$IdentityStatusEnum.UNVALIDATED:
        return Icons.person_off;
      case Enum$IdentityStatusEnum.$unknown:
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
