import 'package:flutter/material.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:provider/provider.dart';

class CertsCounter extends StatelessWidget {
  const CertsCounter({Key? key, required this.address, this.isSent = false})
      : super(key: key);
  final String address;
  final bool isSent;

  @override
  Widget build(BuildContext context) {
    return Consumer<SubstrateSdk>(builder: (context, sub, _) {
      return Text('(${sub.certsCounterCache[address]![isSent ? 1 : 0]})');
    });
  }
}
