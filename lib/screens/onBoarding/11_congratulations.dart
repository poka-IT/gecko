// ignore_for_file: file_names

import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/widgets/commons/build_text.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';

class OnboardingStepEleven extends StatelessWidget {
  const OnboardingStepEleven({super.key});

  @override
  Widget build(BuildContext context) {
    final conffetiController = ConfettiController(duration: const Duration(milliseconds: 500));
    conffetiController.play();
    return PopScope(
      canPop: false,
      child: Scaffold(
          backgroundColor: backgroundColor,
          appBar: GeckoAppBar('allGood'.tr()),
          body: SafeArea(
            child: Stack(children: [
              Column(children: <Widget>[
                ScaledSizedBox(height: isTall ? 25 : 5),
                BuildText(text: "yourChestAndWalletWereCreatedSuccessfully".tr()),
                ScaledSizedBox(height: isTall ? 15 : 5),
                Image.asset(
                  'assets/onBoarding/gecko-clin.gif',
                  height: scaleSize(isTall ? 330 : 280),
                ),
                Expanded(
                  child: Align(alignment: Alignment.bottomCenter, child: finishButton(context)),
                ),
                ScaledSizedBox(height: isTall ? 40 : 5),
              ]),
              Align(
                alignment: Alignment.topLeft,
                child: ConfettiWidget(
                  confettiController: conffetiController,
                  blastDirection: pi * 0.15,
                  maxBlastForce: 15,
                  minBlastForce: 3,
                  emissionFrequency: 0.04,
                  numberOfParticles: 8,
                  shouldLoop: true,
                  gravity: 0.15,
                  particleDrag: 0.1,
                  minimumSize: const Size(8, 8),
                  maximumSize: const Size(12, 12),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: ConfettiWidget(
                  confettiController: conffetiController,
                  blastDirection: pi * 0.85,
                  maxBlastForce: 15,
                  minBlastForce: 3,
                  emissionFrequency: 0.04,
                  numberOfParticles: 8,
                  shouldLoop: true,
                  gravity: 0.15,
                  particleDrag: 0.1,
                  minimumSize: const Size(8, 8),
                  maximumSize: const Size(12, 12),
                ),
              ),
              Align(
                alignment: const Alignment(-0.3, -0.2),
                child: ConfettiWidget(
                  confettiController: conffetiController,
                  blastDirection: pi * 0.3,
                  maxBlastForce: 15,
                  minBlastForce: 3,
                  emissionFrequency: 0.04,
                  numberOfParticles: 6,
                  shouldLoop: true,
                  gravity: 0.15,
                  particleDrag: 0.1,
                  minimumSize: const Size(8, 8),
                  maximumSize: const Size(12, 12),
                ),
              ),
              Align(
                alignment: const Alignment(0.3, -0.2),
                child: ConfettiWidget(
                  confettiController: conffetiController,
                  blastDirection: pi * 0.7,
                  maxBlastForce: 15,
                  minBlastForce: 3,
                  emissionFrequency: 0.04,
                  numberOfParticles: 6,
                  shouldLoop: true,
                  gravity: 0.15,
                  particleDrag: 0.1,
                  minimumSize: const Size(8, 8),
                  maximumSize: const Size(12, 12),
                ),
              ),
            ]),
          )),
    );
  }
}

Widget finishButton(BuildContext context) {
  return ScaledSizedBox(
    width: 340,
    height: 55,
    child: ElevatedButton(
      key: keyGoWalletsHome,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: orangeC,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: orangeC.withValues(alpha: 0.3),
      ),
      onPressed: () {
        Navigator.pushNamedAndRemoveUntil(context, '/mywallets', ModalRoute.withName('/'));
      },
      child: Text(
        "accessMyChest".tr(),
        style: scaledTextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    ),
  );
}
