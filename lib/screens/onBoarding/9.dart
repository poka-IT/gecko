// ignore_for_file: file_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/screens/onBoarding/10.dart';
import 'package:gecko/widgets/commons/build_progress_bar.dart';
import 'package:gecko/widgets/commons/build_text.dart';
import 'package:gecko/widgets/commons/fader_transition.dart';
import 'package:gecko/widgets/commons/offline_info.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OnboardingStepNine extends StatefulWidget {
  const OnboardingStepNine({super.key, this.scanDerivation = false});
  final bool scanDerivation;

  @override
  State<OnboardingStepNine> createState() => _OnboardingStepNineState();
}

class _OnboardingStepNineState extends State<OnboardingStepNine> {
  final formKey = GlobalKey<FormState>();
  late final FocusNode pinFocus;
  late final TextEditingController enterPin;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    pinFocus = FocusNode(debugLabel: 'pinFocusNode9');
    enterPin = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: GeckoAppBar('myPassword'.tr()),
      body: SafeArea(
        child: Stack(children: [
          Column(children: <Widget>[
            ScaledSizedBox(height: isTall ? 25 : 5),
            const BuildProgressBar(pagePosition: 8),
            ScaledSizedBox(height: isTall ? 25 : 5),
            BuildText(text: "hereIsThePasswordKeepIt".tr()),
            ScaledSizedBox(height: isTall ? 60 : 10),
            pinForm(context, 1, 2),
          ]),
          const OfflineInfo(),
        ]),
      ),
    );
  }

  Widget pinForm(context, int walletNbr, int derivation) {
    Color? pinColor = const Color(0xFFA4B600);

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
            pastedTextStyle: TextStyle(
              color: Colors.green.shade600,
              fontWeight: FontWeight.bold,
            ),
            length: pinLength,
            obscureText: true,
            obscuringCharacter: '*',
            useHapticFeedback: true,
            animationType: AnimationType.slide,
            animationDuration: const Duration(milliseconds: 40),
            validator: (v) {
              if ((v!.isEmpty || v.length == pinLength) && !isPinComplex(v)) {
                return "passwordTooSimple".tr();
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
            backgroundColor: const Color(0xffF9F9F1),
            enableActiveFill: false,
            controller: enterPin,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            beforeTextPaste: (text) {
              return text != null && text.contains(RegExp(r'^[0-9]+$'));
            },
            boxShadows: const [
              BoxShadow(
                offset: Offset(0, 1),
                color: Colors.black12,
                blurRadius: 10,
              )
            ],
            onCompleted: (pin) async {
              if (isPinComplex(pin)) {
                Navigator.push(
                  context,
                  FaderTransition(page: OnboardingStepTen(scanDerivation: widget.scanDerivation, pinCode: enterPin.text), isFast: false),
                );
              } else {
                hasError = true;
                pinColor = Colors.red[600];
                enterPin.text = '';
                pinFocus.requestFocus();
              }
            },
          )),
    );
  }
}

bool isPinComplex(String pin) {
  // Debug mode
  if (kDebugMode && debugPin) return true;

  // Check if PIN is 4 digits
  if (pin.length != pinLength) return false;

  // Check for repeated digits (e.g., 1111)
  if (RegExp(r'^(\d)\1{3}$').hasMatch(pin)) return false;

  // Check for common sequences
  List<String> sequences = ['0123', '1234', '2345', '3456', '4567', '5678', '6789', '9876', '8765', '7654', '6543', '5432', '4321', '3210'];
  if (sequences.contains(pin)) return false;

  // Check if digits are too close to each other
  int sum = 0;
  for (int i = 0; i < 3; i++) {
    sum += (int.parse(pin[i]) - int.parse(pin[i + 1])).abs();
  }
  if (sum < 5) return false;

  // Check for palindromes
  if (pin == pin.split('').reversed.join()) return false;

  // Check if PIN is a recent year
  int pinAsInt = int.parse(pin);
  if (pinAsInt >= 1950 && pinAsInt <= 2030) return false;

  return true;
}
