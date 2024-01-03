// ignore_for_file: file_names
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/onBoarding/2.dart';
import 'package:gecko/widgets/commons/intro_info.dart';
import 'package:gecko/widgets/commons/offline_info.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';

class OnboardingStepOne extends StatelessWidget {
  const OnboardingStepOne({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: GeckoAppBar('newWallet'.tr()),
      body: SafeArea(
        child: Stack(children: [
          InfoIntro(
            text: 'geckoGenerateYourWalletFromMnemonic'.tr(),
            assetName: 'fabrication-de-portefeuille.png',
            buttonText: '>',
            nextScreen: const OnboardingStepTwo(),
            pagePosition: 0,
            isMd: true,
          ),
          const OfflineInfo(),
        ]),
      ),
    );
  }
}
