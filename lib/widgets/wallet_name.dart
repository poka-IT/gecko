import 'package:durt2/durt2.dart' show WalletData;
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';

class WalletName extends StatelessWidget {
  const WalletName({
    super.key,
    required this.wallet,
    this.size = 20,
    this.color = Colors.black,
    this.maxWidth,
  });

  final WalletData wallet;
  final double size;
  final Color color;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? MediaQuery.of(context).size.width * 0.3,
      ),
      child: Text(
        wallet.name ?? '',
        maxLines: 1,
        textAlign: TextAlign.center,
        style: scaledTextStyle(
          fontSize: size,
          color: color,
          fontWeight: FontWeight.w400,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
