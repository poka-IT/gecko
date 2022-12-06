import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:truncate/truncate.dart';

class WalletName extends StatelessWidget {
  const WalletName(
      {Key? key,
      required this.wallet,
      this.size = 20,
      this.color = Colors.black})
      : super(key: key);
  final WalletData wallet;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
   double newSize = wallet.name!.length <= 15 ? size : size - 2;

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
      Text(
        truncate(wallet.name!, 20),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isTall ? newSize : newSize * 0.9,
          color: color,
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
        ),
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      ),
    ]);
  }
}
