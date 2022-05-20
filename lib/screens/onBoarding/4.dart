// ignore_for_file: file_names

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/onBoarding/5.dart';

// ignore: must_be_immutable
class OnboardingStepFive extends StatelessWidget {
  TextEditingController tplController = TextEditingController();
  final int progress = 4;

  OnboardingStepFive({Key? key}) : super(key: key);

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
              "Par contre, attention :\n\nDans une blockchain, il n’y a pas de procédure de récupération de coffre.\n\nSi vous perdez votre phrase de restauration, je ne pourrai pas vous la communiquer, et vous ne pourrez donc plus jamais accéder à votre compte.",
              textKey: const Key('step4'),
            ),
            SizedBox(height: isTall ? 30 : 10),
            Image.asset(
              'assets/onBoarding/maison-qui-brule.png',
              width: 320 * ratio,
            ),
            Expanded(
                child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: 400,
                      height: 62,
                      child: ElevatedButton(
                          key: const Key('goStep5'),
                          style: ElevatedButton.styleFrom(
                            elevation: 5,
                            primary: orangeC,
                            onPrimary: Colors.white, // foreground
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              FaderTransition(
                                  page: OnboardingStepSeven(), isFast: true),
                            );
                          },
                          child: const Text("J'ai compris",
                              style: TextStyle(fontSize: 20))),
                    ))),
            const SizedBox(height: 80),
          ]),
        ));
  }
}
