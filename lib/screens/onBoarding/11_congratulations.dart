// ignore_for_file: file_names

import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/widgets/commons/build_text.dart';

class OnboardingStepEleven extends StatelessWidget {
  const OnboardingStepEleven({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final conffetiController =
        ConfettiController(duration: const Duration(milliseconds: 500));
    conffetiController.play();
    return WillPopScope(
      onWillPop: () {
        return Future<bool>.value(false);
      },
      child: Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            toolbarHeight: 60 * ratio,
            leading: const Icon(Icons.check),
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
            child: Stack(children: [
              Column(children: <Widget>[
                const SizedBox(height: 40),
                BuildText(
                    text: "yourChestAndWalletWereCreatedSuccessfully".tr()),
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
              Align(
                alignment: Alignment.topLeft,
                child: ConfettiWidget(
                  confettiController: conffetiController,
                  blastDirection: pi * 0.1,
                  maxBlastForce: 10,
                  minBlastForce: 1,
                  emissionFrequency: 0.01,
                  numberOfParticles: 7,
                  shouldLoop: false,
                  gravity: 0.2,
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: ConfettiWidget(
                  confettiController: conffetiController,
                  blastDirection: pi * 0.9,
                  maxBlastForce: 10,
                  minBlastForce: 1,
                  emissionFrequency: 0.01,
                  numberOfParticles: 7,
                  shouldLoop: false,
                  gravity: 0.2,
                ),
              ),
            ]),
          )),
    );
  }
}

Widget finishButton(BuildContext context) {
  return SizedBox(
    width: 380 * ratio,
    height: 60 * ratio,
    child: ElevatedButton(
        key: keyGoWalletsHome,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, elevation: 4,
          backgroundColor: orangeC, // foreground
        ),
        onPressed: () {
          Navigator.pushNamedAndRemoveUntil(
              context, '/mywallets', ModalRoute.withName('/'));
        },
        child: Text("accessMyChest".tr(),
            style:
                TextStyle(fontSize: 22 * ratio, fontWeight: FontWeight.w600))),
  );
}
