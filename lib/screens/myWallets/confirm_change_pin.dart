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
import 'package:gecko/widgets/pin/gecko_pin_entry.dart';

class ConfirmChangePinScreen extends ConsumerStatefulWidget {
  const ConfirmChangePinScreen({super.key, required this.walletName, required this.newPinCode, required this.oldPin});

  final String walletName;
  final String newPinCode;
  final String oldPin;

  @override
  ConsumerState<ConfirmChangePinScreen> createState() => _ConfirmChangePinScreenState();
}

class _ConfirmChangePinScreenState extends ConsumerState<ConfirmChangePinScreen> {
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
              if (hasError) ...[
                const SizedBox(height: 20),
                Text(
                  "thisIsNotAGoodCode".tr(),
                  style: TextStyle(color: context.geckoColors.danger, fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GeckoPinEntry(
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
    if (pin == widget.newPinCode) {
      _pinController.triggerSuccess();

      final firstWallet = ref.read(firstWalletProvider);
      if (firstWallet == null) return;

      try {
        await ref
            .read(walletServiceProvider)
            .changePin(address: firstWallet.address, oldPin: widget.oldPin, newPin: pin);
      } catch (e) {
        log.e('Failed to change PIN: $e');
        if (!mounted) return;
        _pinController.triggerError();
        setState(() => hasError = true);
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('changePinError'.tr()), backgroundColor: context.geckoColors.danger));
        return;
      }

      PinCodeService.cachePin(pin);
      PinCodeService.setAuthenticatedSafe(ref.read(walletServiceProvider).defaultSafeBoxNumber);

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

      final currentSafe = ref.read(currentSafeNumberProvider);
      await ref.read(walletsListProvider.notifier).loadWallets(safeBoxNumber: currentSafe);

      if (!mounted) return;
      Navigator.of(context)
        ..pop()
        ..pop();
    } else {
      _pinController.triggerError();
    }
  }
}
