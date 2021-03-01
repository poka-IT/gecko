import 'dart:ui';
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
    CommonElements common = CommonElements();

    return Scaffold(
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: Column(children: <Widget>[
            common.onboardingProgressBar('Ma phrase de restauration', progress),
            common.bubbleSpeak(
              "J’ai généré votre phrase de restauration !\nTâchez de la garder bien secrète, car elle permet à quiconque la connaît d’accéder à tous vos portefeuilles.",
            ),
            SizedBox(height: 30),
            sentanceArray(context),
            // ),
            Expanded(
                child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: 400,
                      height: 62,
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
      width: 102,
      child: Column(
        children: <Widget>[
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
            child: Text(dataWord.split(':')[0],
                style: TextStyle(fontSize: 14, color: Colors.black)),
          ),
          SizedBox(height: 2),
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Text(dataWord.split(':')[1],
                style: TextStyle(fontSize: 20, color: Colors.black)),
          )
        ],
      ));
}
