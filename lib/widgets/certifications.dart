import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:provider/provider.dart';

class Certifications extends StatelessWidget {
  const Certifications(
      {Key? key,
      required this.address,
      required this.size,
      this.color = Colors.black})
      : super(key: key);
  final String address;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final sub = Provider.of<SubstrateSdk>(context);

    return Column(children: <Widget>[
      FutureBuilder(
          future: sub.getCertsCounter(address),
          builder: (BuildContext context, AsyncSnapshot<List<int>?> certs) {
            if ((certs.data != null && certs.data!.isEmpty) ||
                sub.certsCounterCache[address] == null) {
              return const SizedBox.shrink();
            }

            final receivedCount = sub.certsCounterCache[address]![0];
            final sentCount = sub.certsCounterCache[address]![1];

            return Row(
              children: [
                Image.asset('assets/medal.png',
                    color: color, height: scaleSize(18)),
                ScaledSizedBox(width: 1),
                Text(receivedCount.toString(),
                    style: scaledTextStyle(fontSize: size, color: color)),
                ScaledSizedBox(width: 5),
                Text(
                  "($sentCount)",
                  style: scaledTextStyle(fontSize: size * 0.7, color: color),
                )
              ],
            );
          }),
    ]);
  }
}
