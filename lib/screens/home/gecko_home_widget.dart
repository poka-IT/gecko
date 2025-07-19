import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/chest_provider.dart';
import 'package:gecko/providers/home.dart';
import 'package:gecko/widgets/animated_background.dart';
import 'package:gecko/widgets/animated_header_image.dart';
import 'package:gecko/widgets/buttons/home_buttons.dart';
import 'package:gecko/widgets/buttons/home_settings_button.dart';
import 'package:gecko/widgets/commons/animated_text.dart';
import 'package:gecko/widgets/easter_egg_detector.dart';
import 'package:provider/provider.dart' as old_provider;

/// Home screen widget displayed when wallets exist
class GeckoHomeWidget extends StatelessWidget {
  final bool isEasterEggActive;
  final ValueChanged<bool> onEasterEggStateChange;

  const GeckoHomeWidget({super.key, required this.isEasterEggActive, required this.onEasterEggStateChange});

  @override
  Widget build(BuildContext context) {
    old_provider.Provider.of<ChestProvider>(context);

    final statusBarHeight = MediaQuery.of(context).padding.top;
    return EasterEggDetector(
      onPlayingStateChanged: onEasterEggStateChange,
      child: AnimatedBackground(
        isEasterEggActive: isEasterEggActive,
        child: Stack(
          children: [
            // Main content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    Positioned(top: statusBarHeight + scaleSize(10), left: scaleSize(15), child: IconHomeSettings()),
                    Align(
                      child: AnimatedHeaderImage(isEasterEggActive: isEasterEggActive, height: scaleSize(165)),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 350),
                        child: DefaultTextStyle(
                          textAlign: TextAlign.center,
                          style: scaledTextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            shadows: <Shadow>[
                              const Shadow(offset: Offset(0, 0), blurRadius: 20, color: Colors.black),
                              const Shadow(offset: Offset(0, 0), blurRadius: 20, color: Colors.black),
                            ],
                          ),
                          child: old_provider.Consumer<HomeProvider>(
                            builder: (context, homeP, _) {
                              return GestureDetector(
                                onTap: () {
                                  // Easter egg: only trigger when message is "noLizard"
                                  if (homeP.homeMessage == "noLizard".tr()) {
                                    homeP.showWisdomOfTheDay(context);
                                  }
                                },
                                child: AnimatedFadeOutIn<String>(
                                  data: homeP.homeMessage,
                                  duration: const Duration(milliseconds: 200),
                                  builder: (value) => Text(value),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ScaledSizedBox(height: 15),
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
                    child: SafeArea(child: HomeButtons(isEasterEggActive: isEasterEggActive)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
