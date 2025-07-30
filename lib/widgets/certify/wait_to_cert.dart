import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/screens/profile_view.dart' show buttonSize, buttonFontSize;

class WaitToCertWidget extends StatelessWidget {
  final String label;
  final String duration;

  const WaitToCertWidget({super.key, required this.label, required this.duration});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ScaledSizedBox(
          height: buttonSize,
          child: Opacity(
            opacity: 0.4,
            child: Image(
              image: const AssetImage('assets/gecko_certify.png'),
              color: context.colorScheme.surface,
              colorBlendMode: BlendMode.saturation,
            ),
          ),
        ),
        Container(
          constraints: BoxConstraints(maxWidth: scaleSize(100)),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: scaledTextStyle(fontSize: buttonFontSize - 4, fontWeight: FontWeight.w400, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }
}
