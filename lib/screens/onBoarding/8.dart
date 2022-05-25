// ignore_for_file: file_names
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/onBoarding/9.dart';

class OnboardingStepEight extends StatelessWidget {
  const OnboardingStepEight({Key? key}) : super(key: key);

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
                      'Ce code secret protège vos portefeuilles dans un coffre-fort '),
              const TextSpan(
                  text: 'dont vous seul possédez le code',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(
                  text:
                      ', de sorte que vos portefeuilles seront inutilisables par d’autres.'),
            ],
            'coffre-fort-protege-les-portefeuilles.png',
            '>',
            const OnboardingStepNine(),
            7),
      ),
    );
  }
}
