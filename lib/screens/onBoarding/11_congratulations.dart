// ignore_for_file: file_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/myWallets/wallets_home.dart';

// ignore: must_be_immutable
class OnboardingStepEleven extends StatelessWidget {
  const OnboardingStepEleven({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    CommonElements common = CommonElements();

    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          toolbarHeight: 60 * ratio,
          title: SizedBox(
            height: 22,
            child: Text(
              'allGood'.tr(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: Column(children: <Widget>[
            const SizedBox(height: 40),
            common.buildText("yourChestAndWalletWereCreatedSuccessfully".tr()),
            SizedBox(height: isTall ? 20 : 10),
            Image.asset(
              'assets/onBoarding/gecko-clin.gif',
              height: isTall ? 400 : 300,
            ),
            Expanded(
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: finishButton(context)),
            ),
            const SizedBox(height: 40),
          ]),
        ));
  }
}

Widget finishButton(BuildContext context) {
  return SizedBox(
    width: 380 * ratio,
    height: 60 * ratio,
    child: ElevatedButton(
        key: const Key('goWalletHome'),
        style: ElevatedButton.styleFrom(
          elevation: 4,
          primary: orangeC,
          onPrimary: Colors.white, // foreground
        ),
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) {
              return const WalletsHome();
            }),
            ModalRoute.withName('/'),
          );
        },
        child: Text("accessMyChest".tr(),
            style:
                TextStyle(fontSize: 22 * ratio, fontWeight: FontWeight.w600))),
  );
}
