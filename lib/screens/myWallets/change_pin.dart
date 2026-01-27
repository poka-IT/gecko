// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/myWallets/confirm_change_pin.dart';
import 'package:gecko/screens/onBoarding/9.dart';
import 'package:gecko/widgets/commons/fader_transition.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key, required this.walletName});

  final String walletName;

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final formKey = GlobalKey<FormState>();
  late final FocusNode pinFocus;
  late final TextEditingController enterPin;
  Color? pinColor = const Color(0xFFA4B600);
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    pinFocus = FocusNode(debugLabel: 'pinFocusNodeChange');
    enterPin = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: GeckoAppBar(widget.walletName),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 60),
                Text(
                  'choosePassword'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.0, color: Colors.grey[600], fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 30),
                pinForm(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget pinForm(BuildContext context) {
    return Form(
      key: formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 40),
        child: Column(
          children: [
            PinCodeTextField(
              focusNode: pinFocus,
              autoFocus: true,
              appContext: context,
              length: pinLength,
              obscureText: true,
              obscuringCharacter: '*',
              animationType: AnimationType.fade,
              validator: (v) {
                if (v!.isEmpty || v.length == pinLength) {
                  if (!isPinComplex(v)) {
                    return "passwordTooSimple".tr();
                  }
                }
                return null;
              },
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(5),
                fieldHeight: 47,
                fieldWidth: 47,
                activeColor: pinColor,
                errorBorderColor: Colors.red,
                borderWidth: 4,
              ),
              cursorColor: Colors.black,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              controller: enterPin,
              onCompleted: (pin) async {
                if (isPinComplex(pin)) {
                  Navigator.push(
                    context,
                    FaderTransition(
                      page: ConfirmChangePinScreen(walletName: widget.walletName, newPinCode: pin),
                      isFast: false,
                    ),
                  );
                } else {
                  setState(() {
                    hasError = true;
                    pinColor = Colors.red[600];
                    enterPin.text = '';
                    pinFocus.requestFocus();
                  });
                }
              },
              onChanged: (value) {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    hasError = false;
                    pinColor = const Color(0xFFA4B600);
                  });
                }
              },
            ),
            if (hasError) ...[
              const SizedBox(height: 20),
              Text(
                "passwordTooSimple".tr(),
                style: const TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
