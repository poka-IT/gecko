// ignore_for_file: file_names

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/onBoarding/3.dart';

class OnboardingStepTwo extends StatelessWidget {
  const OnboardingStepTwo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    CommonElements common = CommonElements();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60 * ratio,
        title: const SizedBox(
          height: 22,
          child: Text(
            'Votre phrase de restauration',
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
                  text:
                      'Conservez cette phrase précieusement, car sans elle Gecko ne pourra pas reconstruire vos portefeuilles le jour où vous changez de téléphone.'),
            ],
            'fabrication-de-portefeuille-impossible-sans-phrase.png',
            '>',
            const OnboardingStepThree(),
            1),
      ),
    );
  }
}
