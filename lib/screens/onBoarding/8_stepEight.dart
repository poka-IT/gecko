import 'dart:ui';

import 'package:bubble/bubble.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/screens/commonElements.dart';
import 'package:gecko/screens/onBoarding/9_stepNine.dart';

// ignore: must_be_immutable
class OnboardingStepEight extends StatelessWidget {
  TextEditingController tplController = TextEditingController();
  final int progress = 42;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return Scaffold(
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: Column(children: <Widget>[
            Stack(children: [
              Container(height: 100),
              Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: GeckoSpeechAppBar('Ma phrase de restauration')),
              Positioned(
                top: 0,
                left: 0,
                child: Image.asset(
                  'assets/onBoarding/gecko_bar.png',
                ),
              ),
              Positioned(
                top: 70,
                left: 50,
                child: Image.asset(
                  'assets/onBoarding/progress_bar/total.png',
                ),
              ),
              Positioned(
                top: 70,
                left: 50,
                child: Image.asset(
                  'assets/onBoarding/progress_bar/$progress.png',
                ),
              ),
              Positioned(
                top: 66,
                right: 45,
                child: Text('$progress%',
                    style: TextStyle(fontSize: 12, color: Colors.black)),
              ),
            ]),
            Bubble(
              padding: BubbleEdges.all(15),
              elevation: 5,
              color: Colors.white,
              margin: BubbleEdges.fromLTRB(10, 0, 20, 10),
              // nip: BubbleNip.leftTop,
              child: Text(
                "J’ai généré votre phrase de restauration !\nTâchez de la garder bien secrète, car elle permet à quiconque la connaît d’accéder à tous vos portefeuilles.",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
              ),
            ),
            SizedBox(height: 10),
            // ImageFiltered(
            //   imageFilter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
            //   child:
            sentanceArray(context),
            // ),
            Expanded(
                child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: 350,
                      height: 55,
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 5,
                            primary: Color(0xffD28928),
                            onPrimary: Colors.white, // foreground
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              SmoothTransition(page: OnboardingStepNine()),
                            );
                          },
                          child: Text("Afficher ma phrase",
                              style: TextStyle(fontSize: 20))),
                    ))),
            SizedBox(height: 80),
          ]),
        ));
  }
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

Widget sentanceArray(BuildContext context) {
  return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Container(
          decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              color: Colors.grey[300],
              borderRadius: BorderRadius.all(
                const Radius.circular(10),
              )),
          // color: Colors.grey[300],
          padding: EdgeInsets.all(20),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Row(children: <Widget>[
                  arrayCell("1:exquis"),
                  arrayCell("2:favori"),
                  arrayCell("3:curseur"),
                  arrayCell("4:relatif"),
                ]),
                SizedBox(height: 15),
                Row(children: <Widget>[
                  arrayCell("5:embellir"),
                  arrayCell("6:cultiver"),
                  arrayCell("7:bureau"),
                  arrayCell("8:ossature"),
                ]),
                SizedBox(height: 15),
                Row(children: <Widget>[
                  arrayCell("9:labial"),
                  arrayCell("10:science"),
                  arrayCell("11:théorie"),
                  arrayCell("12:Monnaie"),
                ]),
              ])));
}

Widget arrayCell(dataWord) {
  return Container(
      width: 80,
      child: Column(
        children: <Widget>[
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
            child: Text(dataWord.split(':')[0],
                style: TextStyle(fontSize: 12, color: Colors.black)),
          ),
          SizedBox(height: 2),
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Text(dataWord.split(':')[1],
                style: TextStyle(fontSize: 16, color: Colors.black)),
          )
        ],
      ));
}
