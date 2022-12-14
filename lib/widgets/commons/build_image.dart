import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';

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
    return Container(
        padding: const EdgeInsets.all(0),
        width: 440,
        height: isTall ? boxHeight : boxHeight * 0.9,
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
        child: Image.asset('assets/onBoarding/$assetName', width: imageWidth));
  }
}
