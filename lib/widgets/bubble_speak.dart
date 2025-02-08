import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';

class BubbleSpeak extends StatelessWidget {
  const BubbleSpeak({
    required this.text,
    this.long,
    this.fontSize = 18,
    this.textKey,
    super.key,
  });

  final String text;
  final double? long;
  final double fontSize;
  final Key? textKey;

  @override
  Widget build(BuildContext context) {
    return Bubble(
      padding: long == null ? BubbleEdges.all(isTall ? 18 : 12) : BubbleEdges.symmetric(horizontal: long, vertical: 30),
      elevation: 5,
      color: backgroundColor,
      child: Text(
        text,
        key: textKey,
        style: scaledTextStyle(color: Colors.black, fontSize: isTall ? fontSize : fontSize * 0.9, fontWeight: FontWeight.w400),
      ),
    );
  }
}

class BubbleSpeakWithTail extends StatelessWidget {
  const BubbleSpeakWithTail({
    required this.text,
    this.long,
    this.fontSize = 18,
    this.textKey,
    super.key,
  });

  final String text;
  final double? long;
  final double fontSize;
  final Key? textKey;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      clipBehavior: Clip.none,
      children: [
        BubbleSpeak(text: text, fontSize: fontSize, textKey: textKey, long: long),
        Positioned(
          left: 15,
          bottom: -scaleSize(28),
          child: Image(
            image: const AssetImage('assets/home/bout_de_bulle.png'),
            height: scaleSize(30),
          ),
        ),
      ],
    );
  }
}
