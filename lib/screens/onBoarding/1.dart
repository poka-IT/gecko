// ignore_for_file: file_names
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/commons/intro_info.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';

class OnboardingStepOne extends StatelessWidget {
  const OnboardingStepOne({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: GeckoAppBar('newWallet'.tr()),
      body: SafeArea(
        child: InfoIntro(
          text: 'geckoGenerateYourWalletFromMnemonic'.tr(),
          assetName: 'fabrication-de-portefeuille.png',
          buttonText: '>',
          nextScreen: RouteNames.onboardingStepTwo,
          pagePosition: 0,
          isMd: true,
        ),
      ),
    );
  }
}
