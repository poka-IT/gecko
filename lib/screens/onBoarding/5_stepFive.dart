import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/commonElements.dart';
import 'package:gecko/screens/onBoarding/7_stepSeven.dart';

// ignore: must_be_immutable
class OnboardingStepFive extends StatelessWidget {
  TextEditingController tplController = TextEditingController();
  final int progress = 25;

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
              "Par contre, attention :\n\nDans une blockchain, il n’y a pas de procédure de récupération de trousseau.\n\nSi vous perdez votre phrase de restauration, je ne pourrai pas vous la communiquer, et vous ne pourrez donc plus jamais accéder à votre compte.",
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
                          child: Text("J'ai compris",
                              style: TextStyle(fontSize: 20))),
                    ))),
            SizedBox(height: 80),
          ]),
        ));
  }
}
