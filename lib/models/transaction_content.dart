import 'package:durt2/durt2.dart';

class TransactionContent {
  final String transactionId;
  TransactionState state;
  final String from;
  final String to;
  final double amount;
  String? error;

  TransactionContent({
    required this.transactionId,
    required this.state,
    required this.from,
    required this.to,
    required this.amount,
    this.error,
  });
}
