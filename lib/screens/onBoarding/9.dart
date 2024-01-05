// ignore_for_file: file_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/generate_wallets.dart';
import 'package:gecko/widgets/commons/build_progress_bar.dart';
import 'package:gecko/widgets/commons/build_text.dart';
import 'package:gecko/screens/onBoarding/10.dart';
import 'package:gecko/widgets/commons/next_button.dart';
import 'package:gecko/widgets/commons/offline_info.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:provider/provider.dart';

class OnboardingStepNine extends StatelessWidget {
  const OnboardingStepNine({Key? key, this.scanDerivation = false})
      : super(key: key);
  final bool scanDerivation;

  @override
  Widget build(BuildContext context) {
    final generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context);

    generateWalletProvider.pin.text = debugPin // kDebugMode &&
        ? 'AAAAA'
        : generateWalletProvider.changePinCode(reload: false).toUpperCase();

    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: GeckoAppBar('myPassword'.tr()),
        body: SafeArea(
          child: Stack(children: [
            Column(children: <Widget>[
              ScaledSizedBox(height: isTall ? 25 : 5),
              const BuildProgressBar(pagePosition: 8),
              ScaledSizedBox(height: isTall ? 25 : 5),
              BuildText(text: "hereIsThePasswordKeepIt".tr()),
              ScaledSizedBox(height: isTall ? 60 : 10),
              Stack(
                alignment: Alignment.centerRight,
                children: <Widget>[
                  TextField(
                      key: keyGeneratedPin,
                      textCapitalization: TextCapitalization.characters,
                      enabled: false,
                      controller: generateWalletProvider.pin,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(),
                      style: scaledTextStyle(
                          letterSpacing: 5,
                          fontSize: 33,
                          color: Colors.black,
                          fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.replay),
                    color: orangeC,
                    onPressed: () {
                      generateWalletProvider.changePinCode(reload: true);
                    },
                  ),
                ],
              ),
              ScaledSizedBox(height: isTall ? 30 : 15),
              Text(
                  'Pendant la phase de test de Ğecko,\nles codes secrets\nsont systématiquement AAAAA.'
                      .tr(),
                  style: scaledTextStyle(color: Colors.grey[700], fontSize: 14),
                  textAlign: TextAlign.center),
              Expanded(
                  child: Align(
                      alignment: Alignment.bottomCenter,
                      child: ScaledSizedBox(
                        width: 340,
                        height: 55,
                        child: ElevatedButton(
                            key: keyChangePin,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.black,
                              elevation: 4,
                              backgroundColor: const Color(0xffFFD58D),
                            ),
                            onPressed: () {
                              generateWalletProvider.changePinCode(
                                  reload: true);
                            },
                            child: Text("chooseAnotherPassword".tr(),
                                style: scaledTextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600))),
                      ))),
              ScaledSizedBox(height: 20),
              NextButton(
                  text: "iNotedMyPassword".tr(),
                  nextScreen: OnboardingStepTen(scanDerivation: scanDerivation),
                  isFast: false),
              ScaledSizedBox(height: 40),
            ]),
            const OfflineInfo(),
          ]),
        ));
  }
}
