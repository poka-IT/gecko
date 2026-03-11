// ignore_for_file: file_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/commons/intro_info.dart';
import 'package:gecko/widgets/commons/responsive_center.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';

class OnboardingStepTwo extends StatelessWidget {
  const OnboardingStepTwo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: GeckoAppBar('yourMnemonic'.tr()),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 500,
          padding: EdgeInsets.zero,
          child: InfoIntro(
            text: 'keepThisMnemonicSecure'.tr(),
            assetName: 'fabrication-de-portefeuille-impossible-sans-phrase.png',
            buttonText: '>',
            nextScreen: RouteNames.onboardingStepThree,
            pagePosition: 1,
          ),
        ),
      ),
    );
  }
}
