import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';

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
        height: boxHeight,
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

  Widget buildText(List<TextSpan> text, [double size = 20]) {
    return Container(
      padding: const EdgeInsets.all(12),
      width: 440,
      decoration: BoxDecoration(
          color: Colors.white, border: Border.all(color: Colors.grey[900]!)),
      child: RichText(
        textAlign: TextAlign.justify,
        text: TextSpan(
          style: TextStyle(
              fontSize: size, color: Colors.black, letterSpacing: 0.3),
          children: text,
        ),
      ),
    );
  }

  Widget nextButton(
      BuildContext context, String text, nextScreen, bool isFast) {
    return SizedBox(
      width: 410,
      height: 70,
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
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget buildProgressBar(double pagePosition) {
    return DotsIndicator(
      dotsCount: 11,
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
    List<TextSpan> text,
    String assetName,
    String buttonText,
    nextScreen,
    double pagePosition, {
    bool isFast = false,
    double boxHeight = 440,
    double imageWidth = 350,
    double textSize = 20,
  }) {
    return Column(children: <Widget>[
      SizedBox(height: isTall ? 40 : 20),
      buildProgressBar(pagePosition),
      SizedBox(height: isTall ? 40 : 20),

      buildText(text, textSize),
      buildImage(assetName, boxHeight, imageWidth),
      Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: nextButton(context, buttonText, nextScreen, false),
        ),
      ),
      // const SizedBox(height: 40),
      SizedBox(height: isTall ? 40 : 10),
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

class SlideLeftRoute extends PageRouteBuilder {
  final Widget? page;
  SlideLeftRoute({this.page})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page!,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
}

class GeckoSpeechAppBar extends StatelessWidget with PreferredSizeWidget {
  @override
  final Size preferredSize;
  final String title;

  GeckoSpeechAppBar(
    this.title, {
    Key? key,
  })  : preferredSize = const Size.fromHeight(105.4),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
        toolbarHeight: 60 * ratio,
        leading: IconButton(
          icon: SizedBox(
              height: 30,
              child: Image.asset('assets/onBoarding/gecko_bar.png')),
          onPressed: () => Navigator.popUntil(
            context,
            ModalRoute.withName('/'),
          ),
        ),
        title: SizedBox(
          height: 25,
          child: Text(title),
        ));
  }
}
