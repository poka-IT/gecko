// ignore_for_file: file_names

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/common_elements.dart';

// ignore: must_be_immutable
class OnboardingStepFiveteen extends StatelessWidget {
  TextEditingController tplController = TextEditingController();
  final int progress = 12;

  OnboardingStepFiveteen({Key key}) : super(key: key);

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
              "Top !\n\nVotre trousseau de clef et votre portefeuille ont été créés avec un immense succès.\n\nFélicitations !",
              textKey: const Key('step13'),
            ),
            SizedBox(height: isTall ? 20 : 10),
            Image.asset(
              'assets/onBoarding/gecko-clin.gif',
              height: isTall ? 400 : 300,
            ),
            Expanded(
                child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: 400,
                      height: 62,
                      child: ElevatedButton(
                          key: const Key('goWalletHome'),
                          style: ElevatedButton.styleFrom(
                            elevation: 5,
                            primary: orangeC,
                            onPrimary: Colors.white, // foreground
                          ),
                          onPressed: () {
                            Navigator.popUntil(
                              context,
                              ModalRoute.withName('/'),
                            );
                            Navigator.pushNamed(
                              context,
                              '/mywallets',
                            );
                          },
                          child: const Text("Accéder à mes portefeuilles",
                              style: TextStyle(fontSize: 20))),
                    ))),
            const SizedBox(height: 80),
          ]),
        ));
  }
}
