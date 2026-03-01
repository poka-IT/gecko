import 'dart:convert';
import 'package:durt2/durt2.dart'
    show
        Query$GetAccountHistory$transfers$edges$node,
        Query$GetUdHistoryViaIdentity$identities$edges$node$udHistory$edges$node;
import 'package:gecko/globals.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/migration_data.dart';
import 'package:gecko/utils.dart';

enum TransactionType { transfer, universalDividend, identityMigrationFrom, identityMigrationTo }

class TransactionDisplayItem {
  final String address;
  final String? username;
  final BigInt amount;
  final String? comment;
  final bool isReceived;
  final DateTime timestamp;
  final DateTime transactionTime;
  final String dateDelimiter;
  final bool isMigrationTime;
  final TransactionType type;
  final String? fromAddress; // For network view: explicit from address
  final String? toAddress; // For network view: explicit to address
  final String? fromUsername; // For network view: from identity name
  final String? toUsername; // For network view: to identity name
  final String? squidId; // Squid transfer id for exact deduplication

  TransactionDisplayItem({
    required this.address,
    this.username,
    required this.amount,
    this.comment,
    required this.isReceived,
    required this.timestamp,
    required this.transactionTime,
    required this.dateDelimiter,
    required this.isMigrationTime,
    required this.type,
    this.fromAddress,
    this.toAddress,
    this.fromUsername,
    this.toUsername,
    this.squidId,
  });

  factory TransactionDisplayItem.fromGraphQLNode(
    Query$GetAccountHistory$transfers$edges$node node,
    String walletAddress,
    DateTime genesisTime,
  ) {
    final bool isReceived = node.toId == walletAddress;
    final String otherAddress = isReceived ? (node.fromId ?? '') : (node.toId ?? '');
    final String? otherUsername = isReceived ? node.from?.identity?.name : node.to?.identity?.name;
    final BigInt amount = BigInt.parse(node.amount);
    // Parse the timestamp as UTC and convert to local time
    final DateTime transactionTime = node.timestamp.parseBlockTimestamp();

    // Calculate date delimiter for grouping
    final String dateDelimiter = calculateDateDelimiter(transactionTime);

    // Check if this is migration time
    final bool isMigrationTime = transactionTime.isBefore(genesisTime);

    final comment = _decodeHexString(node.comment?.remarkBytes);

    return TransactionDisplayItem(
      address: otherAddress,
      username: otherUsername,
      amount: amount,
      comment: comment,
      isReceived: isReceived,
      timestamp: transactionTime,
      transactionTime: transactionTime,
      dateDelimiter: dateDelimiter,
      isMigrationTime: isMigrationTime,
      type: TransactionType.transfer,
      fromAddress: node.fromId,
      toAddress: node.toId,
      fromUsername: node.from?.identity?.name,
      toUsername: node.to?.identity?.name,
      squidId: node.id,
    );
  }

  /// Factory for server-filtered GraphQL nodes (works with both types due to dynamic typing)
  factory TransactionDisplayItem.fromFilteredGraphQLNode(
    dynamic node, // Accept both Query$GetAccountHistory... and Query$GetAccountHistoryFiltered...
    String walletAddress,
    DateTime genesisTime,
  ) {
    final bool isReceived = node.toId == walletAddress;
    final String otherAddress = isReceived ? (node.fromId ?? '') : (node.toId ?? '');
    final String? otherUsername = isReceived ? node.from?.identity?.name : node.to?.identity?.name;
    final BigInt amount = BigInt.parse(node.amount);
    final DateTime transactionTime = (node.timestamp as String).parseBlockTimestamp();

    final String dateDelimiter = calculateDateDelimiter(transactionTime);
    final bool isMigrationTime = transactionTime.isBefore(genesisTime);
    final comment = _decodeHexString(node.comment?.remarkBytes);

    return TransactionDisplayItem(
      address: otherAddress,
      username: otherUsername,
      amount: amount,
      comment: comment,
      isReceived: isReceived,
      timestamp: transactionTime,
      transactionTime: transactionTime,
      dateDelimiter: dateDelimiter,
      isMigrationTime: isMigrationTime,
      type: TransactionType.transfer,
      fromAddress: node.fromId,
      toAddress: node.toId,
      fromUsername: node.from?.identity?.name,
      toUsername: node.to?.identity?.name,
      squidId: node.id,
    );
  }

  factory TransactionDisplayItem.fromNetworkActivityNode(
    dynamic node, // Network activity node
    DateTime genesisTime,
  ) {
    final String fromAddress = node.fromId ?? '';
    final String toAddress = node.toId ?? '';
    final String? fromUsername = node.from?.identity?.name;
    final String? toUsername = node.to?.identity?.name;
    final BigInt amount = BigInt.parse(node.amount);

    // Parse the timestamp as UTC and convert to local time
    final DateTime transactionTime = (node.timestamp as String).parseBlockTimestamp();

    // Calculate date delimiter for grouping
    final String dateDelimiter = calculateDateDelimiter(transactionTime);

    // Check if this is migration time
    final bool isMigrationTime = transactionTime.isBefore(genesisTime);

    final comment = _decodeHexString(node.comment?.remarkBytes);

    // For network view, show "from → to" format
    final displayUsername = fromUsername != null && toUsername != null
        ? '$fromUsername → $toUsername'
        : fromUsername != null
        ? '$fromUsername → ${toAddress.substring(0, 8)}...'
        : toUsername != null
        ? '${fromAddress.substring(0, 8)}... → $toUsername'
        : '${fromAddress.substring(0, 8)}... → ${toAddress.substring(0, 8)}...';

    return TransactionDisplayItem(
      address: fromAddress,
      username: displayUsername,
      amount: amount,
      comment: comment,
      isReceived: true, // In network view, amounts are displayed as positive
      timestamp: transactionTime,
      transactionTime: transactionTime,
      dateDelimiter: dateDelimiter,
      isMigrationTime: isMigrationTime,
      type: TransactionType.transfer,
      fromAddress: fromAddress,
      toAddress: toAddress,
      fromUsername: fromUsername,
      toUsername: toUsername,
    );
  }

  factory TransactionDisplayItem.fromUdHistoryNode(
    Query$GetUdHistoryViaIdentity$identities$edges$node$udHistory$edges$node node,
    String walletAddress,
    DateTime genesisTime,
  ) {
    final BigInt amount = BigInt.parse(node.amount);
    // Parse the timestamp as UTC and convert to local time
    final DateTime transactionTime = node.timestamp.parseBlockTimestamp();

    // Calculate date delimiter for grouping
    final String dateDelimiter = calculateDateDelimiter(transactionTime);

    // Check if this is migration time
    final bool isMigrationTime = transactionTime.isBefore(genesisTime);

    return TransactionDisplayItem(
      address: walletAddress, // For UDs, the address is the wallet address
      username: null, // New UD structure doesn't include identity name directly
      amount: amount,
      comment: null, // UDs don't have comments
      isReceived: true, // UDs are always received
      timestamp: transactionTime,
      transactionTime: transactionTime,
      dateDelimiter: dateDelimiter,
      isMigrationTime: isMigrationTime,
      type: TransactionType.universalDividend,
    );
  }

  factory TransactionDisplayItem.fromMigrationFromEvent(MigrationData migrationData) {
    // For "migration from" events, we show the OLD address this identity migrated FROM
    final String dateDelimiter = calculateDateDelimiter(migrationData.migrationDate);

    return TransactionDisplayItem(
      address: migrationData.fromAddress, // The old address this identity migrated FROM
      username: migrationData.identityName, // Identity name if available
      amount: BigInt.zero, // Migration events don't have amounts
      comment: null, // Migration events don't have comments
      isReceived: false, // Not applicable for migration events
      timestamp: migrationData.migrationDate,
      transactionTime: migrationData.migrationDate,
      dateDelimiter: dateDelimiter,
      isMigrationTime: false, // This is the migration event itself, not a transaction from migration time
      type: TransactionType.identityMigrationFrom,
    );
  }

  factory TransactionDisplayItem.fromMigrationToEvent(MigrationData migrationData) {
    // For "migration to" events, we show the NEW address this identity migrated TO
    final String dateDelimiter = calculateDateDelimiter(migrationData.migrationDate);

    return TransactionDisplayItem(
      address: migrationData.toAddress, // The new address this identity migrated TO
      username: migrationData.identityName, // Identity name if available
      amount: BigInt.zero, // Migration events don't have amounts
      comment: null, // Migration events don't have comments
      isReceived: false, // Not applicable for migration events
      timestamp: migrationData.migrationDate,
      transactionTime: migrationData.migrationDate,
      dateDelimiter: dateDelimiter,
      isMigrationTime: false, // This is the migration event itself, not a transaction from migration time
      type: TransactionType.identityMigrationTo,
    );
  }

  static String _decodeHexString(String? hexString) {
    if (hexString == null) return '';

    try {
      // Remove any leading backslash-x prefix if present
      final cleanHex = hexString.replaceAll(r'\x', '');

      // Convert hex string to bytes
      final List<int> bytes = [];
      for (int i = 0; i < cleanHex.length; i += 2) {
        if (i + 1 < cleanHex.length) {
          String hexByte = cleanHex.substring(i, i + 2);
          bytes.add(int.parse(hexByte, radix: 16));
        }
      }

      // Try UTF-8 first
      try {
        final result = utf8.decode(bytes);
        // Check if the result contains replacement characters
        if (!result.contains('�')) {
          return result;
        }
      } catch (_) {}

      // If UTF-8 fails or contains replacement characters, try Latin-1
      try {
        return latin1.decode(bytes);
      } catch (_) {}

      // If both fail, fallback to UTF-8 with malformed allowed
      return utf8.decode(bytes, allowMalformed: true);
    } catch (e) {
      // If decoding fails, return the original string
      log.e('Error decoding hex string: $e');
      return hexString;
    }
  }

  /// Check if this is a universal dividend
  bool get isUniversalDividend => type == TransactionType.universalDividend;

  /// Check if this is an identity migration "from" event
  bool get isIdentityMigrationFrom => type == TransactionType.identityMigrationFrom;

  /// Check if this is an identity migration "to" event
  bool get isIdentityMigrationTo => type == TransactionType.identityMigrationTo;

  Map<String, dynamic> toJson() => {
    'address': address,
    'username': username,
    'amount': amount.toString(),
    'comment': comment,
    'isReceived': isReceived,
    'timestamp': timestamp.toIso8601String(),
    'transactionTime': transactionTime.toIso8601String(),
    'dateDelimiter': dateDelimiter,
    'isMigrationTime': isMigrationTime,
    'type': type.name,
    'fromAddress': fromAddress,
    'toAddress': toAddress,
    'fromUsername': fromUsername,
    'toUsername': toUsername,
    'squidId': squidId,
  };

  factory TransactionDisplayItem.fromJson(Map<String, dynamic> json) => TransactionDisplayItem(
    address: json['address'] as String,
    username: json['username'] as String?,
    amount: BigInt.parse(json['amount'] as String),
    comment: json['comment'] as String?,
    isReceived: json['isReceived'] as bool,
    timestamp: DateTime.parse(json['timestamp'] as String),
    transactionTime: DateTime.parse(json['transactionTime'] as String),
    dateDelimiter: json['dateDelimiter'] as String,
    isMigrationTime: json['isMigrationTime'] as bool,
    type: TransactionType.values.byName(json['type'] as String),
    fromAddress: json['fromAddress'] as String?,
    toAddress: json['toAddress'] as String?,
    fromUsername: json['fromUsername'] as String?,
    toUsername: json['toUsername'] as String?,
    squidId: json['squidId'] as String?,
  );

  /// Get a display-friendly type name
  String get displayType {
    return switch (type) {
      TransactionType.universalDividend => "Universal Dividend",
      TransactionType.identityMigrationFrom => "Identity Migration From",
      TransactionType.identityMigrationTo => "Identity Migration To",
      TransactionType.transfer => "Transfer",
    };
  }
}
