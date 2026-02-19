import 'package:durt2/durt2.dart' show WalletEntity;
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/services/wallet_name_service.dart';

class WalletName extends StatelessWidget {
  const WalletName({super.key, required this.wallet, this.size = 20, this.color = Colors.black, this.maxWidth});

  final WalletEntity wallet;
  final double size;
  final Color color;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth ?? MediaQuery.of(context).size.width * 0.3),
      child: Text(
        WalletNameService.displayName(wallet.name),
        maxLines: 1,
        textAlign: TextAlign.center,
        style: scaledTextStyle(fontSize: size, color: color, fontWeight: FontWeight.w400),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
