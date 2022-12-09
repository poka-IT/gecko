// ignore_for_file: file_names
import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/onBoarding/9.dart';

class OnboardingStepEight extends ConsumerWidget {
  const OnboardingStepEight({Key? key, this.scanDerivation = false})
      : super(key: key);
  final bool scanDerivation;

  @override
  Widget build(BuildContext context) {
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
        child: Stack(children: [
          common.infoIntro(
              context,
              'thisPasswordProtectsYourWalletsInASecureChest'.tr(),
              'coffre-fort-protege-les-portefeuilles.png',
              '>',
              OnboardingStepNine(scanDerivation: scanDerivation),
              7,
              isMd: true),
          CommonElements().offlineInfo(context),
        ]),
      ),
    );
  }
}
