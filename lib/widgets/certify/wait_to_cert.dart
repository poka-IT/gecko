import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/screens/wallet_view.dart' show buttonSize, buttonFontSize;

class WaitToCertWidget extends StatelessWidget {
  final String messageKey;
  final String duration;

  const WaitToCertWidget(
      {super.key, required this.messageKey, required this.duration});

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      ScaledSizedBox(
        height: buttonSize,
        child: Container(
          foregroundDecoration: const BoxDecoration(
            color: Colors.grey,
            backgroundBlendMode: BlendMode.saturation,
          ),
          child: const Opacity(
            opacity: 0.5,
            child: Image(image: AssetImage('assets/gecko_certify.png')),
          ),
        ),
      ),
      Text(
        messageKey.tr(args: [duration]),
        textAlign: TextAlign.center,
        style: scaledTextStyle(
            fontSize: buttonFontSize - 4,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600]),
      ),
    ]);
  }
}
