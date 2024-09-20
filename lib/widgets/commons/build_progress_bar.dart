import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';

class BuildProgressBar extends StatelessWidget {
  const BuildProgressBar({
    super.key,
    required this.pagePosition,
  });

  final int pagePosition;

  @override
  Widget build(BuildContext context) {
    return DotsIndicator(
      dotsCount: 10,
      position: pagePosition,
      decorator: DotsDecorator(
        size: Size.square(scaleSize(7)),
        activeSize: Size.square(scaleSize(10)),
        spacing: EdgeInsets.symmetric(horizontal: scaleSize(10)),
        color: Colors.grey[400]!,
        activeColor: orangeC,
      ),
    );
  }
}
