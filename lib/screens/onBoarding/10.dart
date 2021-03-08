import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/commonElements.dart';
import 'package:gecko/screens/onBoarding/11.dart';

// ignore: must_be_immutable
class OnboardingStepTwelve extends StatelessWidget {
  TextEditingController tplController = TextEditingController();
  final int progress = 9;

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
                "Si un jour vous changez de téléphone, votre code secret sera différent, mais il vous suffira de me redonner votre phrase de restauration pour recréer votre trousseau."),
            SizedBox(height: 10),
            Image.asset(
              'assets/onBoarding/plusieurs-codes-secrets-un-trousseau.png',
              height: 410 * ratio,
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
                              FaderTransition(
                                  page: OnboardingStepThirteen(), isFast: true),
                            );
                          },
                          child: Text("Générer le code secret",
                              style: TextStyle(fontSize: 20))),
                    ))),
            SizedBox(height: isTall ? 80 : 40),
          ]),
        ));
  }
}
