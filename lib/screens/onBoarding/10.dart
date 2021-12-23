// ignore_for_file: file_names

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/onBoarding/11.dart';

// ignore: must_be_immutable
class OnboardingStepTwelve extends StatelessWidget {
  TextEditingController tplController = TextEditingController();
  final int progress = 9;

  OnboardingStepTwelve({Key? key}) : super(key: key);

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
              "Si un jour vous changez de téléphone, votre code secret sera différent, mais il vous suffira de me redonner votre phrase de restauration pour recréer votre trousseau.",
              textKey: const Key('step10'),
            ),
            const SizedBox(height: 10),
            Image.asset(
              'assets/onBoarding/plusieurs-codes-secrets-un-trousseau.png',
              height: isTall ? 410 : 380,
            ),
            Expanded(
                child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: 400,
                      height: 62,
                      child: ElevatedButton(
                          key: const Key('goStep11'),
                          style: ElevatedButton.styleFrom(
                            elevation: 5,
                            primary: orangeC,
                            onPrimary: Colors.white, // foreground
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              FaderTransition(
                                  page: const OnboardingStepThirteen(),
                                  isFast: true),
                            );
                          },
                          child: const Text("Générer le code secret",
                              style: TextStyle(fontSize: 20))),
                    ))),
            const SizedBox(height: 80),
          ]),
        ));
  }
}
