import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:provider/provider.dart';

class CommonElements {
  // Exemple de Widget
  Widget exemple(String data) {
    return const Text('Coucou');
  }

  Widget buildImage(String assetName,
      [double boxHeight = 440, double imageWidth = 350]) {
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

  Widget buildText(String text, [double size = 20]) {
    return Container(
      padding: const EdgeInsets.all(12),
      width: 440,
      decoration: BoxDecoration(
          color: Colors.white, border: Border.all(color: Colors.grey[900]!)),
      child: Text(text,
          textAlign: TextAlign.justify,
          style: TextStyle(
              fontSize: isTall ? size : size * 0.9,
              color: Colors.black,
              letterSpacing: 0.3)),
    );
  }

  Widget buildTextMd(String text, [double size = 20]) {
    final style = MarkdownStyleSheet(
      p: TextStyle(
          fontSize: isTall ? size : size * 0.9,
          color: Colors.black,
          letterSpacing: 0.3),
      textAlign: WrapAlignment.spaceBetween,
    );

    return Container(
        padding: const EdgeInsets.all(12),
        width: 440,
        decoration: BoxDecoration(
            color: Colors.white, border: Border.all(color: Colors.grey[900]!)),
        child: MarkdownBody(data: text, styleSheet: style));

    //   RichText(
    //     textAlign: TextAlign.justify,
    //     text: TextSpan(
    //       style: TextStyle(
    //           fontSize: isTall ? size : size * 0.9,
    //           color: Colors.black,
    //           letterSpacing: 0.3),
    //       children: text,
    //     ),
    //   ),
    // );
  }

  Widget nextButton(
      BuildContext context, String text, nextScreen, bool isFast) {
    return SizedBox(
      width: 380 * ratio,
      height: 60 * ratio,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          primary: orangeC, // background
          onPrimary: Colors.white, // foreground
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

  Widget buildProgressBar(double pagePosition) {
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

  Widget infoIntro(
    BuildContext context,
    String text,
    String assetName,
    String buttonText,
    nextScreen,
    double pagePosition, {
    String? textMd,
    bool isFast = false,
    double boxHeight = 440,
    double imageWidth = 350,
    double textSize = 20,
  }) {
    return Column(children: <Widget>[
      SizedBox(height: isTall ? 40 : 20),
      buildProgressBar(pagePosition),
      SizedBox(height: isTall ? 40 : 20),

      if (textMd == null)
        buildText(text, textSize)
      else
        buildTextMd(textMd, textSize),

      buildImage(assetName, boxHeight, imageWidth),
      Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: nextButton(context, buttonText, nextScreen, false),
        ),
      ),
      // const SizedBox(height: 40),
      SizedBox(height: isTall ? 40 : 20),
    ]);
  }

  Widget roundButton(
    AssetImage image,
    ontap,
    isAsync,
    double imgHight,
    EdgeInsets padding,
  ) {
    return Container(
      child: ClipOval(
        child: Material(
          color: const Color(0xffFFD58D), // button color
          child: InkWell(
              splashColor: orangeC, // inkwell color
              child: Padding(
                  padding: padding,
                  child: Image(image: image, height: imgHight)),
              onTap: () async {
                await ontap;
              }),
        ),
      ),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.grey,
              blurRadius: 4.0,
              offset: Offset(2.0, 2.5),
              spreadRadius: 0.5)
        ],
      ),
    );
  }

  Widget offlineInfo(BuildContext context) {
    // SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);
    final double screenWidth = MediaQuery.of(context).size.width;
    return Consumer<SubstrateSdk>(builder: (context, _sub, _) {
      return Visibility(
        visible: !_sub.nodeConnected,
        child: Positioned(
          top: 0,
          child: Container(
              height: 30,
              width: screenWidth,
              color: Colors.grey[800],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Vous êtes hors ligne...",
                    style: TextStyle(color: Colors.grey[50]),
                    textAlign: TextAlign.center,
                  ),
                ],
              )),
        ),
      );
    });
  }
}

class SmoothTransition extends PageRouteBuilder {
  final Widget? page;
  SmoothTransition({this.page})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              TweenAnimationBuilder(
            duration: const Duration(seconds: 5),
            tween: Tween(begin: 200, end: 200),
            builder: (BuildContext context, dynamic value, Widget? child) {
              return page!;
            },
          ),
        );
}

class FaderTransition extends PageRouteBuilder {
  final Widget page;
  final bool isFast;

  FaderTransition({required this.page, required this.isFast})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) =>
              FadeTransition(
            opacity:
                Tween(begin: 0.0, end: isFast ? 3.0 : 1.0).animate(animation),
            child: child,
          ),
        );
}

Future<bool?> confirmPopup(BuildContext context, String title) async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: backgroundColor,
        content: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        ),
        actions: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                key: const Key('confirmPopop'),
                child: const Text(
                  "Oui",
                  style: TextStyle(
                    fontSize: 21,
                    color: Color(0xffD80000),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context, true);
                },
              ),
              const SizedBox(width: 20),
              TextButton(
                child: const Text(
                  "Non",
                  style: TextStyle(fontSize: 21),
                ),
                onPressed: () {
                  Navigator.pop(context, false);
                },
              ),
              const SizedBox(height: 120)
            ],
          )
        ],
      );
    },
  );
}

Future<void> infoPopup(BuildContext context, String title) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: backgroundColor,
        content: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        ),
        actions: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                key: const Key('infoPopup'),
                child: const Text(
                  "D'accord",
                  style: TextStyle(
                    fontSize: 21,
                    color: Color(0xffD80000),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context, true);
                },
              ),
            ],
          )
        ],
      );
    },
  );
}

// Widget geckoAppBar() {
//   return AppBar(
//     toolbarHeight: 60 * ratio,
//     elevation: 0,
//     leading: IconButton(
//         icon: const Icon(Icons.arrow_back, color: Colors.black),
//         onPressed: () {
//           _walletOptions.isEditing = false;
//           _walletOptions.isBalanceBlur = false;
//           Navigator.pop(context);
//         }),
//     title: SizedBox(
//       height: 22,
//       child: Consumer<WalletOptionsProvider>(
//           builder: (context, walletProvider, _) {
//         return Text(_walletOptions.nameController.text);
//       }),
//     ),
//   );
// }
