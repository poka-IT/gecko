import 'package:durt2/durt2.dart'
    show Query$GetNetworkIdentities$identities$edges$node, Query$GetNetworkIdentitiesFiltered$identities$edges$node;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/providers/gecko_colors.dart';
import 'package:gecko/utils.dart';

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
    final String dateDelimiter = calculateDateDelimiter(displayTime);

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
    final String dateDelimiter = calculateDateDelimiter(displayTime);

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

  Map<String, dynamic> toJson() => {
    'name': name,
    'accountId': accountId,
    'accountRemovedId': accountRemovedId,
    'status': status,
    'timestamp': timestamp.toIso8601String(),
    'dateDelimiter': dateDelimiter,
    'blockHeight': blockHeight,
    'blockTimestamp': blockTimestamp?.toIso8601String(),
  };

  factory IdentityDisplayItem.fromJson(Map<String, dynamic> json) => IdentityDisplayItem(
    name: json['name'] as String,
    accountId: json['accountId'] as String?,
    accountRemovedId: json['accountRemovedId'] as String?,
    status: json['status'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    dateDelimiter: json['dateDelimiter'] as String,
    blockHeight: json['blockHeight'] as int?,
    blockTimestamp: json['blockTimestamp'] != null ? DateTime.parse(json['blockTimestamp'] as String) : null,
  );

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
  Color getStatusColor(GeckoColors colors) {
    switch (status) {
      case 'Member':
        return colors.statusMember;
      case 'Unconfirmed':
        return colors.statusCreated;
      case 'NotMember':
        return colors.statusConfirmed;
      case 'Removed':
        return colors.statusConfirmed;
      case 'Revoked':
        return colors.statusExpired;
      case 'Unvalidated':
        return colors.statusNone;
      case 'Unknown':
        return colors.statusNone;
      default:
        return colors.statusExpired;
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
