// ignore_for_file: file_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/commons/intro_info.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';

class OnboardingStepThree extends StatelessWidget {
  const OnboardingStepThree({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: GeckoAppBar('yourMnemonic'.tr()),
      body: SafeArea(
        child: SingleChildScrollView(
          child: InfoIntro(
            text: 'warningForgotPassword'.tr(),
            assetName: 'forgot_password.png'.tr(),
            buttonText: '>',
            nextScreen: RouteNames.onboardingStepFour,
            pagePosition: 2,
            boxHeight: 316,
          ),
        ),
      ),
    );
  }
}
