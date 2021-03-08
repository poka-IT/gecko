import 'package:flutter/material.dart';
import 'package:bubble/bubble.dart';

class CommonElements {
  // Exemple de Widget
  Widget exemple(String data) {
    return Text('Coucou');
  }

  Widget bubbleSpeak(String text, {double long}) {
    return Bubble(
      padding: long == null
          ? BubbleEdges.all(18)
          : BubbleEdges.symmetric(horizontal: long, vertical: 30),
      elevation: 5,
      color: Colors.white,
      margin: BubbleEdges.fromLTRB(10, 0, 20, 10),
      // nip: BubbleNip.leftTop,
      child: Text(
        text,
        style: TextStyle(
            color: Colors.black, fontSize: 18, fontWeight: FontWeight.w400),
      ),
    );
  }

  Widget bubbleSpeakRich(List<TextSpan> text) {
    return Bubble(
      padding: BubbleEdges.all(18),
      elevation: 5,
      color: Colors.white,
      margin: BubbleEdges.fromLTRB(10, 0, 20, 10),
      // nip: BubbleNip.leftTop,
      child: RichText(
          text: TextSpan(
        style: TextStyle(
          fontSize: 18.0,
          color: Colors.black,
        ),
        children: text,
      )),
    );
  }

  Widget onboardingProgressBar(String screenTitle, int progress) {
    return Stack(children: [
      Container(height: 100),
      Positioned(
          top: 0, left: 0, right: 0, child: GeckoSpeechAppBar(screenTitle)),
      Positioned(
        top: 0,
        left: 0,
        child: Image.asset(
          'assets/onBoarding/gecko_bar.png',
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
              style: TextStyle(fontSize: 12, color: Colors.black)),
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
          color: Color(0xffFFD58D), // button color
          child: InkWell(
              splashColor: Color(0xffD28928), // inkwell color
              child: Padding(
                  padding: padding,
                  child: Image(image: image, height: imgHight)),
              onTap: () async {
                await ontap;
              }),
        ),
      ),
      decoration: BoxDecoration(
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
  final Widget page;
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
            builder: (BuildContext context, dynamic value, Widget child) {
              return page;
            },
          ),
        );
}

class SlideLeftRoute extends PageRouteBuilder {
  final Widget page;
  SlideLeftRoute({this.page})
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
    Key key,
  })  : preferredSize = Size.fromHeight(105.4),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
        leading: IconButton(
          icon: Container(
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
