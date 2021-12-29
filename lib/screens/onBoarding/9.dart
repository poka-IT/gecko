// ignore_for_file: file_names

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/onBoarding/10.dart';

// ignore: must_be_immutable
class OnboardingStepEleven extends StatelessWidget {
  TextEditingController tplController = TextEditingController();
  final int progress = 8;

  OnboardingStepEleven({Key? key}) : super(key: key);

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
                const TextSpan(
                    text: "Super !\n\nJe vais maintenant créer votre "),
                const TextSpan(
                    text: 'code secret.',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const TextSpan(
                    text:
                        " \n\nVotre code secret chiffre votre trousseau de clefs, ce qui le rend inutilisable par d’autres, par exemple si vous perdez votre téléphone ou si on vous le vole."),
              ],
              textKey: const Key('step9'),
            ),
            SizedBox(height: isTall ? 50 : 10),
            Image.asset(
              'assets/onBoarding/treasure-chest-gecko-souligne.png',
              height: 280 * ratio, //5": 400
            ),
            Expanded(
                child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: 400,
                      height: 62,
                      child: ElevatedButton(
                          key: const Key('goStep10'),
                          style: ElevatedButton.styleFrom(
                            elevation: 5,
                            primary: orangeC,
                            onPrimary: Colors.white, // foreground
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              FaderTransition(
                                  page: OnboardingStepTwelve(), isFast: true),
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
