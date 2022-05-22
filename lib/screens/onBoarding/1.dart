// ignore_for_file: file_names

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/onBoarding/2.dart';
// import 'package:gecko/models/home.dart';
// import 'package:provider/provider.dart';

// ignore: must_be_immutable
class OnboardingStepOne extends StatelessWidget {
  TextEditingController tplController = TextEditingController();
  final int progress = 1;

  OnboardingStepOne({Key? key}) : super(key: key);

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
                "Il semblerait que vous n’ayez pas encore de coffre.\n\nUn coffre vous permet de gérer un ou plusieurs portefeuilles.",
                textKey: const Key('step1')),
            const SizedBox(height: 90),
            Image.asset(
              'assets/onBoarding/fabrication-de-portefeuille.png',
              height: 200,
            ),
            Expanded(
                child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: 400,
                      height: 62,
                      child: ElevatedButton(
                          key: const Key('goStep2'),
                          style: ElevatedButton.styleFrom(
                            elevation: 5,
                            primary: orangeC,
                            onPrimary: Colors.white, // foreground
                          ),
                          onPressed: () {
                            Navigator.push(
                                context,
                                FaderTransition(
                                    page: OnboardingStepTwo(), isFast: true));
                          },
                          child: const Text('Créer mon coffre',
                              style: TextStyle(fontSize: 20))),
                    ))),
            const SizedBox(height: 80),
          ]),
        ));
  }
}
