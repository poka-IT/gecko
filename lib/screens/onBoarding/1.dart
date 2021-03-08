import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/screens/commonElements.dart';
import 'package:gecko/screens/onBoarding/2.dart';
// import 'package:gecko/models/home.dart';
// import 'package:provider/provider.dart';

// ignore: must_be_immutable
class OnboardingStepOne extends StatelessWidget {
  TextEditingController tplController = TextEditingController();
  final int progress = 1;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    CommonElements common = CommonElements();

    return Scaffold(
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: Column(children: <Widget>[
            common.onboardingProgressBar(context, 'Nouveau portefeuilles', progress),
            common.bubbleSpeak(
              "Il semblerait que vous n’ayez pas encore de trousseau.\n\nUn trousseau vous permet de gérer un ou plusieurs portefeuilles.",
            ),
            SizedBox(height: 90),
            Image.asset(
              'assets/onBoarding/keys-and-wallets-horizontal.png',
              height: 200,
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
                            Navigator.push(context,
                                FaderTransition(page: OnboardingStepTwo(), isFast: true));
                          },
                          child: Text('Créer mon trousseau',
                              style: TextStyle(fontSize: 20))),
                    ))),
            SizedBox(height: 80),
          ]),
        ));
  }
}
