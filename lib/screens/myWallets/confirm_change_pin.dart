// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class ConfirmChangePinScreen extends StatefulWidget {
  const ConfirmChangePinScreen({
    super.key,
    required this.walletName,
    required this.walletProvider,
    required this.newPinCode,
  });

  final String? walletName;
  final MyWalletsProvider walletProvider;
  final String newPinCode;

  @override
  State<ConfirmChangePinScreen> createState() => _ConfirmChangePinScreenState();
}

class _ConfirmChangePinScreenState extends State<ConfirmChangePinScreen> {
  final formKey = GlobalKey<FormState>();
  late final FocusNode pinFocus;
  late final TextEditingController enterPin;
  Color? pinColor = const Color(0xFFA4B600);
  bool hasError = false;
  bool isPinLoading = false;

  @override
  void initState() {
    super.initState();
    pinFocus = FocusNode(debugLabel: 'pinFocusNodeConfirm');
    enterPin = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: GeckoAppBar(widget.walletName!),
      body: SafeArea(
        child: Column(children: <Widget>[
          const SizedBox(height: 80),
          SizedBox(
            width: 300,
            child: Text(
              'geckoWillCheckPassword'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 30),
          if (hasError) ...[
            Text(
              "thisIsNotAGoodCode".tr(),
              style: const TextStyle(
                color: Colors.red,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
          ],
          pinForm(context),
        ]),
      ),
    );
  }

  Widget pinForm(BuildContext context) {
    return Form(
      key: formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 40),
        child: PinCodeTextField(
          focusNode: pinFocus,
          autoFocus: true,
          appContext: context,
          length: pinLength,
          obscureText: true,
          obscuringCharacter: '*',
          animationType: AnimationType.fade,
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(5),
            fieldHeight: 47,
            fieldWidth: 47,
            activeColor: pinColor,
            borderWidth: 4,
          ),
          cursorColor: Colors.black,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          controller: enterPin,
          onCompleted: (pin) async {
            if (pin == widget.newPinCode) {
              setState(() {
                isPinLoading = true;
                hasError = false;
              });

              // Demander l'ancien PIN pour confirmation
              if (!await widget.walletProvider.askPinCode()) {
                setState(() => isPinLoading = false);
                return;
              }

              final defaultWallet = widget.walletProvider.getDefaultWallet();

              await Durt.i.wallets.changePin(
                address: defaultWallet.address,
                oldPin: widget.walletProvider.pinCode,
                newPin: pin,
              );

              // Mettre à jour le PIN dans le provider
              widget.walletProvider.pinCode = pin;

              // Recharger les wallets avec le nouveau PIN
              final currentChest = widget.walletProvider.getCurrentSafe;
              await widget.walletProvider.readAllWallets(currentChest);
              widget.walletProvider.reload();

              Navigator.of(context)
                ..pop() // Ferme l'écran de confirmation
                ..pop(); // Ferme l'écran de changement de PIN
            } else {
              setState(() {
                hasError = true;
                isPinLoading = false;
                pinColor = Colors.red[600];
                enterPin.text = '';
              });
              pinFocus.requestFocus();
            }
          },
          onChanged: (value) {
            setState(() {
              if (enterPin.text.isNotEmpty) {
                hasError = false;
              }
              pinColor = const Color(0xFFA4B600);
            });
          },
        ),
      ),
    );
  }
}
