// ignore_for_file: file_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/onBoarding/8.dart';
import 'package:gecko/widgets/commons/intro_info.dart';
import 'package:gecko/widgets/commons/offline_info.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';

class OnboardingStepSeven extends StatelessWidget {
  const OnboardingStepSeven({super.key, this.scanDerivation = false, this.fromRestore = false});
  final bool scanDerivation;
  final bool fromRestore;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: GeckoAppBar('myPassword'.tr()),
      body: SafeArea(
        child: Stack(children: [
          SingleChildScrollView(
            child: InfoIntro(
                text: 'geckoWillGenerateAPassword'.tr(),
                assetName: 'coffre-fort-code-secret-dans-telephone.png',
                buttonText: '>',
                nextScreen: OnboardingStepEight(scanDerivation: scanDerivation, fromRestore: fromRestore),
                pagePosition: 6,
                boxHeight: 320),
          ),
          const OfflineInfo(),
        ]),
      ),
    );
  }
}
