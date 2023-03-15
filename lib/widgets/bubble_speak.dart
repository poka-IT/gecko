import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';

class BubbleSpeak extends StatelessWidget {
  const BubbleSpeak({
    required this.text,
    this.long,
    this.textKey,
    Key? key,
  }) : super(key: key);

  final String text;
  final double? long;
  final Key? textKey;

  @override
  Widget build(BuildContext context) {
    return Bubble(
      padding: long == null
          ? const BubbleEdges.all(20)
          : BubbleEdges.symmetric(horizontal: long, vertical: 30),
      elevation: 5,
      color: backgroundColor,
      child: Text(
        text,
        key: textKey,
        style: const TextStyle(
            color: Colors.black, fontSize: 21, fontWeight: FontWeight.w400),
      ),
    );
  }
}
