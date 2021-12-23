// ignore_for_file: file_names

import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/onBoarding/7.dart';

// ignore: must_be_immutable
class OnboardingStepEight extends StatelessWidget {
  TextEditingController tplController = TextEditingController();
  final int progress = 6;

  OnboardingStepEight({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    CommonElements common = CommonElements();

    return Scaffold(
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: Column(children: <Widget>[
            common.onboardingProgressBar(
                context, 'Ma phrase de restauration', progress),
            common.bubbleSpeak(
              "J’ai généré votre phrase de restauration !\nTâchez de la garder bien secrète, car elle permet à quiconque la connaît d’accéder à tous vos portefeuilles.",
              textKey: const Key('step6'),
            ),
            SizedBox(height: isTall ? 61 : 31),
            // SizedBox(height: 30),
            sentanceArray(context),
            // ),
            Expanded(
                child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: 400,
                      height: 62,
                      child: ElevatedButton(
                          key: const Key('goStep7'),
                          style: ElevatedButton.styleFrom(
                            elevation: 5,
                            primary: orangeC,
                            onPrimary: Colors.white, // foreground
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              FaderTransition(
                                  page: OnboardingStepNine(), isFast: false),
                            );
                          },
                          child: const Text("Afficher ma phrase",
                              style: TextStyle(fontSize: 20))),
                    ))),
            const SizedBox(height: 80),
          ]),
        ));
  }
}

Widget sentanceArray(BuildContext context) {
  return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
          decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              color: Colors.grey[300],
              borderRadius: const BorderRadius.all(
                Radius.circular(10),
              )),
          // color: Colors.grey[300],
          padding: const EdgeInsets.all(20),
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
                const SizedBox(height: 15),
                Row(children: <Widget>[
                  arrayCell("5:embellir"),
                  arrayCell("6:cultiver"),
                  arrayCell("7:bureau"),
                  arrayCell("8:ossature"),
                ]),
                const SizedBox(height: 15),
                Row(children: <Widget>[
                  arrayCell("9:labial"),
                  arrayCell("10:science"),
                  arrayCell("11:théorie"),
                  arrayCell("12:Monnaie"),
                ]),
              ])));
}

Widget arrayCell(dataWord) {
  return SizedBox(
      width: 102,
      child: Column(
        children: <Widget>[
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
            child: Text(dataWord.split(':')[0],
                style: const TextStyle(fontSize: 14, color: Colors.black)),
          ),
          const SizedBox(height: 2),
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Text(dataWord.split(':')[1],
                style: const TextStyle(fontSize: 20, color: Colors.black)),
          )
        ],
      ));
}
