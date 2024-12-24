import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/widgets/commons/loading.dart';
import 'package:gecko/widgets/transaction_status.dart';

class TransactionStatusIcon extends StatelessWidget {
  const TransactionStatusIcon(this.status, {super.key, this.size = 32, this.stroke = 3});
  final TransactionStatus status;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) => switch (status) {
        TransactionStatus.sending || TransactionStatus.propagation || TransactionStatus.validating => Loading(size: size, stroke: stroke),
        TransactionStatus.success => Icon(
            Icons.done,
            size: scaleSize(size),
            color: Colors.green,
          ),
        TransactionStatus.finalized => Icon(
            Icons.done_all,
            size: scaleSize(size),
            color: Colors.green,
          ),
        TransactionStatus.failed || TransactionStatus.timeout => Icon(
            Icons.close,
            size: scaleSize(size),
            color: Colors.red,
          ),
        TransactionStatus.none => ScaledSizedBox(height: size, width: size)
      };
}
