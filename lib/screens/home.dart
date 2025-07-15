import 'package:durt2/durt2.dart' show Durt, Networks, Utils;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/chest_provider.dart';
import 'package:gecko/providers/home.dart';
import 'package:flutter/material.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/widgets/bubble_speak.dart';
import 'package:gecko/widgets/buttons/home_settings_button.dart';
import 'package:gecko/widgets/commons/animated_text.dart';
import 'package:gecko/screens/myWallets/restore_chest.dart';
import 'package:gecko/screens/onBoarding/1.dart';
import 'package:gecko/widgets/drawer.dart';
import 'package:gecko/widgets/buttons/home_buttons.dart';
import 'package:gecko/widgets/easter_egg_detector.dart';
import 'package:gecko/widgets/animated_header_image.dart';
import 'package:gecko/widgets/animated_background.dart';
import 'package:gecko/utils/debug_test_wallet.dart';
import 'package:provider/provider.dart' as old_provider;
import 'package:gecko/providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isEasterEggActive = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await old_provider.Provider.of<HomeProvider>(context, listen: false).initHome(context: context, ref: ref);
      _showCesiumImportInfoDialogIfNeeded();
    });
  }

  void _showCesiumImportInfoDialogIfNeeded() {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);
    final bool isWalletsExists = myWalletProvider.isWalletsExists;
    final bool alreadyShown = configBox.get('cesiumImportInfoShown') ?? false;

    if (!isWalletsExists && !alreadyShown) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("cesium_import_info_title".tr()),
            content: Text("cesium_import_info_body".tr()),
            actions: <Widget>[
              TextButton(
                child: Text("gotit".tr()),
                onPressed: () {
                  configBox.put('cesiumImportInfoShown', true);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      configBox.put('cesiumImportInfoShown', true);
    }
  }

  void _handleEasterEggStateChange(bool isActive) {
    setState(() {
      _isEasterEggActive = isActive;
    });
  }

  @override
  Widget build(BuildContext context) {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context);
    old_provider.Provider.of<ChestProvider>(context);
    final isWalletsExists = myWalletProvider.isWalletsExists;

    isTall = (MediaQuery.of(context).size.height / MediaQuery.of(context).size.width) > 1.75;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: MainDrawer(isWalletsExists: isWalletsExists),
      backgroundColor: context.colorScheme.secondary,
      body: isWalletsExists ? geckHome(context, _isEasterEggActive, _handleEasterEggStateChange) : welcomeHome(context),
    );
  }
}

/// Check if test wallet button should be shown (reactive to network changes)
/// Only show if in debug mode AND connected to a local Duniter network
Widget _buildTestWalletButton(BuildContext context) {
  return Consumer(
    builder: (context, ref, _) {
      // Watch connection status to make this reactive
      ref.watch(duniterConnectionStatusProvider);

      if (!kDebugMode) return const SizedBox.shrink();

      // Check if current Duniter endpoint is local
      final currentEndpoint = Networks.duniterEndpoint;
      if (currentEndpoint.isEmpty) return const SizedBox.shrink();

      if (!Utils.isLocalEndpoint(currentEndpoint)) return const SizedBox.shrink();

      return Column(
        children: [
          ScaledSizedBox(height: scaleSize(25)),
          ScaledSizedBox(
            width: 330,
            height: 60,
            child: OutlinedButton(
              style:
                  OutlinedButton.styleFrom(
                    side: BorderSide(width: scaleSize(2), color: Colors.orange),
                    padding: EdgeInsets.symmetric(vertical: scaleSize(8)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.orange.withValues(alpha: 0.1),
                  ).copyWith(
                    elevation: WidgetStateProperty.resolveWith<double>((Set<WidgetState> states) {
                      if (states.contains(WidgetState.pressed)) return 0;
                      return 4;
                    }),
                    shadowColor: WidgetStateProperty.all(Colors.black.withValues(alpha: 0.15)),
                  ),
              onPressed: () => DebugTestWalletService.importTestWallet(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bug_report, color: Colors.orange, size: scaleSize(20)),
                  ScaledSizedBox(width: 8),
                  Text(
                    "Import Test Wallet (Dev Mode)",
                    style: scaledTextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// Show welcome screen if no wallets exist
Widget geckHome(BuildContext context, bool isEasterEggActive, ValueChanged<bool> onEasterEggStateChange) {
  old_provider.Provider.of<ChestProvider>(context);

  final statusBarHeight = MediaQuery.of(context).padding.top;
  return EasterEggDetector(
    onPlayingStateChanged: onEasterEggStateChange,
    child: AnimatedBackground(
      isEasterEggActive: isEasterEggActive,
      child: Stack(
        children: [
          // Contenu par-dessus
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
                  child: HomeButtons(isEasterEggActive: isEasterEggActive),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget welcomeHome(BuildContext context) {
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
                    const Spacer(flex: 4),
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
                    ScaledSizedBox(
                      width: 330,
                      height: 60,
                      child: ElevatedButton(
                        key: keyOnboardingNewChest,
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
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const OnboardingStepOne()));
                        },
                        child: Text(
                          'createWallet'.tr(),
                          style: scaledTextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                    ScaledSizedBox(height: scaleSize(25)),
                    ScaledSizedBox(
                      width: 330,
                      height: 60,
                      child: OutlinedButton(
                        key: keyRestoreChest,
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
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const RestoreChest()));
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
                    _buildTestWalletButton(context),
                    const Spacer(flex: 3),
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
