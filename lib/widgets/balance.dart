import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/widgets/ud_unit_display.dart';
import 'package:provider/provider.dart';

class Balance extends StatelessWidget {
  const Balance(
      {Key? key,
      required this.address,
      required this.size,
      this.color = Colors.black,
      this.loadingColor = const Color(0xffd07316)})
      : super(key: key);
  final String address;
  final double size;
  final Color color;
  final Color loadingColor;

  @override
  Widget build(BuildContext context) {
    final walletOptions =
        Provider.of<WalletOptionsProvider>(context, listen: false);
    return Consumer<SubstrateSdk>(builder: (context, sdk, _) {
      return FutureBuilder(
          future: sdk.getBalance(address),
          builder: (BuildContext context,
              AsyncSnapshot<Map<String, double>> globalBalance) {
            if (globalBalance.connectionState != ConnectionState.done ||
                globalBalance.hasError) {
              if (walletOptions.balanceCache[address] != null &&
                  walletOptions.balanceCache[address] != -1) {
                return Row(children: [
                  Text(walletOptions.balanceCache[address]!.toString(),
                      style: scaledTextStyle(fontSize: size, color: color)),
                  ScaledSizedBox(width: 5),
                  UdUnitDisplay(size: scaleSize(size), color: color),
                ]);
              } else {
                return ScaledSizedBox(
                  height: 15,
                  width: 15,
                  child: CircularProgressIndicator(
                    color: loadingColor,
                    strokeWidth: 2,
                  ),
                );
              }
            }
            walletOptions.balanceCache[address] =
                globalBalance.data!['transferableBalance']!;
            if (walletOptions.balanceCache[address] != -1) {
              return Row(children: [
                Text(
                  walletOptions.balanceCache[address]!.toString(),
                  style: scaledTextStyle(
                    fontSize: size,
                    color: color,
                  ),
                ),
                ScaledSizedBox(width: 5),
                UdUnitDisplay(size: scaleSize(size), color: color),
              ]);
            } else {
              return const Text('');
            }
          });
    });
  }
}
