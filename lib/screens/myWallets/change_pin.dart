import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/screens/myWallets/confirm_change_pin.dart';
import 'package:gecko/widgets/commons/fader_transition.dart';
import 'package:gecko/widgets/commons/responsive_center.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/widgets/pin/gecko_pin_entry.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key, required this.walletName, required this.oldPin});

  final String walletName;
  final String oldPin;

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
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
      appBar: GeckoAppBar(widget.walletName),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 500,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 60),
              Text(
                'choosePassword'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16.0, color: Colors.grey[600], fontWeight: FontWeight.w400),
              ),
              if (hasError) ...[
                const SizedBox(height: 20),
                Text(
                  "passwordTooSimple".tr(),
                  style: TextStyle(color: context.geckoColors.danger, fontSize: 15, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ],
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GeckoPinEntry(
                    controller: _pinController,
                    onCompleted: (pin) {
                      if (isPinComplex(pin)) {
                        Navigator.push(
                          context,
                          FaderTransition(
                            page: ConfirmChangePinScreen(
                              walletName: widget.walletName,
                              newPinCode: pin,
                              oldPin: widget.oldPin,
                            ),
                            isFast: false,
                          ),
                        );
                      } else {
                        _pinController.triggerError();
                      }
                    },
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
}
