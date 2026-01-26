import 'package:durt2/durt2.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/widgets/commons/loading.dart';

class TransactionStateIcon extends StatelessWidget {
  const TransactionStateIcon(this.state, {super.key, this.size = 32, this.stroke = 3});
  final TransactionState state;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) => switch (state) {
    TransactionState.pending || TransactionState.futureNonce || TransactionState.retrying => Loading(size: size, stroke: stroke),
    TransactionState.inBlock => Icon(Icons.done, size: scaleSize(size), color: Colors.green),
    TransactionState.finalized => Icon(Icons.done_all, size: scaleSize(size), color: Colors.green),
    TransactionState.error || TransactionState.timeout => Icon(Icons.close, size: scaleSize(size), color: Colors.red),
    TransactionState.none => ScaledSizedBox(height: size, width: size),
  };
}
