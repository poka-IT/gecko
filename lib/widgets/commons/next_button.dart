import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/widgets/commons/fader_transition.dart';

class NextButton extends StatelessWidget {
  const NextButton({
    super.key,
    required this.text,
    required this.nextScreen,
    required this.isFast,
  });

  final String text;
  final Widget nextScreen;
  final bool isFast;

  @override
  Widget build(BuildContext context) {
    return ScaledSizedBox(
      width: 340,
      height: 55,
      child: ElevatedButton(
        key: keyGoNext,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: orangeC,
          elevation: 4,
        ),
        onPressed: () {
          Navigator.push(
              context, FaderTransition(page: nextScreen, isFast: isFast));
        },
        child: Text(
          text,
          style: scaledTextStyle(
              fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }
}
