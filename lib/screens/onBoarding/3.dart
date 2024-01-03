// ignore_for_file: file_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/onBoarding/4.dart';
import 'package:gecko/widgets/commons/intro_info.dart';
import 'package:gecko/widgets/commons/offline_info.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';

class OnboardingStepThree extends StatelessWidget {
  const OnboardingStepThree({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: GeckoAppBar('yourMnemonic'.tr()),
      body: SafeArea(
        child: Stack(children: [
          InfoIntro(
            text: 'warningForgotPassword'.tr(),
            assetName: 'forgot_password.png'.tr(),
            buttonText: '>',
            nextScreen: const OnboardingStepFor(),
            pagePosition: 2,
            boxHeight: 316,
          ),
          const OfflineInfo(),
        ]),
      ),
    );
  }
}
