import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/app_update_provider.dart';
import 'package:gecko/services/app_update_service.dart';
import 'package:gecko/providers/home_providers.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/screens/home/gecko_home_widget.dart';
import 'package:gecko/screens/home/welcome_home_widget.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/widgets/drawer.dart';
import 'package:gecko/widgets/desktop/desktop_utils.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isEasterEggActive = false;
  bool _splashRemoved = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Remove native splash only after Flutter has drawn its first frame
      FlutterNativeSplash.remove();
      // Trigger the fade transition now that the native splash is gone
      if (mounted) setState(() => _splashRemoved = true);
      await ref.read(appInitProvider.notifier).initApp(context: context, widgetRef: ref);
      _showCesiumImportInfoDialogIfNeeded();
      _checkForAppUpdate();
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

  Future<void> _checkForAppUpdate() async {
    try {
      final result = await ref.read(appUpdateCheckProvider.future);
      if (result == null) return;
      if (!mounted) return;

      switch (result.actionType) {
        case UpdateActionType.playStoreFlexible:
          await _handlePlayStoreFlexibleUpdate();
        case UpdateActionType.playStoreImmediate:
          await InAppUpdate.performImmediateUpdate();
        case UpdateActionType.showDialogWithUrl:
          await _handleDialogUpdate(result);
      }
    } catch (e) {
      log.d('App update check error: $e');
    }
  }

  Future<void> _handlePlayStoreFlexibleUpdate() async {
    try {
      await InAppUpdate.startFlexibleUpdate();
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      log.d('Play Store flexible update failed: $e');
    }
  }

  Future<void> _handleDialogUpdate(UpdateCheckResult result) async {
    final appInfoService = ref.read(appInfoServiceProvider);
    final confirmed = await showConfirmationDialog(
      context: context,
      title: "updateAvailableTitle".tr(),
      message: "updateAvailableMessage".tr(args: [result.latestVersion, appInfoService.appVersionShort]),
      confirmText: "updateNow".tr(),
      cancelText: "updateLater".tr(),
      customIcon: Icon(Icons.system_update_rounded, color: context.colorScheme.primary, size: 32),
    );

    if (confirmed && mounted && result.updateUrl != null) {
      await launchUrl(Uri.parse(result.updateUrl!), mode: LaunchMode.externalApplication);
    } else {
      ref.read(appUpdateServiceProvider).dismissUpdate(result);
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

    // Show splash until native splash is removed AND wallets are loaded.
    // This ensures the fade animation is visible (not hidden behind the native splash).
    final Widget child;
    if (!_splashRemoved || isLoading) {
      child = const _SplashPlaceholder(key: ValueKey('splash'));
    } else if (isWalletsExists || isDesktopLayout(context)) {
      // On desktop, always use the full desktop layout (even without wallets)
      // The left panel adapts to show welcome content when no wallets exist
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
      drawer: isDesktopLayout(context) ? null : MainDrawer(isWalletsExists: isWalletsExists),
      backgroundColor: context.colorScheme.secondary,
      body: SizedBox.expand(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          child: child,
        ),
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
      child: Image.asset('assets/icon/gecko_final_padded.png', width: 240, height: 240),
    );
  }
}
