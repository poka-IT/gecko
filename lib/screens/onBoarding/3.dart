// ignore_for_file: file_names

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/onBoarding/4.dart';

class OnboardingStepThree extends StatelessWidget {
  const OnboardingStepThree({Key? key}) : super(key: key);

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
                      'Dans une blockchain, pas de procédure de récupération par mail. Seule votre phrase de restauration peut vous permettre de récupérer vos Ğ1 à tout moment.'),
            ],
            'mot-de-passe-oublie.png',
            '>',
            const OnboardingStepFor(),
            2),
      ),
    );
  }
}
