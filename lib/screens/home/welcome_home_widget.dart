import 'package:durt2/durt2.dart' show Durt;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/screens/home/test_wallet_button.dart';
import 'package:gecko/screens/myWallets/restore_safe.dart';
import 'package:gecko/screens/onBoarding/1.dart';
import 'package:gecko/widgets/bubble_speak.dart';
import 'package:gecko/widgets/buttons/home_settings_button.dart';

/// Welcome screen widget displayed when no wallets exist
class WelcomeHomeWidget extends StatelessWidget {
  const WelcomeHomeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage("assets/home/background.jpg"), fit: BoxFit.cover),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Stack(
            children: <Widget>[
              Positioned(top: statusBarHeight + scaleSize(10), left: scaleSize(15), child: IconHomeSettings()),
              Align(
                child: Image(image: const AssetImage('assets/home/header.png'), height: scaleSize(165)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Text(
                    "fastAppDescription".tr(args: [Durt.i.network.symbol]),
                    textAlign: TextAlign.center,
                    style: scaledTextStyle(
                      color: Colors.white,
                      fontSize: isTall ? 19 : 17,
                      fontWeight: FontWeight.w700,
                      shadows: const <Shadow>[
                        Shadow(offset: Offset(0, 0), blurRadius: 20, color: Colors.black),
                        Shadow(offset: Offset(0, 0), blurRadius: 20, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)],
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    children: <Widget>[
                      const Spacer(flex: 2),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Stack(
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(top: scaleSize(isTall ? 55 : 0)),
                                  child: Image(
                                    image: const AssetImage('assets/home/gecko-bienvenue.png'),
                                    height: scaleSize(isTall ? 180 : 160),
                                  ),
                                ),
                                Positioned(
                                  left: scaleSize(160),
                                  top: 10,
                                  child: BubbleSpeakWithTail(text: "noLizard".tr()),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SafeArea(
                        top: false,
                        child: Column(
                          children: [
                            ScaledSizedBox(
                              width: 330,
                              height: 60,
                              child: ElevatedButton(
                                key: keyOnboardingNewSafe,
                                style:
                                    ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: homeContext.colorScheme.primary,
                                      elevation: 0,
                                      padding: EdgeInsets.symmetric(vertical: scaleSize(8)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ).copyWith(
                                      elevation: WidgetStateProperty.resolveWith<double>((Set<WidgetState> states) {
                                        if (states.contains(WidgetState.pressed)) return 0;
                                        return 8;
                                      }),
                                      shadowColor: WidgetStateProperty.all(Colors.black.withValues(alpha: 0.2)),
                                    ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const OnboardingStepOne()),
                                  );
                                },
                                child: Text(
                                  'createWallet'.tr(),
                                  style: scaledTextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            ScaledSizedBox(height: scaleSize(17)),
                            ScaledSizedBox(
                              width: 330,
                              height: 60,
                              child: OutlinedButton(
                                key: keyRestoreSafe,
                                style:
                                    OutlinedButton.styleFrom(
                                      side: BorderSide(width: scaleSize(4), color: homeContext.colorScheme.primary),
                                      padding: EdgeInsets.symmetric(vertical: scaleSize(8)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                                    ).copyWith(
                                      elevation: WidgetStateProperty.resolveWith<double>((Set<WidgetState> states) {
                                        if (states.contains(WidgetState.pressed)) return 0;
                                        return 4;
                                      }),
                                      shadowColor: WidgetStateProperty.all(Colors.black.withValues(alpha: 0.15)),
                                    ),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const RestoreSafe()));
                                },
                                child: Text(
                                  "restoreWallet".tr(),
                                  style: scaledTextStyle(
                                    fontSize: 20,
                                    color: homeContext.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const TestWalletButton(),
                          ],
                        ),
                      ),
                      const Spacer(flex: 1),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
