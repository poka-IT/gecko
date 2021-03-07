import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/commonElements.dart';
import 'package:gecko/screens/onBoarding/12_stepTwelve.dart';

// ignore: must_be_immutable
class OnboardingStepEleven extends StatelessWidget {
  TextEditingController tplController = TextEditingController();
  final int progress = 67;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    CommonElements common = CommonElements();

    return Scaffold(
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: Column(children: <Widget>[
            common.onboardingProgressBar('Ma phrase de restauration', progress),
            common.bubbleSpeakRich(<TextSpan>[
              TextSpan(text: "Super !\n\nJe vais maintenant créer votre "),
              TextSpan(
                  text: 'code secret.',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(
                  text:
                      " \n\nVotre code secret chiffre votre trousseau de clefs, ce qui le rend inutilisable par d’autres, par exemple si vous perdez votre téléphone ou si on vous le vole."),
            ]),
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
                          style: ElevatedButton.styleFrom(
                            elevation: 5,
                            primary: Color(0xffD28928),
                            onPrimary: Colors.white, // foreground
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              SmoothTransition(page: OnboardingStepTwelve()),
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
