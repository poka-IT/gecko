// ignore_for_file: file_names
import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/onBoarding/2.dart';

class OnboardingStepOne extends StatelessWidget {
  const OnboardingStepOne({Key? key}) : super(key: key);

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
            'newWallet'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Stack(children: [
          common.infoIntro(
            context,
            'geckoGenerateYourWalletFromMnemonic'.tr(),
            'fabrication-de-portefeuille.png',
            '>',
            const OnboardingStepTwo(),
            0,
            isMd: true,
          ),
          CommonElements().offlineInfo(context),
        ]),
      ),
    );
  }
}
