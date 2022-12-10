import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/widgets/commons/fader_transition.dart';

class NextButton extends StatelessWidget {
  const NextButton({
    Key? key,
    required this.text,
    required this.nextScreen,
    required this.isFast,
  }) : super(key: key);

  final String text;
  final Widget nextScreen;
  final bool isFast;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 380 * ratio,
      height: 60 * ratio,
      child: ElevatedButton(
        key: keyGoNext,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, backgroundColor: orangeC,
          elevation: 4, // foreground
        ),
        onPressed: () {
          Navigator.push(
              context, FaderTransition(page: nextScreen, isFast: isFast));
        },
        child: Text(
          text,
          style: TextStyle(fontSize: 23 * ratio, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
