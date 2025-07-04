import 'package:durt2/durt2.dart' show Query$GetAccountHistory$transferConnection$edges$node;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';

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
  });

  factory TransactionDisplayItem.fromGraphQLNode(
    Query$GetAccountHistory$transferConnection$edges$node node,
    String walletAddress,
    DateTime genesisTime,
  ) {
    final bool isReceived = node.toId == walletAddress;
    final String otherAddress = isReceived ? (node.fromId ?? '') : (node.toId ?? '');
    final String? otherUsername = isReceived ? node.from?.identity?.name : node.to?.identity?.name;
    final BigInt amount = BigInt.parse(node.amount);
    final DateTime transactionTime = DateTime.parse(node.timestamp);

    // Calculate date delimiter for grouping
    final String dateDelimiter = _calculateDateDelimiter(transactionTime);

    // Check if this is migration time (before genesis + 7 days)
    final bool isMigrationTime = transactionTime.isBefore(genesisTime.add(const Duration(days: 7)));

    return TransactionDisplayItem(
      address: otherAddress,
      username: otherUsername,
      amount: amount,
      comment: node.comment?.remark,
      isReceived: isReceived,
      timestamp: transactionTime,
      transactionTime: transactionTime,
      dateDelimiter: dateDelimiter,
      isMigrationTime: isMigrationTime,
    );
  }

  static String _calculateDateDelimiter(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return "today";
    } else if (difference.inDays == 1) {
      return "yesterday";
    } else if (difference.inDays < 7) {
      return "${difference.inDays} days ago";
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
}
