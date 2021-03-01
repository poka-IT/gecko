import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/screens/commonElements.dart';
import 'package:gecko/screens/onBoarding/7_stepSeven.dart';

// ignore: must_be_immutable
class OnboardingStepSix extends StatelessWidget {
  TextEditingController tplController = TextEditingController();
  final int progress = 28;

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
              "Je vais générer votre phrase de restauration ansi que votre trousseau de clef.\n\nC’est moi qui vais décider des mots de votre phrase, parce que sans ça les gens choisissent des choses trop faciles à deviner.",
            ),
            SizedBox(height: 10),
            Image.asset(
              'assets/onBoarding/good-bad-passphrase.png',
              height: 300,
            ),
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
                              SmoothTransition(page: OnboardingStepSeven()),
                            );
                          },
                          child: Text("Je comprends",
                              style: TextStyle(fontSize: 20))),
                    ))),
            SizedBox(height: 80),
          ]),
        ));
  }
}
