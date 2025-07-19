// ignore_for_file: file_names, use_build_context_synchronously

import 'package:durt2/durt2.dart' show WalletEntity, Durt;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers.dart';
import 'package:gecko/providers/generate_wallets.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/widgets/commons/build_progress_bar.dart';
import 'package:gecko/widgets/commons/build_text.dart';
import 'package:gecko/screens/onBoarding/11_congratulations.dart';
import 'package:gecko/widgets/commons/fader_transition.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/widgets/scan_derivations_info.dart';
import 'package:gif_view/gif_view.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart' as old_provider;

class OnboardingStepTen extends ConsumerStatefulWidget {
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
  ConsumerState<OnboardingStepTen> createState() => _OnboardingStepTenState();
}

class _OnboardingStepTenState extends ConsumerState<OnboardingStepTen> {
  final formKey = GlobalKey<FormState>();
  Color? pinColor = const Color(0xFFA4B600);
  bool hasError = false;
  late final FocusNode pinFocus;
  late final TextEditingController enterPin;
  late final GenerateWalletsProvider generateWalletProvider;

  @override
  void initState() {
    super.initState();
    pinFocus = FocusNode(debugLabel: 'pinFocusNode10');
    enterPin = TextEditingController();
    generateWalletProvider = old_provider.Provider.of<GenerateWalletsProvider>(homeContext);
    generateWalletProvider.scanStatus = ScanDerivationsStatus.none;
  }

  @override
  Widget build(BuildContext context) {
    final walletOptions = old_provider.Provider.of<WalletOptionsProvider>(context);
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);
    final pinLenght = widget.pinCode.length;
    GifView.preFetchImage(AssetImage('assets/onBoarding/gecko-clin.gif'));

    return PopScope(
      onPopInvokedWithResult: (_, _) {
        myWalletProvider.isPinValid = false;
        myWalletProvider.isPinLoading = true;
      },
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        appBar: GeckoAppBar('myPassword'.tr()),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                ScaledSizedBox(height: isTall ? 25 : 5),
                const BuildProgressBar(pagePosition: 9),
                ScaledSizedBox(height: isTall ? 25 : 5),
                BuildText(text: "geckoWillCheckPassword".tr()),
                ScaledSizedBox(height: isTall ? 25 : 0),
                const ScanDerivationsInfo(),
                old_provider.Consumer<MyWalletsProvider>(
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
                pinForm(context, walletOptions, pinLenght, 1, 2),
                old_provider.Consumer<WalletOptionsProvider>(
                  builder: (context, walletOptions, _) {
                    return ref.read(durtProvider).isConnected
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
                                  style: scaledTextStyle(fontSize: 14, color: homeContext.colorScheme.onSurfaceVariant),
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
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context);
    final generateWalletProvider = old_provider.Provider.of<GenerateWalletsProvider>(context);

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

              final pinCodeint = int.parse(widget.pinCode);
              // Pass the original user mnemonic to createSafe for proper language detection
              // The service will handle the conversion internally for crypto operations
              final originalMnemonic =
                  generateWalletProvider.generatedMnemonic ?? generateWalletProvider.getEnglishMnemonic();

              await ref
                  .read(walletServiceProvider)
                  .createSafe(mnemonic: originalMnemonic, pinCode: pinCodeint, safeName: 'safeBoxName'.tr());

              ScanDerivationsResult scanStatus = ScanDerivationsResult.none;
              if (widget.scanDerivation) {
                scanStatus = await generateWalletProvider.scanDerivations(context);
              }
              switch (scanStatus) {
                case ScanDerivationsResult.none:
                case ScanDerivationsResult.walletNotFound:
                  final walletData = await ref.read(walletServiceProvider).importRootWallet(pinCode: widget.pinCode);

                  WalletEntity myWallet = WalletEntity.create(
                    address: walletData.address,
                    number: 0,
                    name: 'currentWallet'.tr(),
                    keyPairType: Durt.defaultKeyPairType,
                  );

                  final safe = ref.read(walletServiceProvider).getSafeBox(currentChest);
                  myWallet.safe.target = safe;

                  await ref.read(walletServiceProvider).walletBox.putAsync(myWallet);
                  break;
                case ScanDerivationsResult.timeout:
                case ScanDerivationsResult.error:
                  return;
                default:
                  break;
              }

              await myWalletProvider.readAllWallets(ref: ref, safeBoxNumber: currentChest);
              myWalletProvider.reload();

              generateWalletProvider.generatedMnemonic = '';
              myWalletProvider.debounceResetPinCode();

              // Set default wallet intelligently based on identity status
              // Priority: member > confirmed identity > any identity > wallet number 0 > first wallet
              WalletEntity? defaultWallet;

              try {
                // First try to get wallet with best identity status
                defaultWallet = await ref.read(idtyWalletAsyncProvider.future);
              } catch (e) {
                log.w('Error getting identity wallet during onboarding: $e');
                defaultWallet = null;
              }

              // Fallback to numeric priority if no identity wallet found
              defaultWallet ??= myWalletProvider.listWallets.firstWhereOrNull((w) => w.number == 0);

              // Final fallback to first available wallet
              if (defaultWallet == null && myWalletProvider.listWallets.isNotEmpty) {
                defaultWallet = myWalletProvider.listWallets.first;
              }

              if (defaultWallet != null) {
                await ref.read(walletServiceProvider).setDefaultAddress(defaultWallet.address);
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
