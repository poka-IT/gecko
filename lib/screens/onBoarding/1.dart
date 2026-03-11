// ignore_for_file: file_names
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/commons/intro_info.dart';
import 'package:gecko/widgets/commons/responsive_center.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';

class OnboardingStepOne extends StatelessWidget {
  const OnboardingStepOne({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as OnboardingStepOneArguments?;

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: GeckoAppBar('newWallet'.tr()),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 500,
          padding: EdgeInsets.zero,
          child: InfoIntro(
            text: 'geckoGenerateYourWalletFromMnemonic'.tr(),
            assetName: 'fabrication-de-portefeuille.png',
            buttonText: '>',
            nextScreen: RouteNames.onboardingStepTwo,
            routeArguments: args?.legacyMigrationData != null
                ? OnboardingStepTwoArguments(legacyMigrationData: args!.legacyMigrationData!)
                : null,
            pagePosition: 0,
            isMd: true,
          ),
        ),
      ),
    );
  }
}
