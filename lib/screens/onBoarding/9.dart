// ignore_for_file: file_names

import 'package:durt2/durt2.dart' as d;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/commons/build_progress_bar.dart';
import 'package:gecko/widgets/commons/build_text.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/widgets/gecko_pin_field.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OnboardingStepNine extends ConsumerStatefulWidget {
  const OnboardingStepNine({
    super.key,
    this.scanDerivation = false,
    this.fromRestore = false,
    this.legacySalt,
    this.legacyPassword,
    this.legacyMigrationData,
  });
  final bool scanDerivation;
  final bool fromRestore;
  final String? legacySalt;
  final String? legacyPassword;
  final LegacyMigrationData? legacyMigrationData;

  @override
  ConsumerState<OnboardingStepNine> createState() => _OnboardingStepNineState();
}

class _OnboardingStepNineState extends ConsumerState<OnboardingStepNine> {
  final formKey = GlobalKey<FormState>();
  late final FocusNode pinFocus;
  late final TextEditingController enterPin;
  late final PinInputController _pinController;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    pinFocus = FocusNode(debugLabel: 'pinFocusNode9');
    enterPin = TextEditingController();
    _pinController = PinInputController(textController: enterPin, focusNode: pinFocus);
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: GeckoAppBar('myPassword'.tr()),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            children: <Widget>[
              ScaledSizedBox(height: isTall ? 25 : 5),
              const BuildProgressBar(pagePosition: 8),
              ScaledSizedBox(height: isTall ? 25 : 5),
              BuildText(text: "hereIsThePasswordKeepIt".tr()),
              ScaledSizedBox(height: isTall ? 60 : 10),
              pinForm(context, 1, 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget pinForm(BuildContext context, int walletNbr, int derivation) {
    return GeckoPinField(
      key: keyPinForm,
      pinController: _pinController,
      length: pinLength,
      onCompleted: (pin) async {
        if (isPinComplex(pin)) {
          // Check if we're offline before proceeding
          final connectionStatus = ref.read(connectionStatusProvider);
          if (connectionStatus != d.ConnectionStatus.connected) {
            await _showOfflineDialog(context);
            return;
          }

          AppNavigator.pushWithFader(
            context,
            RouteNames.onboardingStepTen,
            arguments: OnboardingStepTenArguments(
              scanDerivation: widget.scanDerivation,
              pinCode: enterPin.text,
              fromRestore: widget.fromRestore,
              legacySalt: widget.legacySalt,
              legacyPassword: widget.legacyPassword,
              legacyMigrationData: widget.legacyMigrationData,
            ),
          );
        } else {
          hasError = true;
          enterPin.text = '';
          pinFocus.requestFocus();
        }
      },
    );
  }

  /// Shows an informative dialog when user tries to continue while offline
  Future _showOfflineDialog(BuildContext context) async {
    final result = await showConfirmationDialog(
      context: context,
      barrierDismissible: false,
      title: 'onboardingOfflineTitle'.tr(),
      message: 'onboardingOfflineMessage'.tr(),
      confirmText: 'returnToHome'.tr(),
      hideCancelButton: true,
    );
    if (result) {
      AppNavigator.pushAndRemoveUntilWithFader(
        // ignore: use_build_context_synchronously
        context,
        RouteNames.home,
        (route) => false, // Remove all previous routes
      );
    }
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
  List<String> sequences = [
    '0123',
    '1234',
    '2345',
    '3456',
    '4567',
    '5678',
    '6789',
    '9876',
    '8765',
    '7654',
    '6543',
    '5432',
    '4321',
    '3210',
  ];
  if (sequences.contains(pin)) return false;

  // Check if digits are too close to each other
  int sum = 0;
  for (int i = 0; i < 3; i++) {
    sum += (int.parse(pin[i]) - int.parse(pin[i + 1])).abs();
  }
  if (sum < 3) return false;

  // Check if PIN is a recent year
  int pinAsInt = int.parse(pin);
  if (pinAsInt >= 1950 && pinAsInt <= 2030) return false;

  return true;
}
