import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/widgets/commons/loading.dart';
import 'package:gecko/widgets/transaction_status.dart';

class TransactionStatusIcon extends StatelessWidget {
  const TransactionStatusIcon(this.status,
      {Key? key, this.size = 32, this.stroke = 3})
      : super(key: key);
  final TransactionStatus status;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case TransactionStatus.sending:
      case TransactionStatus.propagation:
      case TransactionStatus.validating:
        return Loading(size: size, stroke: stroke);
      case TransactionStatus.success:
        return Icon(
          Icons.done,
          size: scaleSize(size),
          color: Colors.green,
        );
      case TransactionStatus.finalized:
        return Icon(
          Icons.done_all,
          size: scaleSize(size),
          color: Colors.green,
        );
      case TransactionStatus.failed:
      case TransactionStatus.timeout:
        return Icon(
          Icons.close,
          size: scaleSize(size),
          color: Colors.red,
        );
      case TransactionStatus.none:
      default:
        return ScaledSizedBox(height: size, width: size);
    }
  }
}
