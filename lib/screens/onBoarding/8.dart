// ignore_for_file: file_names
import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/onBoarding/9.dart';
import 'package:gecko/widgets/commons/intro_info.dart';
import 'package:gecko/widgets/commons/offline_info.dart';

class OnboardingStepEight extends StatelessWidget {
  const OnboardingStepEight({Key? key, this.scanDerivation = false})
      : super(key: key);
  final bool scanDerivation;

  @override
  Widget build(BuildContext context) {
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
        child: Stack(children: [
          InfoIntro(
              text: 'thisPasswordProtectsYourWalletsInASecureChest'.tr(),
              assetName: 'coffre-fort-protege-les-portefeuilles.png',
              buttonText: '>',
              nextScreen: OnboardingStepNine(scanDerivation: scanDerivation),
              pagePosition: 7,
              isMd: true),
          const OfflineInfo(),
        ]),
      ),
    );
  }
}
