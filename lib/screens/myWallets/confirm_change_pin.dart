// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/biometric_provider.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/widgets/commons/responsive_center.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/widgets/gecko_pin_field.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class ConfirmChangePinScreen extends ConsumerStatefulWidget {
  const ConfirmChangePinScreen({super.key, required this.walletName, required this.newPinCode, required this.oldPin});

  final String walletName;
  final String newPinCode;
  final String oldPin;

  @override
  ConsumerState<ConfirmChangePinScreen> createState() => _ConfirmChangePinScreenState();
}

class _ConfirmChangePinScreenState extends ConsumerState<ConfirmChangePinScreen> {
  final formKey = GlobalKey<FormState>();
  late final FocusNode pinFocus;
  late final TextEditingController enterPin;
  late final PinInputController _pinController;
  Color? pinColor = const Color(0xFFA4B600);
  bool hasError = false;
  bool isPinLoading = false;

  @override
  void initState() {
    super.initState();
    pinFocus = FocusNode(debugLabel: 'pinFocusNodeConfirm');
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
      appBar: GeckoAppBar(widget.walletName),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 500,
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              const SizedBox(height: 80),
              SizedBox(
                width: 300,
                child: Text(
                  'geckoWillCheckPassword'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.0, color: Colors.grey[600], fontWeight: FontWeight.w400),
                ),
              ),
              const SizedBox(height: 30),
              if (hasError) ...[
                Text(
                  "thisIsNotAGoodCode".tr(),
                  style: const TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),
              ],
              pinForm(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget pinForm(BuildContext context) {
    return GeckoPinField(
      pinController: _pinController,
      pinColor: pinColor,
      length: pinLength,
      onCompleted: (pin) async {
        if (pin == widget.newPinCode) {
          setState(() {
            isPinLoading = true;
            hasError = false;
          });

          final firstWallet = ref.read(firstWalletProvider);
          if (firstWallet == null) return;

          try {
            await ref
                .read(walletServiceProvider)
                .changePin(address: firstWallet.address, oldPin: widget.oldPin, newPin: pin);
          } catch (e) {
            log.e('Failed to change PIN: $e');
            if (!mounted) return;
            setState(() {
              isPinLoading = false;
              hasError = true;
              pinColor = Colors.red[600];
              enterPin.text = '';
            });
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('changePinError'.tr()), backgroundColor: Colors.red));
            return;
          }

          // Mettre à jour le PIN dans le provider
          PinCodeService.pinCode = pin;
          PinCodeService.setAuthenticatedSafe(ref.read(walletServiceProvider).defaultSafeBoxNumber);

          // Ré-enrôler la biométrie avec le nouveau PIN si elle était activée
          final biometricState = ref.read(biometricProvider);
          if (biometricState.isEnrolledForCurrentSafe) {
            try {
              final walletService = ref.read(walletServiceProvider);
              await walletService.disableBiometric();
              await walletService.enableBiometric(pin: pin);
              log.i('Biometric re-enrolled with new PIN');
            } catch (e) {
              log.e('Failed to re-enroll biometric after PIN change: $e');
            }
          }

          // Recharger les wallets avec le nouveau PIN
          final currentSafe = ref.read(currentSafeNumberProvider);
          await ref.read(walletsListProvider.notifier).loadWallets(safeBoxNumber: currentSafe);

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
    );
  }
}
