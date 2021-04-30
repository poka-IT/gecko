import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/screens/commonElements.dart';
import 'package:gecko/screens/onBoarding/3.dart';
// import 'package:gecko/screens/commonElements.dart';
// import 'package:gecko/models/home.dart';
// import 'package:provider/provider.dart';

// ignore: must_be_immutable
class OnboardingStepTwo extends StatelessWidget {
  TextEditingController tplController = TextEditingController();
  final int progress = 2;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    CommonElements common = CommonElements();

    return Scaffold(
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: Column(children: <Widget>[
            common.onboardingProgressBar(
                context, 'Nouveau portefeuilles', progress),
            common.bubbleSpeak(
              "Un trousseau est créé à partir d’une phrase de restauration.",
              textKey: Key('step2'),
            ),
            SizedBox(height: 70),
            Image.asset(
                'assets/onBoarding/keys-and-wallets-horizontal-plus-phrase.png'),
            Expanded(
                child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: 400,
                      height: 62,
                      child: ElevatedButton(
                        key: Key('goStep3'),
                        style: ElevatedButton.styleFrom(
                          elevation: 5,
                          primary: Color(0xffD28928),
                          onPrimary: Colors.white, // foreground
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            FaderTransition(
                                page: OnboardingStepFor(), isFast: true),
                          );
                        },
                        child: Text("D'accord", style: TextStyle(fontSize: 20)),
                      ),
                    ))),
            SizedBox(height: 80),
          ]),
        ));
  }
}
