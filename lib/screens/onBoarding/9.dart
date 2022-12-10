// ignore_for_file: file_names
import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/generate_wallets.dart';
import 'package:gecko/widgets/commons/build_progress_bar.dart';
import 'package:gecko/widgets/commons/build_text.dart';
import 'package:gecko/screens/onBoarding/10.dart';
import 'package:gecko/widgets/commons/next_button.dart';
import 'package:gecko/widgets/commons/offline_info.dart';
import 'package:provider/provider.dart';

class OnboardingStepNine extends StatelessWidget {
  const OnboardingStepNine({Key? key, this.scanDerivation = false})
      : super(key: key);
  final bool scanDerivation;

  @override
  Widget build(BuildContext context) {
    final generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context);
    // final myWalletProvider =
    //     Provider.of<MyWalletsProvider>(context);

    generateWalletProvider.pin.text = debugPin // kDebugMode &&
        ? 'AAAAA'
        : generateWalletProvider.changePinCode(reload: false).toUpperCase();

    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          toolbarHeight: 60 * ratio,
          title: SizedBox(
            height: 22,
            child: Text(
              'myPassword'.tr(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: Stack(children: [
            Column(children: <Widget>[
              SizedBox(height: isTall ? 40 : 20),
              const BuildProgressBar(pagePosition: 8),
              SizedBox(height: isTall ? 40 : 20),
              BuildText(text: "hereIsThePasswordKeepIt".tr()),
              const SizedBox(height: 100),
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
                      style: const TextStyle(
                          letterSpacing: 5,
                          fontSize: 35.0,
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
              const SizedBox(height: 30),
              Text(
                  'Pendant la phase de test de Ğecko,\nles codes secrets\nsont systématiquement AAAAA.'
                      .tr(),
                  style: TextStyle(color: Colors.grey[700], fontSize: 15),
                  textAlign: TextAlign.center),
              Expanded(
                  child: Align(
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        width: 380 * ratio,
                        height: 60 * ratio,
                        child: ElevatedButton(
                            key: keyChangePin,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.black,
                              elevation: 4,
                              backgroundColor:
                                  const Color(0xffFFD58D), // foreground
                            ),
                            onPressed: () {
                              generateWalletProvider.changePinCode(
                                  reload: true);
                            },
                            child: Text("chooseAnotherPassword".tr(),
                                style: TextStyle(
                                    fontSize: 22 * ratio,
                                    fontWeight: FontWeight.w600))),
                      ))),
              SizedBox(height: 22 * ratio),
              NextButton(
                  text: "iNotedMyPassword".tr(),
                  nextScreen: OnboardingStepTen(scanDerivation: scanDerivation),
                  isFast: false),
              SizedBox(height: 35 * ratio),
            ]),
            const OfflineInfo(),
          ]),
        ));
  }
}
