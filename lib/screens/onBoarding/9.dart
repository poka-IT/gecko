// ignore_for_file: file_names
import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/generate_wallets.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/onBoarding/10.dart';
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
    CommonElements common = CommonElements();

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
              common.buildProgressBar(8),
              SizedBox(height: isTall ? 40 : 20),
              common.buildText("hereIsThePasswordKeepIt".tr(), 20, true),
              const SizedBox(height: 100),
              Stack(
                alignment: Alignment.centerRight,
                children: <Widget>[
                  TextField(
                      key: keyGeneratedPin,
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
              common.nextButton(context, "iNotedMyPassword".tr(),
                  OnboardingStepTen(scanDerivation: scanDerivation), false),
              SizedBox(height: 35 * ratio),
            ]),
            CommonElements().offlineInfo(context),
          ]),
        ));
  }
}
