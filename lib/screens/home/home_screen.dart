import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';

import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/providers/home_providers.dart';
import 'package:gecko/providers/certification_queue_provider.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/screens/certification_queue_screen.dart';
import 'package:gecko/screens/home/gecko_home_widget.dart';
import 'package:gecko/screens/home/welcome_home_widget.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/widgets/certify/ready_certification_modal.dart';
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
      _checkReadyCertifications();
    });
  }

  /// Check if there are any ready certifications and show notification modal
  void _checkReadyCertifications() {
    // Also check current state on startup (delayed to ensure providers are ready)
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;

      // Get the effective certification wallet
      final identityWallet = await ref.read(effectiveCertificationWalletProvider.future);
      if (identityWallet == null) return;

      final issuerAddress = identityWallet.address;

      // Listen for ready certification notifications for this issuer
      ref.listenManual(readyCertificationNotifierProvider(issuerAddress), (previous, next) {
        if (next != null && context.mounted) {
          ReadyCertificationModal.show(
            context: context,
            pendingCert: next,
            issuerAddress: issuerAddress,
            onCertify: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CertificationQueueScreen(issuerAddress: issuerAddress)),
              );
            },
            onViewQueue: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CertificationQueueScreen(issuerAddress: issuerAddress)),
              );
            },
            onDismiss: () {
              // Notification dismissed, will be shown again on next check
            },
          );
        }
      });

      // Check current state
      final readyCert = ref.read(readyCertificationNotifierProvider(issuerAddress));
      if (readyCert != null && context.mounted) {
        ReadyCertificationModal.show(
          context: context,
          pendingCert: readyCert,
          issuerAddress: issuerAddress,
          onCertify: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CertificationQueueScreen(issuerAddress: issuerAddress)),
            );
          },
          onViewQueue: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CertificationQueueScreen(issuerAddress: issuerAddress)),
            );
          },
          onDismiss: () {},
        );
      }
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
    final isWalletsExists = ref.watch(isWalletsExistsProvider);

    // Use view size instead of MediaQuery to avoid rebuilds when keyboard shows/hides
    final viewSize = View.of(context).physicalSize / View.of(context).devicePixelRatio;
    isTall = (viewSize.height / viewSize.width) > 1.75;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: MainDrawer(isWalletsExists: isWalletsExists),
      backgroundColor: context.colorScheme.secondary,
      body: SizedBox.expand(
        child: isWalletsExists
            ? GeckoHomeWidget(
                isEasterEggActive: _isEasterEggActive,
                onEasterEggStateChange: _handleEasterEggStateChange,
              )
            : const WelcomeHomeWidget(),
      ),
    );
  }
}
