// ignore_for_file: file_names

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/onBoarding/4.dart';

// ignore: must_be_immutable
class OnboardingStepFor extends StatelessWidget {
  TextEditingController tplController = TextEditingController();
  final int progress = 3;

  OnboardingStepFor({Key? key}) : super(key: key);

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
              "Si un jour vous changez de téléphone, il vous suffira de me redonner votre phrase de restauration pour recréer votre coffre.",
              textKey: const Key('step3'),
            ),
            SizedBox(height: isTall ? 15 : 0),
            // Row(children: <Widget>[
            // Align(
            //     alignment: Alignment.centerRight,
            //     child:
            Image.asset(
              'assets/onBoarding/plusieurs-appareils-un-trousseau.png',
              height: 400 * ratio,
            ),
            // ]),
            Expanded(
                child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: 400,
                      height: 62,
                      child: ElevatedButton(
                          key: const Key('goStep4'),
                          style: ElevatedButton.styleFrom(
                            elevation: 5,
                            primary: orangeC,
                            onPrimary: Colors.white, // foreground
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              FaderTransition(
                                  page: OnboardingStepFive(), isFast: true),
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
