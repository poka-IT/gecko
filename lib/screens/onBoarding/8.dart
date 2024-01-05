// ignore_for_file: file_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/onBoarding/9.dart';
import 'package:gecko/widgets/commons/intro_info.dart';
import 'package:gecko/widgets/commons/offline_info.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';

class OnboardingStepEight extends StatelessWidget {
  const OnboardingStepEight({Key? key, this.scanDerivation = false})
      : super(key: key);
  final bool scanDerivation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: GeckoAppBar('myPassword'.tr()),
      body: SafeArea(
        child: Stack(children: [
          InfoIntro(
              text: 'thisPasswordProtectsYourWalletsInASecureChest'.tr(),
              assetName: 'coffre-fort-protege-les-portefeuilles.png',
              buttonText: '>',
              nextScreen: OnboardingStepNine(scanDerivation: scanDerivation),
              pagePosition: 7,
              isMd: true,
              boxHeight: 320),
          const OfflineInfo(),
        ]),
      ),
    );
  }
}
