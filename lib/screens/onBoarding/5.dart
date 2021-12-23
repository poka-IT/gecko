// ignore_for_file: file_names

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/onBoarding/6.dart';

// ignore: must_be_immutable
class OnboardingStepSeven extends StatelessWidget {
  TextEditingController tplController = TextEditingController();
  final int progress = 5;

  OnboardingStepSeven({Key? key}) : super(key: key);

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
            common.bubbleSpeakRich(
              <TextSpan>[
                const TextSpan(text: "Munissez-vous d'"),
                const TextSpan(
                    text: 'un papier et d’un crayon\n',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const TextSpan(
                    text:
                        "afin de pouvoir noter votre phrase de restauration."),
              ],
              textKey: const Key('step5'),
            ),
            Expanded(
                child: Align(
              alignment: Alignment.bottomCenter,
              child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                Container(
                  padding: const EdgeInsets.only(bottom: 90),
                  child: common.bubbleSpeak(
                      "Moi, j’ai déjà essayé de\nmémoriser une phrase de\nrestauration, mais je n’ai\npas une mémoire\nd’éléphant.",
                      isMaxWidth: false),
                ),
                Image.asset(
                  'assets/onBoarding/chopp-gecko.png',
                  height: 200,
                ),
              ]),
            )),
            SizedBox(height: isTall ? 120 : 50),
            SizedBox(
              width: 400,
              height: 62,
              child: ElevatedButton(
                  key: const Key('goStep6'),
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    primary: orangeC,
                    onPrimary: Colors.white, // foreground
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      FaderTransition(
                          page: OnboardingStepEight(), isFast: true),
                    );
                  },
                  child: const Text("J'ai de quoi noter",
                      style: TextStyle(fontSize: 20))),
            ),
            const SizedBox(height: 80),
          ]),
        ));
  }
}
