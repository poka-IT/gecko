import 'package:flutter/material.dart';
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
    return Column(children: <Widget>[
      Consumer<SubstrateSdk>(builder: (context, sdk, _) {
        return FutureBuilder(
            future: sdk.getCertsCounter(address),
            builder: (BuildContext context, AsyncSnapshot<List<int>?> certs) {
              return certs.data != null
                  ? Row(
                      children: [
                        Image.asset('assets/medal.png',
                            color: color, height: 20),
                        const SizedBox(width: 1),
                        Text(certs.data?[0].toString() ?? '0',
                            style: TextStyle(fontSize: size, color: color)),
                        const SizedBox(width: 5),
                        Text(
                          "(${certs.data?[1].toString() ?? '0'})",
                          style: TextStyle(fontSize: size * 0.7, color: color),
                        )
                      ],
                    )
                  : const Text('');
            });
      }),
    ]);
  }
}
