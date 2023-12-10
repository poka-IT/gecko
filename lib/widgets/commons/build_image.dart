import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';

class BuildImage extends StatelessWidget {
  const BuildImage({
    Key? key,
    required this.assetName,
    required this.boxHeight,
    required this.imageWidth,
  }) : super(key: key);

  final String assetName;
  final double boxHeight;
  final double imageWidth;

  @override
  Widget build(BuildContext context) {
    final ratio = isTall ? 1 : 0.95;
    return Container(
        padding: const EdgeInsets.all(0),
        width: scaleSize(imageWidth * ratio),
        height: scaleSize(boxHeight * ratio),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xffd2d4cf),
                Color(0xffeaeae7),
              ],
            ),
            border: Border.all(color: Colors.grey[900]!)),
        child: Image.asset('assets/onBoarding/$assetName'));
  }
}
