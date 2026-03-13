// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/biometric_provider.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/screens/onBoarding/9.dart' show isPinComplex;
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/widgets/desktop/desktop_modal.dart';
import 'package:gecko/widgets/gecko_pin_field.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

/// Shows a self-contained change PIN flow inside a desktop modal.
///
/// Handles: new PIN entry -> confirmation -> save.
Future<void> showDesktopChangePinModal(BuildContext context, {required String walletName, required String oldPin}) {
  return showDesktopModal(
    context: context,
    title: 'changePassword'.tr(),
    size: DesktopModalSize.small,
    contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
    builder: (context) => _ChangePinContent(walletName: walletName, oldPin: oldPin),
  );
}

class _ChangePinContent extends ConsumerStatefulWidget {
  const _ChangePinContent({required this.walletName, required this.oldPin});
  final String walletName;
  final String oldPin;

  @override
  ConsumerState<_ChangePinContent> createState() => _ChangePinContentState();
}

class _ChangePinContentState extends ConsumerState<_ChangePinContent> {
  late FocusNode _pinFocusNode;
  late TextEditingController _pinTextController;
  late PinInputController _pinController;
  late FocusNode _confirmFocusNode;
  late TextEditingController _confirmTextController;
  late PinInputController _confirmController;

  String _newPin = '';
  bool _isConfirmStep = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isProcessing = false;
  Color _pinColor = const Color(0xFFA4B600);

  @override
  void initState() {
    super.initState();
    _pinFocusNode = FocusNode(debugLabel: 'desktop_change_pin');
    _pinTextController = TextEditingController();
    _pinController = PinInputController(textController: _pinTextController, focusNode: _pinFocusNode);
    _confirmFocusNode = FocusNode(debugLabel: 'desktop_confirm_pin');
    _confirmTextController = TextEditingController();
    _confirmController = PinInputController(textController: _confirmTextController, focusNode: _confirmFocusNode);
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        Text(
          _isConfirmStep ? 'geckoWillCheckPassword'.tr() : 'choosePassword'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: context.colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 8),
        if (_hasError)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
        if (_isProcessing)
          const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: CircularProgressIndicator())
        else if (!_isConfirmStep)
          GeckoPinField(
            pinController: _pinController,
            pinColor: _pinColor,
            length: pinLength,
            onCompleted: (pin) {
              if (isPinComplex(pin)) {
                setState(() {
                  _newPin = pin.toUpperCase();
                  _isConfirmStep = true;
                  _hasError = false;
                  _pinColor = const Color(0xFFA4B600);
                });
                WidgetsBinding.instance.addPostFrameCallback((_) => _confirmFocusNode.requestFocus());
              } else {
                setState(() {
                  _hasError = true;
                  _errorMessage = 'passwordTooSimple'.tr();
                  _pinColor = Colors.red;
                });
                _pinTextController.clear();
                _pinFocusNode.requestFocus();
              }
            },
            onChanged: (value) {
              if (_hasError && value.isNotEmpty) setState(() => _hasError = false);
              if (_pinColor != const Color(0xFFA4B600)) setState(() => _pinColor = const Color(0xFFA4B600));
            },
          )
        else
          GeckoPinField(
            pinController: _confirmController,
            pinColor: _pinColor,
            length: _newPin.length,
            onCompleted: (pin) async {
              if (pin.toUpperCase() == _newPin) {
                await _changePin(pin.toUpperCase());
              } else {
                setState(() {
                  _hasError = true;
                  _errorMessage = 'thisIsNotAGoodCode'.tr();
                  _pinColor = Colors.red;
                });
                _confirmTextController.clear();
                _confirmFocusNode.requestFocus();
              }
            },
            onChanged: (value) {
              if (_hasError && value.isNotEmpty) {
                setState(() {
                  _hasError = false;
                  _pinColor = const Color(0xFFA4B600);
                });
              }
            },
          ),
        if (_isConfirmStep && !_isProcessing) ...[
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _isConfirmStep = false;
                _newPin = '';
                _hasError = false;
                _pinTextController.clear();
                _confirmTextController.clear();
                _pinColor = const Color(0xFFA4B600);
              });
              WidgetsBinding.instance.addPostFrameCallback((_) => _pinFocusNode.requestFocus());
            },
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: Text(MaterialLocalizations.of(context).backButtonTooltip),
          ),
        ],
      ],
    );
  }

  Future<void> _changePin(String pin) async {
    setState(() => _isProcessing = true);

    try {
      final firstWallet = ref.read(firstWalletProvider);
      if (firstWallet == null) return;

      await ref.read(walletServiceProvider).changePin(address: firstWallet.address, oldPin: widget.oldPin, newPin: pin);

      PinCodeService.pinCode = pin;
      PinCodeService.setAuthenticatedSafe(ref.read(walletServiceProvider).defaultSafeBoxNumber);

      // Re-enroll biometric if enabled
      final biometricState = ref.read(biometricProvider);
      if (biometricState.isEnrolledForCurrentSafe) {
        try {
          final walletService = ref.read(walletServiceProvider);
          await walletService.disableBiometric();
          await walletService.enableBiometric(pin: pin);
        } catch (e) {
          log.e('Failed to re-enroll biometric after PIN change: $e');
        }
      }

      final currentSafe = ref.read(currentSafeNumberProvider);
      await ref.read(walletsListProvider.notifier).loadWallets(safeBoxNumber: currentSafe);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      log.e('Failed to change PIN: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _hasError = true;
          _errorMessage = 'changePinError'.tr();
        });
      }
    }
  }
}
