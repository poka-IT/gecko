import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/providers/home_providers.dart';
import 'package:gecko/screens/home/gecko_home_widget.dart';
import 'package:gecko/screens/home/welcome_home_widget.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/widgets/drawer.dart';

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
      await ref.read(appInitProvider.notifier).initApp(context: context, widgetRef: ref);
      _showCesiumImportInfoDialogIfNeeded();
      // Note: Ready certification notifications are handled globally by ReadyCertificationListener in main.dart
    });
  }

  void _showCesiumImportInfoDialogIfNeeded() {
    final bool isWalletsExists = ref.read(isWalletsExistsProvider);
    final bool alreadyShown = configBox.get('cesiumImportInfoShown') ?? false;

    if (!isWalletsExists && !alreadyShown) {
      showConfirmationDialog(
        context: context,
        title: "cesium_import_info_title".tr(),
        message: "cesium_import_info_body".tr(),
        confirmText: "gotit".tr(),
        customIcon: SvgPicture.asset('assets/cesium_bw2.svg', semanticsLabel: 'CS', height: scaleSize(40)),
        barrierDismissible: false,
        hideCancelButton: true,
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
    final walletsState = ref.watch(walletsListProvider);
    final isWalletsExists = walletsState.wallets.isNotEmpty;
    final isLoading = walletsState.isLoading;

    // Use view size instead of MediaQuery to avoid rebuilds when keyboard shows/hides
    final viewSize = View.of(context).physicalSize / View.of(context).devicePixelRatio;
    isTall = (viewSize.height / viewSize.width) > 1.75;

    // While wallets are loading, show a splash-like screen to avoid flashing WelcomeHome
    final Widget child;
    if (isLoading) {
      child = const _SplashPlaceholder(key: ValueKey('splash'));
    } else if (isWalletsExists) {
      child = GeckoHomeWidget(
        key: const ValueKey('home'),
        isEasterEggActive: _isEasterEggActive,
        onEasterEggStateChange: _handleEasterEggStateChange,
      );
    } else {
      child = const WelcomeHomeWidget(key: ValueKey('welcome'));
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: MainDrawer(isWalletsExists: isWalletsExists),
      backgroundColor: context.colorScheme.secondary,
      body: SizedBox.expand(
        child: AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: child),
      ),
    );
  }
}

/// Matches the native splash screen visually (golden background + centered logo)
/// so the transition from native splash to Flutter content is seamless.
class _SplashPlaceholder extends StatelessWidget {
  const _SplashPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFD68E),
      alignment: Alignment.center,
      child: Image.asset('assets/icon/gecko_final.png', width: 180, height: 180),
    );
  }
}
