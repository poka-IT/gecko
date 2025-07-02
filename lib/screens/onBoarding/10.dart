// ignore_for_file: file_names, use_build_context_synchronously

import 'package:durt2/durt2.dart' show Durt, WalletEntity;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/generate_wallets.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/widgets/commons/build_progress_bar.dart';
import 'package:gecko/widgets/commons/build_text.dart';
import 'package:gecko/screens/onBoarding/11_congratulations.dart';
import 'package:gecko/widgets/commons/fader_transition.dart';
import 'package:gecko/widgets/commons/offline_info.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/widgets/scan_derivations_info.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

class OnboardingStepTen extends StatefulWidget {
  const OnboardingStepTen({
    Key? validationKey,
    required this.pinCode,
    this.scanDerivation = false,
    this.fromRestore = false,
  }) : super(key: validationKey);

  final bool scanDerivation;
  final String pinCode;
  final bool fromRestore;
  @override
  State<OnboardingStepTen> createState() => _OnboardingStepTenState();
}

class _OnboardingStepTenState extends State<OnboardingStepTen> {
  final formKey = GlobalKey<FormState>();
  Color? pinColor = const Color(0xFFA4B600);
  bool hasError = false;
  late final FocusNode pinFocus;
  late final TextEditingController enterPin;
  final generateWalletProvider = Provider.of<GenerateWalletsProvider>(homeContext);

  @override
  void initState() {
    super.initState();
    pinFocus = FocusNode(debugLabel: 'pinFocusNode10');
    enterPin = TextEditingController();
    generateWalletProvider.scanStatus = ScanDerivationsStatus.none;
  }

  @override
  Widget build(BuildContext context) {
    final walletOptions = Provider.of<WalletOptionsProvider>(context);
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);
    final pinLenght = widget.pinCode.length;

    return PopScope(
      onPopInvokedWithResult: (_, _) {
        myWalletProvider.isPinValid = false;
        myWalletProvider.isPinLoading = true;
      },
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        appBar: GeckoAppBar('myPassword'.tr()),
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    ScaledSizedBox(height: isTall ? 25 : 5),
                    const BuildProgressBar(pagePosition: 9),
                    ScaledSizedBox(height: isTall ? 25 : 5),
                    BuildText(text: "geckoWillCheckPassword".tr()),
                    ScaledSizedBox(height: isTall ? 25 : 0),
                    const ScanDerivationsInfo(),
                    Consumer<MyWalletsProvider>(
                      builder: (context, mw, _) {
                        return Visibility(
                          visible: !myWalletProvider.isPinValid && !myWalletProvider.isPinLoading,
                          child: Text(
                            "thisIsNotAGoodCode".tr(),
                            style: scaledTextStyle(fontSize: 15, color: Colors.red, fontWeight: FontWeight.w500),
                          ),
                        );
                      },
                    ),
                    ScaledSizedBox(height: isTall ? 20 : 0),
                    Durt.i.isConnected
                        ? pinForm(context, walletOptions, pinLenght, 1, 2)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "youHaveToBeConnectedToValidateChest".tr(),
                                style: scaledTextStyle(
                                  fontSize: 16,
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                    Consumer<WalletOptionsProvider>(
                      builder: (context, walletOptions, _) {
                        return Durt.i.isConnected
                            ? InkWell(
                                key: keyCachePassword,
                                onTap: () {
                                  walletOptions.changePinCacheChoice();
                                },
                                child: Row(
                                  children: [
                                    ScaledSizedBox(height: isTall ? 30 : 0),
                                    const Spacer(),
                                    Icon(
                                      configBox.get('isCacheChecked') ?? false
                                          ? Icons.check_box
                                          : Icons.check_box_outline_blank,
                                      color: context.colorScheme.primary,
                                      size: scaleSize(22),
                                    ),
                                    ScaledSizedBox(width: 8),
                                    Text(
                                      'rememberPassword'.tr(),
                                      style: scaledTextStyle(
                                        fontSize: 14,
                                        color: homeContext.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const Spacer(),
                                  ],
                                ),
                              )
                            : const Text('');
                      },
                    ),
                  ],
                ),
              ),
              const OfflineInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget pinForm(
    BuildContext context,
    WalletOptionsProvider walletOptions,
    int pinLenght,
    int walletNbr,
    int derivation,
  ) {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context);

    final currentChest = myWalletProvider.getCurrentSafe;

    return Form(
      key: formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 40),
        child: PinCodeTextField(
          key: keyPinForm,
          textCapitalization: TextCapitalization.characters,
          // autoDisposeControllers: false,
          focusNode: pinFocus,
          autoFocus: true,
          appContext: context,
          pastedTextStyle: TextStyle(color: Colors.green.shade600, fontWeight: FontWeight.bold),
          length: pinLenght,
          obscureText: true,
          obscuringCharacter: '*',
          useHapticFeedback: true,
          animationType: AnimationType.slide,
          animationDuration: const Duration(milliseconds: 40),
          validator: (v) {
            if (v!.length < pinLenght) {
              return "yourPasswordLengthIsX".tr(args: [pinLenght.toString()]);
            } else {
              return null;
            }
          },
          pinTheme: PinTheme(
            activeColor: pinColor,
            borderWidth: 4,
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(5),
            fieldHeight: scaleSize(47),
            fieldWidth: scaleSize(47),
            activeFillColor: Colors.black,
          ),
          showCursor: !kDebugMode,
          cursorColor: Colors.black,
          textStyle: const TextStyle(fontSize: 24, height: 1.6),
          backgroundColor: homeContext.colorScheme.surface,
          enableActiveFill: false,
          controller: enterPin,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          beforeTextPaste: (text) {
            return text != null && text.contains(RegExp(r'^[0-9]+$'));
          },
          boxShadows: const [BoxShadow(offset: Offset(0, 1), color: Colors.black12, blurRadius: 10)],
          onCompleted: (pin) async {
            myWalletProvider.pinCode = pin.toUpperCase();
            myWalletProvider.pinLenght = pinLenght;
            if (pin.toUpperCase() == widget.pinCode) {
              pinColor = Colors.green[500];
              myWalletProvider.isPinLoading = false;
              myWalletProvider.isPinValid = true;

              //TODO: Use int pincode directly instead of cast
              final pinCodeint = int.parse(widget.pinCode);
              await Durt.i.wallets.createSafe(mnemonic: generateWalletProvider.generatedMnemonic!, pinCode: pinCodeint);

              ScanDerivationsResult scanStatus = ScanDerivationsResult.none;
              if (widget.scanDerivation) {
                scanStatus = await generateWalletProvider.scanDerivations(context, widget.pinCode);
              }
              switch (scanStatus) {
                case ScanDerivationsResult.none:
                case ScanDerivationsResult.walletNotFound:
                  final walletData = await Durt.i.wallets.importRootWallet(pinCode: widget.pinCode);
                  final address = Durt.i.wallets.getAddress(walletData.address);

                  WalletEntity myWallet = WalletEntity(
                    address: address,
                    number: 0,
                    derivation: -1,
                    name: 'currentWallet'.tr(),
                  );

                  final safe = Durt.i.wallets.getSafeBox(currentChest);
                  myWallet.safe.target = safe;

                  await Durt.i.wallets.walletBox.putAsync(myWallet);
                  break;
                case ScanDerivationsResult.timeout:
                case ScanDerivationsResult.error:
                  return;
                default:
                  break;
              }

              await myWalletProvider.readAllWallets(currentChest);
              myWalletProvider.reload();

              generateWalletProvider.generatedMnemonic = '';
              myWalletProvider.debounceResetPinCode();

              // Set default wallet to number 0 of current chest
              WalletEntity? defaultWallet =
                  myWalletProvider.listWallets.firstWhereOrNull((w) => w.isMember) ??
                  myWalletProvider.listWallets.firstWhereOrNull((w) => w.hasIdentity) ??
                  myWalletProvider.listWallets.firstWhereOrNull((w) => w.number == 0);

              if (defaultWallet == null && myWalletProvider.listWallets.isNotEmpty) {
                defaultWallet = myWalletProvider.listWallets.first;
              }
              if (defaultWallet != null) {
                final address = Durt.i.wallets.getAddress(defaultWallet.address);
                await Durt.i.wallets.setDefaultAddress(address);
              }

              await Navigator.push(
                context,
                FaderTransition(page: OnboardingStepEleven(fromRestore: widget.fromRestore), isFast: false),
              );
            } else {
              hasError = true;
              myWalletProvider.isPinLoading = false;
              myWalletProvider.isPinValid = false;
              pinColor = Colors.red[600];
              enterPin.text = '';
              pinFocus.requestFocus();
            }
          },
          onChanged: (value) {
            if (enterPin.text != '') myWalletProvider.isPinLoading = true;
            if (pinColor != const Color(0xFFA4B600)) {
              pinColor = const Color(0xFFA4B600);
            }
            myWalletProvider.reload();
          },
        ),
      ),
    );
  }
}
