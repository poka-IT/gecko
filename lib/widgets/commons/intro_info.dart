import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/widgets/commons/build_image.dart';
import 'package:gecko/widgets/commons/build_progress_bar.dart';
import 'package:gecko/widgets/commons/build_text.dart';
import 'package:gecko/widgets/commons/next_button.dart';

class InfoIntro extends StatelessWidget {
  const InfoIntro({
    super.key,
    required this.text,
    required this.assetName,
    required this.buttonText,
    required this.nextScreen,
    required this.pagePosition,
    this.isMd = false,
    this.isFast = false,
    this.boxHeight = 340,
    this.imageWidth = 350,
    this.textSize = 17,
  });

  final String text;
  final String assetName;
  final String buttonText;
  final Widget nextScreen;
  final int pagePosition;
  final bool isMd;
  final bool isFast;
  final double boxHeight;
  final double imageWidth;
  final double textSize;

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      ScaledSizedBox(height: isTall ? 25 : 5),
      BuildProgressBar(pagePosition: pagePosition),
      ScaledSizedBox(height: isTall ? 25 : 5),
      BuildText(text: text, size: textSize, isMd: isMd),
      BuildImage(
          assetName: assetName, boxHeight: boxHeight, imageWidth: imageWidth),
      Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: NextButton(
              text: buttonText, nextScreen: nextScreen, isFast: false),
        ),
      ),
      ScaledSizedBox(height: isTall ? 40 : 5),
    ]);
  }
}
