import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/safe_provider.dart';
import 'package:gecko/providers/home.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/screens/home/gecko_home_widget.dart';
import 'package:gecko/screens/home/welcome_home_widget.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/widgets/drawer.dart';
import 'package:provider/provider.dart' as old_provider;

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
    // final bool alreadyShown = configBox.get('cesiumImportInfoShown') ?? false;
    final bool alreadyShown = false;

    if (!isWalletsExists && !alreadyShown) {
      showConfirmationDialog(
        context: context,
        title: "cesium_import_info_title".tr(),
        message: "cesium_import_info_body".tr(),
        confirmText: "gotit".tr(),
        customIcon: SvgPicture.asset('assets/cesium_bw2.svg', semanticsLabel: 'CS', height: scaleSize(40)),
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
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context);
    old_provider.Provider.of<SafeProvider>(context);
    final isWalletsExists = myWalletProvider.isWalletsExists;

    isTall = (MediaQuery.of(context).size.height / MediaQuery.of(context).size.width) > 1.75;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: MainDrawer(isWalletsExists: isWalletsExists),
      backgroundColor: context.colorScheme.secondary,
      body: isWalletsExists
          ? GeckoHomeWidget(isEasterEggActive: _isEasterEggActive, onEasterEggStateChange: _handleEasterEggStateChange)
          : const WelcomeHomeWidget(),
    );
  }
}
