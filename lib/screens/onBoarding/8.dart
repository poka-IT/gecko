// ignore_for_file: file_names
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/onBoarding/9.dart';

class OnboardingStepEight extends StatelessWidget {
  const OnboardingStepEight({Key? key, this.scanDerivation = false})
      : super(key: key);
  final bool scanDerivation;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    CommonElements common = CommonElements();
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        toolbarHeight: 60 * ratio,
        title: SizedBox(
          height: 22,
          child: Text(
            'myPassword'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: common.infoIntro(
            context,
            'Ce code secret protège vos portefeuilles dans un coffre-fort **dont vous seul possédez le code**, de sorte que vos portefeuilles seront inutilisables par d’autres.',
            'coffre-fort-protege-les-portefeuilles.png',
            '>',
            OnboardingStepNine(scanDerivation: scanDerivation),
            7,
            isMd: true),
      ),
    );
  }
}
