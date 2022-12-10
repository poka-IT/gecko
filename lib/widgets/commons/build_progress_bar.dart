import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';

class BuildProgressBar extends StatelessWidget {
  const BuildProgressBar({
    Key? key,
    required this.pagePosition,
  }) : super(key: key);

  final double pagePosition;

  @override
  Widget build(BuildContext context) {
    return DotsIndicator(
      dotsCount: 10,
      position: pagePosition,
      decorator: DotsDecorator(
        spacing: const EdgeInsets.symmetric(horizontal: 10),
        color: Colors.grey[300]!, // Inactive color
        activeColor: orangeC,
      ),
    );
  }
}
