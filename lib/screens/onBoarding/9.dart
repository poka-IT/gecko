// ignore_for_file: file_names

import 'package:durt2/durt2.dart' as d;
import 'package:easy_localization/easy_localization.dart';
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
import 'package:gecko/widgets/commons/responsive_center.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/widgets/pin/gecko_pin_entry.dart';

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
  final _pinController = GeckoPinEntryController();
  bool hasError = false;

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
        child: ResponsiveCenter(
          maxWidth: 500,
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              ScaledSizedBox(height: isTall ? 25 : 5),
              const BuildProgressBar(pagePosition: 8),
              ScaledSizedBox(height: isTall ? 25 : 5),
              BuildText(text: "hereIsThePasswordKeepIt".tr()),
              if (hasError)
                Padding(
                  padding: EdgeInsets.only(top: scaleSize(10)),
                  child: Text(
                    'passwordTooSimple'.tr(),
                    style: scaledTextStyle(
                      fontSize: 15,
                      color: context.geckoColors.danger,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: scaleSize(16)),
                  child: GeckoPinEntry(
                    key: keyPinForm,
                    controller: _pinController,
                    onCompleted: _onPinCompleted,
                    onChanged: (_) {
                      if (hasError) setState(() => hasError = false);
                    },
                    onErrorAnimationComplete: () {
                      setState(() => hasError = true);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onPinCompleted(String pin) async {
    if (isPinComplex(pin)) {
      final connectionStatus = ref.read(connectionStatusProvider);
      if (connectionStatus != d.ConnectionStatus.connected) {
        _pinController.clear();
        await _showOfflineDialog(context);
        return;
      }

      AppNavigator.pushWithFader(
        context,
        RouteNames.onboardingStepTen,
        arguments: OnboardingStepTenArguments(
          scanDerivation: widget.scanDerivation,
          pinCode: pin,
          fromRestore: widget.fromRestore,
          legacySalt: widget.legacySalt,
          legacyPassword: widget.legacyPassword,
          legacyMigrationData: widget.legacyMigrationData,
        ),
      );
    } else {
      _pinController.triggerError();
    }
  }

  Future<void> _showOfflineDialog(BuildContext context) async {
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
        (route) => false,
      );
    }
  }
}
