import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:provider/provider.dart';

class CertsCounter extends StatelessWidget {
  const CertsCounter({super.key, required this.address, this.isSent = false});
  final String address;
  final bool isSent;

  @override
  Widget build(BuildContext context) {
    return Consumer<SubstrateSdk>(builder: (context, sub, _) {
      return Text(
        '(${isSent ? sub.certsCounterCache[address]!.sentCount : sub.certsCounterCache[address]!.receivedCount})',
        style: scaledTextStyle(fontSize: 16),
      );
    });
  }
}
