import 'package:durt2/durt2.dart' show Durt;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/screens/home/test_wallet_button.dart';
import 'package:gecko/screens/onBoarding/import_choice_screen.dart';
import 'package:gecko/services/image_cache_service.dart';
import 'package:gecko/widgets/bubble_speak.dart';
import 'package:gecko/widgets/buttons/home_settings_button.dart';

/// Welcome screen widget displayed when no wallets exist
class WelcomeHomeWidget extends StatelessWidget {
  const WelcomeHomeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final imageCache = ImageCacheService();

    // Get fixed screen dimensions to avoid keyboard-related scaling
    final view = View.of(context);
    final screenSize = view.physicalSize / view.devicePixelRatio;

    return SizedBox.expand(
      child: Stack(
        children: [
          // Fixed background that ignores keyboard changes
          Positioned(
            top: 0,
            left: 0,
            width: screenSize.width,
            height: screenSize.height,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: imageCache.getImageProvider("assets/home/background.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Content on top
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Stack(
                children: <Widget>[
                  Positioned(top: statusBarHeight + scaleSize(10), left: scaleSize(15), child: IconHomeSettings()),
                  Align(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Image(
                        image: imageCache.getImageProvider('assets/home/header.png'),
                        height: scaleSize(165),
                      ),
                    ),
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
                        textScaler: TextScaler.noScaling,
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
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        children: <Widget>[
                          const Spacer(flex: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(top: scaleSize(isTall ? 55 : 0)),
                                child: Image(
                                  image: imageCache.getImageProvider('assets/home/gecko-bienvenue.png'),
                                  height: scaleSize(isTall ? 180 : 160),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: BubbleSpeakWithTail(text: "noLizard".tr()),
                              ),
                            ],
                          ),
                          SafeArea(
                            top: false,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: scaleSize(20)),
                              child: Column(
                                children: [
                                  ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: 400, minHeight: scaleSize(60)),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        key: keyOnboardingNewSafe,
                                        style:
                                            ElevatedButton.styleFrom(
                                              foregroundColor: Colors.white,
                                              backgroundColor: context.colorScheme.primary,
                                              elevation: 0,
                                              padding: EdgeInsets.symmetric(
                                                vertical: scaleSize(12),
                                                horizontal: scaleSize(16),
                                              ),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ).copyWith(
                                              elevation: WidgetStateProperty.resolveWith<double>((
                                                Set<WidgetState> states,
                                              ) {
                                                if (states.contains(WidgetState.pressed)) return 0;
                                                return 8;
                                              }),
                                              shadowColor: WidgetStateProperty.all(Colors.black.withValues(alpha: 0.2)),
                                            ),
                                        onPressed: () {
                                          Navigator.pushNamed(context, RouteNames.onboardingStepOne);
                                        },
                                        child: Text(
                                          'createWallet'.tr(),
                                          style: scaledTextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                  ScaledSizedBox(height: scaleSize(17)),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: 400, minHeight: scaleSize(60)),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        key: keyRestoreSafe,
                                        style:
                                            OutlinedButton.styleFrom(
                                              side: BorderSide(width: scaleSize(4), color: context.colorScheme.primary),
                                              padding: EdgeInsets.symmetric(
                                                vertical: scaleSize(12),
                                                horizontal: scaleSize(16),
                                              ),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                                            ).copyWith(
                                              elevation: WidgetStateProperty.resolveWith<double>((
                                                Set<WidgetState> states,
                                              ) {
                                                if (states.contains(WidgetState.pressed)) return 0;
                                                return 4;
                                              }),
                                              shadowColor: WidgetStateProperty.all(
                                                Colors.black.withValues(alpha: 0.15),
                                              ),
                                            ),
                                        onPressed: () {
                                          if (ImportChoiceScreen.enableLegacyLogin) {
                                            Navigator.pushNamed(context, RouteNames.importChoice);
                                          } else {
                                            Navigator.pushNamed(context, RouteNames.restoreSafe);
                                          }
                                        },
                                        child: Text(
                                          "restoreWallet".tr(),
                                          style: scaledTextStyle(
                                            fontSize: 20,
                                            color: context.colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const TestWalletButton(),
                                ],
                              ),
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
        ],
      ),
    );
  }
}
