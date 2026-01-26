import 'package:durt2/durt2.dart'
    show Durt, Query$GetNetworkCertifications$certs$edges$node, Query$GetNetworkCertificationsFiltered$certs$edges$node;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/providers.dart';

class CertificationDisplayItem {
  final String id;
  final String? issuerName;
  final String? receiverName;
  final String issuerAccountId;
  final String receiverAccountId;
  final bool isActive;
  final DateTime createdTimestamp;
  final DateTime updatedTimestamp;
  final DateTime timestamp; // Display timestamp (most recent of created/updated)
  final String dateDelimiter;
  final DateTime expireDate;
  final int? createdBlockHeight;
  final int? updatedBlockHeight;

  CertificationDisplayItem({
    required this.id,
    this.issuerName,
    this.receiverName,
    required this.issuerAccountId,
    required this.receiverAccountId,
    required this.isActive,
    required this.createdTimestamp,
    required this.updatedTimestamp,
    required this.timestamp,
    required this.dateDelimiter,
    required this.expireDate,
    this.createdBlockHeight,
    this.updatedBlockHeight,
  });

  static Future<CertificationDisplayItem?> fromNetworkCertificationNode(
    Query$GetNetworkCertifications$certs$edges$node node,
    Ref ref,
  ) async {
    // Get genesis blockchain time for block number conversion
    final genesisTime = await ref.read(genesisTimeProvider.future);
    if (genesisTime == null) {
      return null; // Storage not ready yet
    }

    // Convert block numbers to proper timestamps
    final DateTime creationTime = Durt.i.storage.blocNumberToDate(node.createdOn, genesisTime);
    final DateTime updateTime = Durt.i.storage.blocNumberToDate(node.updatedOn, genesisTime);

    // Use the most recent timestamp for display
    final DateTime displayTime = updateTime.isAfter(creationTime) ? updateTime : creationTime;

    // Parse block timestamps if available (these are actual timestamps)
    final DateTime? createdBlockTime = node.createdIn?.block?.timestamp != null
        ? (node.createdIn!.block!.timestamp.endsWith('Z') ||
                  node.createdIn!.block!.timestamp.contains('+') ||
                  node.createdIn!.block!.timestamp.contains('-')
              ? DateTime.parse(node.createdIn!.block!.timestamp).toLocal()
              : DateTime.parse('${node.createdIn!.block!.timestamp}Z').toLocal())
        : null;

    final DateTime? updatedBlockTime = node.updatedIn?.block?.timestamp != null
        ? (node.updatedIn!.block!.timestamp.endsWith('Z') ||
                  node.updatedIn!.block!.timestamp.contains('+') ||
                  node.updatedIn!.block!.timestamp.contains('-')
              ? DateTime.parse(node.updatedIn!.block!.timestamp).toLocal()
              : DateTime.parse('${node.updatedIn!.block!.timestamp}Z').toLocal())
        : null;

    // Use block timestamp if available, otherwise fall back to converted block number timestamp
    final DateTime finalDisplayTime = updatedBlockTime ?? createdBlockTime ?? displayTime;

    // Convert expiration block number to proper date
    final DateTime expireDate = Durt.i.storage.blocNumberToDate(node.expireOn, genesisTime);

    final String dateDelimiter = _calculateDateDelimiter(finalDisplayTime);

    return CertificationDisplayItem(
      id: node.id,
      issuerName: node.issuer?.name,
      receiverName: node.receiver?.name,
      issuerAccountId: node.issuer?.accountId ?? '',
      receiverAccountId: node.receiver?.accountId ?? '',
      isActive: node.isActive,
      createdTimestamp: creationTime,
      updatedTimestamp: updateTime,
      timestamp: finalDisplayTime,
      dateDelimiter: dateDelimiter,
      expireDate: expireDate,
      createdBlockHeight: node.createdIn?.block?.height,
      updatedBlockHeight: node.updatedIn?.block?.height,
    );
  }

  static Future<CertificationDisplayItem?> fromFilteredNetworkCertificationNode(
    Query$GetNetworkCertificationsFiltered$certs$edges$node node,
    Ref ref,
  ) async {
    // Get genesis blockchain time for block number conversion
    final genesisTime = await ref.read(genesisTimeProvider.future);
    if (genesisTime == null) {
      return null; // Storage not ready yet
    }

    // Convert block numbers to proper timestamps
    final DateTime creationTime = Durt.i.storage.blocNumberToDate(node.createdOn, genesisTime);
    final DateTime updateTime = Durt.i.storage.blocNumberToDate(node.updatedOn, genesisTime);

    // Use the most recent timestamp for display
    final DateTime displayTime = updateTime.isAfter(creationTime) ? updateTime : creationTime;

    // Parse block timestamps if available (these are actual timestamps)
    final DateTime? createdBlockTime = node.createdIn?.block?.timestamp != null
        ? (node.createdIn!.block!.timestamp.endsWith('Z') ||
                  node.createdIn!.block!.timestamp.contains('+') ||
                  node.createdIn!.block!.timestamp.contains('-')
              ? DateTime.parse(node.createdIn!.block!.timestamp).toLocal()
              : DateTime.parse('${node.createdIn!.block!.timestamp}Z').toLocal())
        : null;

    final DateTime? updatedBlockTime = node.updatedIn?.block?.timestamp != null
        ? (node.updatedIn!.block!.timestamp.endsWith('Z') ||
                  node.updatedIn!.block!.timestamp.contains('+') ||
                  node.updatedIn!.block!.timestamp.contains('-')
              ? DateTime.parse(node.updatedIn!.block!.timestamp).toLocal()
              : DateTime.parse('${node.updatedIn!.block!.timestamp}Z').toLocal())
        : null;

    // Use block timestamp if available, otherwise fall back to converted block number timestamp
    final DateTime finalDisplayTime = updatedBlockTime ?? createdBlockTime ?? displayTime;

    // Convert expiration block number to proper date
    final DateTime expireDate = Durt.i.storage.blocNumberToDate(node.expireOn, genesisTime);

    final String dateDelimiter = _calculateDateDelimiter(finalDisplayTime);

    return CertificationDisplayItem(
      id: node.id,
      issuerName: node.issuer?.name,
      receiverName: node.receiver?.name,
      issuerAccountId: node.issuer?.accountId ?? '',
      receiverAccountId: node.receiver?.accountId ?? '',
      isActive: node.isActive,
      createdTimestamp: creationTime,
      updatedTimestamp: updateTime,
      timestamp: finalDisplayTime,
      dateDelimiter: dateDelimiter,
      expireDate: expireDate,
      createdBlockHeight: node.createdIn?.block?.height,
      updatedBlockHeight: node.updatedIn?.block?.height,
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

  /// Get a display-friendly status name
  String get displayStatus {
    return isActive ? "certificationActive".tr() : "certificationInactive".tr();
  }

  /// Get color associated with certification status
  Color getStatusColor() {
    return isActive ? Colors.green : Colors.red.withValues(alpha: 0.6);
  }

  /// Get icon associated with certification status
  IconData getStatusIcon() {
    return isActive ? Icons.verified : Icons.cancel;
  }

  /// Get display name for issuer (name if available, otherwise truncated account ID)
  String get issuerDisplayName {
    return issuerName ?? '${issuerAccountId.substring(0, 8)}...';
  }

  /// Get display name for receiver (name if available, otherwise truncated account ID)
  String get receiverDisplayName {
    return receiverName ?? '${receiverAccountId.substring(0, 8)}...';
  }

  /// Get a formatted display text for the certification relationship
  String get relationshipDisplay {
    return '$issuerDisplayName → $receiverDisplayName';
  }

  /// Check if this certification is expired
  /// A certification cannot be expired if it is active, even if expireDate is in the past
  /// (which could happen if genesisTime was incorrectly calculated)
  bool get isExpired {
    // If the certification is active, it cannot be expired
    if (isActive) {
      return false;
    }
    // Only check expiration date if the certification is not active
    return DateTime.now().isAfter(expireDate);
  }

  /// Get expiration status text
  String? get expirationText {
    final now = DateTime.now();
    if (now.isAfter(expireDate)) {
      return "certificationExpired".tr();
    }

    final daysUntilExpiration = expireDate.difference(now).inDays;
    if (daysUntilExpiration <= 30) {
      return "certificationExpiresIn".tr(args: [daysUntilExpiration.toString()]);
    }

    return null; // Don't show expiration text if more than 30 days away
  }

  /// Check if this certification was recently updated (within last 7 days)
  bool get isRecentlyUpdated {
    final daysSinceUpdate = DateTime.now().difference(updatedTimestamp).inDays;
    return daysSinceUpdate <= 7;
  }
}
