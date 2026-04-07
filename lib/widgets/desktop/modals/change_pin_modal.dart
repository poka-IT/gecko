import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/biometric_provider.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/widgets/desktop/desktop_modal.dart';
import 'package:gecko/widgets/pin/gecko_pin_entry.dart';

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
  late GeckoPinEntryController _pinController;
  late GeckoPinEntryController _confirmController;

  String _newPin = '';
  bool _isConfirmStep = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _pinController = GeckoPinEntryController();
    _confirmController = GeckoPinEntryController();
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
              style: TextStyle(color: context.geckoColors.danger, fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
        if (_isProcessing)
          const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: CircularProgressIndicator())
        else if (!_isConfirmStep)
          GeckoPinEntry(
            controller: _pinController,
            length: pinLength,
            onCompleted: (pin) {
              if (isPinComplex(pin)) {
                setState(() {
                  _newPin = pin.toUpperCase();
                  _isConfirmStep = true;
                  _hasError = false;
                });
              } else {
                setState(() {
                  _hasError = true;
                  _errorMessage = 'passwordTooSimple'.tr();
                });
                _pinController.triggerError();
              }
            },
            onChanged: (value) {
              if (_hasError && value.isNotEmpty) setState(() => _hasError = false);
            },
          )
        else
          GeckoPinEntry(
            controller: _confirmController,
            length: _newPin.length,
            onCompleted: (pin) async {
              if (pin.toUpperCase() == _newPin) {
                await _changePin(pin.toUpperCase());
              } else {
                setState(() {
                  _hasError = true;
                  _errorMessage = 'thisIsNotAGoodCode'.tr();
                });
                _confirmController.triggerError();
              }
            },
            onChanged: (value) {
              if (_hasError && value.isNotEmpty) setState(() => _hasError = false);
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
              });
              _pinController.clear();
              _confirmController.clear();
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

      PinCodeService.cachePin(pin);
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
