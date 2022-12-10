// ignore_for_file: file_names

import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/onBoarding/5.dart';
import 'package:gecko/widgets/commons/intro_info.dart';
import 'package:gecko/widgets/commons/offline_info.dart';

class OnboardingStepFor extends StatelessWidget {
  const OnboardingStepFor({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        toolbarHeight: 60 * ratio,
        title: SizedBox(
          height: 22,
          child: Text(
            'yourMnemonic'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Stack(children: [
          InfoIntro(
              text: 'itsTimeToUseAPenAndPaper'.tr(),
              assetName: 'gecko_also_can_forget.png'.tr(),
              buttonText: '>',
              nextScreen: const OnboardingStepFive(),
              pagePosition: 3,
              isMd: true),
          const OfflineInfo(),
        ]),
      ),
    );
  }
}
