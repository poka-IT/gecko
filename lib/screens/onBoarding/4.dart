// ignore_for_file: file_names

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/onBoarding/5.dart';

class OnboardingStepFor extends StatelessWidget {
  const OnboardingStepFor({Key? key}) : super(key: key);

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
            'Votre phrase de restauration',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: common.infoIntro(context, '', 'gecko-oublie-aussi.png', '>',
            const OnboardingStepFive(), 3,
            textMd:
                'Il est temps de vous munir d’**un papier et d’un crayon** afin de pouvoir noter votre phrase de restauration.'),
      ),
    );
  }
}
