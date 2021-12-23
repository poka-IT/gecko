import 'package:flutter/material.dart';
import 'package:bubble/bubble.dart';
import 'package:gecko/globals.dart';

class CommonElements {
  // Exemple de Widget
  Widget exemple(String data) {
    return const Text('Coucou');
  }

  Widget bubbleSpeak(String text, {double? long, Key? textKey}) {
    return Bubble(
      padding: long == null
          ? const BubbleEdges.all(18)
          : BubbleEdges.symmetric(horizontal: long, vertical: 30),
      elevation: 5,
      color: Colors.white,
      margin: const BubbleEdges.fromLTRB(10, 0, 20, 10),
      // nip: BubbleNip.leftTop,
      child: Text(
        text,
        key: textKey,
        style: const TextStyle(
            color: Colors.black, fontSize: 18, fontWeight: FontWeight.w400),
      ),
    );
  }

  Widget bubbleSpeakRich(List<TextSpan> text, {Key? textKey}) {
    return Bubble(
      padding: const BubbleEdges.all(18),
      elevation: 5,
      color: Colors.white,
      margin: const BubbleEdges.fromLTRB(10, 0, 20, 10),
      // nip: BubbleNip.leftTop,
      child: RichText(
        key: textKey,
        text: TextSpan(
          style: const TextStyle(
            fontSize: 18.0,
            color: Colors.black,
          ),
          children: text,
        ),
      ),
    );
  }

  Widget onboardingProgressBar(
      BuildContext context, String screenTitle, int progress) {
    return Stack(children: [
      Container(height: 100),
      Positioned(
          top: 0, left: 0, right: 0, child: GeckoSpeechAppBar(screenTitle)),
      Positioned(
        top: 0,
        left: 0,
        child: GestureDetector(
          onTap: () {
            Navigator.popUntil(
              context,
              ModalRoute.withName('/'),
            );
          },
          child: Image.asset(
            'assets/onBoarding/gecko_bar.png',
          ),
        ),
      ),
      if (progress != 0)
        Positioned(
          top: 75,
          left: 90,
          child: Image.asset(
            'assets/onBoarding/progress_bar/total.png',
          ),
        ),
      if (progress != 0)
        Positioned(
          top: 75,
          left: 90,
          child: Image.asset(
            'assets/onBoarding/progress_bar/$progress.png',
          ),
        ),
      if (progress != 0)
        Positioned(
          top: 70,
          right: 90,
          child: Text(progress == 12 ? '11/11' : '$progress/11',
              style: const TextStyle(fontSize: 12, color: Colors.black)),
        ),
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
