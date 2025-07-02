import 'dart:async';

import 'package:durt2/durt2.dart';

class TransactionInProgressData {
  const TransactionInProgressData({required this.status, required this.toAddress, required this.amount, required this.comment});

  final Stream<TransactionStatus> status;
  final String toAddress;
  final double amount;
  final String comment;
}
