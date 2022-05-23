// ignore_for_file: file_names
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/onBoarding/8.dart';

class OnboardingStepSeven extends StatelessWidget {
  const OnboardingStepSeven({Key? key}) : super(key: key);

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
            'Mon code secret',
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
                      'Gecko va maintenant générer pour vous un code secret court qui vous permettra d’accéder rapidement à vos portefeuilles, sans avoir à taper votre phrase de restauration à chaque fois.'),
            ],
            'coffre-fort-code-secret-dans-telephone.png',
            '>',
            const OnboardingStepEight(),
            6,
            boxHeight: 400),
      ),
    );
  }
}
