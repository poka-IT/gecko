// ignore_for_file: file_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/onBoarding/5.dart';
import 'package:gecko/widgets/commons/intro_info.dart';
import 'package:gecko/widgets/commons/offline_info.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';

class OnboardingStepFor extends StatelessWidget {
  const OnboardingStepFor({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: GeckoAppBar('yourMnemonic'.tr()),
      body: SafeArea(
        child: Stack(children: [
          SingleChildScrollView(
            child: InfoIntro(
                text: 'itsTimeToUseAPenAndPaper'.tr(),
                assetName: 'gecko_also_can_forget.png'.tr(),
                buttonText: '>',
                nextScreen: const OnboardingStepFive(),
                pagePosition: 3,
                isMd: true),
          ),
          const OfflineInfo(),
        ]),
      ),
    );
  }
}
