import 'package:gecko/widgets/transaction_status.dart';

class TransactionContent {
  final String transactionId;
  TransactionStatus status;
  final String from;
  final String to;
  final double amount;
  String? error;

  TransactionContent({
    required this.transactionId,
    required this.status,
    required this.from,
    required this.to,
    required this.amount,
    this.error,
  });
}
