// ignore_for_file: file_names
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/onBoarding/2.dart';

class OnboardingStepOne extends StatelessWidget {
  const OnboardingStepOne({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    CommonElements common = CommonElements();
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        toolbarHeight: 60 * ratio,
        title: const SizedBox(
          height: 22,
          child: Text(
            'Nouveau portefeuille',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: common.infoIntro(
            context,
            <TextSpan>[
              const TextSpan(
                  text: 'Gecko fabrique votre portefeuille à partir d’une '),
              const TextSpan(
                  text: 'phrase de restauration',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(
                  text:
                      '. Elle est un peu comme le plan qui permet de construire votre portefeuille.'),
            ],
            'fabrication-de-portefeuille.png',
            '>',
            const OnboardingStepTwo(),
            0),
      ),
    );
  }
}
