// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' as d;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/biometric_provider.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/wallet_generation_providers.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/screens/onBoarding/9.dart' show isPinComplex;
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/widgets/desktop/desktop_modal.dart';
import 'package:gecko/widgets/gecko_pin_field.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

/// Opens the desktop restore modal for restoring a wallet from mnemonic.
///
/// 3 steps: Mnemonic entry → PIN creation → PIN confirmation + safe creation
Future<bool?> showDesktopRestoreModal(BuildContext context) {
  return showDesktopModal<bool>(
    context: context,
    size: DesktopModalSize.medium,
    barrierDismissible: false,
    showCloseButton: false,
    contentPadding: EdgeInsets.zero,
    builder: (context) => const _RestoreModalContent(),
  );
}

class _RestoreModalContent extends ConsumerStatefulWidget {
  const _RestoreModalContent();

  @override
  ConsumerState<_RestoreModalContent> createState() => _RestoreModalContentState();
}

class _RestoreModalContentState extends ConsumerState<_RestoreModalContent> {
  int _currentStep = 0;
  static const _totalSteps = 3;

  // Mnemonic
  final List<TextEditingController> _wordControllers = List.generate(12, (_) => TextEditingController());
  final List<FocusNode> _wordFocusNodes = List.generate(12, (i) => FocusNode(debugLabel: 'word_$i'));
  bool _mnemonicValid = false;

  // PIN
  String _pinCode = '';
  bool _pinConfirmed = false;
  bool _pinError = false;
  String _pinErrorMessage = '';
  bool _isProcessing = false;
  late FocusNode _pinFocusNode;
  late TextEditingController _pinTextController;
  late PinInputController _pinController;
  late FocusNode _confirmPinFocusNode;
  late TextEditingController _confirmPinTextController;
  late PinInputController _confirmPinController;

  @override
  void initState() {
    super.initState();
    _pinFocusNode = FocusNode(debugLabel: 'restore_pin');
    _pinTextController = TextEditingController();
    _pinController = PinInputController(textController: _pinTextController, focusNode: _pinFocusNode);
    _confirmPinFocusNode = FocusNode(debugLabel: 'restore_confirm_pin');
    _confirmPinTextController = TextEditingController();
    _confirmPinController = PinInputController(
      textController: _confirmPinTextController,
      focusNode: _confirmPinFocusNode,
    );
    for (final c in _wordControllers) {
      c.addListener(_checkMnemonic);
    }
  }

  @override
  void dispose() {
    for (final c in _wordControllers) {
      c.dispose();
    }
    for (final f in _wordFocusNodes) {
      f.dispose();
    }
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  String get _mnemonicString => _wordControllers.map((c) => c.text.trim().toLowerCase()).join(' ');

  void _checkMnemonic() {
    final allFilled = _wordControllers.every((c) => c.text.trim().isNotEmpty);
    if (allFilled != _mnemonicValid) {
      setState(() => _mnemonicValid = allFilled);
    }
  }

  Future<void> _pasteMnemonic() async {
    final success = await ref.read(pasteMnemonicProvider)();
    if (success) {
      // Read words from the provider controllers and fill ours
      final providerControllers = ref.read(mnemonicControllersProvider);
      for (int i = 0; i < 12 && i < providerControllers.length; i++) {
        _wordControllers[i].text = providerControllers[i].text;
      }
    }
  }

  Future<void> _validateAndProceed() async {
    try {
      // Validate mnemonic
      await ref.read(mnemonicStateProvider.notifier).setMnemonic(_mnemonicString);
      setState(() => _currentStep = 1);
    } catch (e) {
      if (context.mounted) {
        await showConfirmationDialog(
          context: context,
          type: ConfirmationDialogType.error,
          title: 'error'.tr(),
          message: 'thisIsNotAValidMnemonic'.tr(),
          hideCancelButton: true,
        );
      }
    }
  }

  Future<void> _handlePinConfirmed() async {
    setState(() => _isProcessing = true);

    try {
      final connectionStatus = ref.read(connectionStatusProvider);
      if (connectionStatus != d.ConnectionStatus.connected) {
        if (context.mounted) {
          await showConfirmationDialog(
            context: context,
            barrierDismissible: false,
            title: 'onboardingOfflineTitle'.tr(),
            message: 'onboardingOfflineMessage'.tr(),
            confirmText: 'close'.tr(),
            hideCancelButton: true,
          );
        }
        setState(() => _isProcessing = false);
        return;
      }

      // Create safe from mnemonic
      final mnemonic = ref.read(mnemonicStateProvider).mnemonicResult?.displayMnemonic ?? _mnemonicString;
      try {
        await ref
            .read(walletServiceProvider)
            .createSafe(mnemonic: mnemonic, pinCode: _pinCode, safeName: 'safeBoxName'.tr());
      } catch (e) {
        if (!e.toString().contains('already exists') && !e.toString().contains('detect source language')) {
          rethrow;
        }
      }

      // Sync providers
      ref.read(defaultSafeBoxNumberProvider.notifier).refresh();
      await ref.read(biometricProvider.notifier).refresh();
      final currentSafe = ref.read(walletServiceProvider).defaultSafeBoxNumber;

      // Scan derivations for existing wallets
      final mnemonicState = ref.read(mnemonicStateProvider);
      if (mnemonicState.mnemonicResult != null) {
        final scanStatus = await ref.read(startScanProvider)(context, mnemonicState.mnemonicResult!);
        if (scanStatus == ScanDerivationsResult.timeout || scanStatus == ScanDerivationsResult.error) {
          // Fallback: import root wallet
          await ref.read(walletServiceProvider).importRootWallet(pinCode: _pinCode);
        }
      } else {
        await ref.read(walletServiceProvider).importRootWallet(pinCode: _pinCode);
      }

      // Load wallets
      await ref.read(walletsListProvider.notifier).loadWallets(safeBoxNumber: currentSafe);
      ref.read(walletActionsProvider.notifier).invalidateProviders();
      ref.invalidate(idtyWalletAsyncProvider);
      ref.invalidate(identityWalletsAsyncProvider);

      // Select default wallet
      d.WalletEntity? defaultWallet;
      try {
        defaultWallet = await ref.read(idtyWalletAsyncProvider.future);
      } catch (_) {}
      final walletsList = ref.read(walletsListProvider).wallets;
      defaultWallet ??= walletsList.firstWhereOrNull((w) => w.number == 0);
      if (defaultWallet == null && walletsList.isNotEmpty) {
        defaultWallet = walletsList.first;
      }
      if (defaultWallet != null) {
        await ref.read(walletServiceProvider).setDefaultAddress(defaultWallet.address);
      }

      // Clear sensitive state
      ref.read(resetMnemonicStateProvider)();
      PinCodeService.debounceResetPinCode();

      // Final reload
      final finalSafe = ref.read(walletServiceProvider).defaultSafeBoxNumber;
      ref.read(defaultSafeBoxNumberProvider.notifier).refresh();
      await ref.read(walletsListProvider.notifier).loadWallets(safeBoxNumber: finalSafe);

      if (mounted) {
        setState(() => _isProcessing = false);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      log.e('Error during desktop restore: $e');
      ref.read(resetMnemonicStateProvider)();
      if (mounted) {
        setState(() => _isProcessing = false);
        await showConfirmationDialog(
          context: context,
          type: ConfirmationDialogType.error,
          title: 'error'.tr(),
          message: 'errorScanDerivations'.tr(),
          hideCancelButton: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context),
        _buildProgressBar(context),
        Flexible(child: _isProcessing ? _buildProcessingOverlay(context) : _buildCurrentStep(context)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final titles = ['restoreASafe'.tr(), 'myPassword'.tr(), 'allGood'.tr()];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titles[_currentStep],
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: context.colorScheme.onSurface),
            ),
          ),
          if (!_isProcessing)
            IconButton(
              onPressed: () {
                ref.read(clearMnemonicInputProvider)();
                Navigator.of(context).pop(false);
              },
              icon: Icon(Icons.close_rounded, color: context.colorScheme.onSurface.withValues(alpha: 0.6)),
              splashRadius: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 4 : 0),
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isActive ? context.colorScheme.primary : context.colorScheme.onSurface.withValues(alpha: 0.12),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return _buildMnemonicEntry(context);
      case 1:
        return _buildPinStep(context);
      case 2:
        return _buildCongratsStep(context);
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Step 0: Mnemonic entry ───

  Widget _buildMnemonicEntry(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'toRestoreEnterMnemonic'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: context.colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: List.generate(12, (index) {
                  return SizedBox(
                    width: 120,
                    height: 44,
                    child: TextField(
                      controller: _wordControllers[index],
                      focusNode: _wordFocusNodes[index],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: '${index + 1}',
                        labelStyle: TextStyle(fontSize: 12, color: context.colorScheme.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        filled: true,
                        fillColor: context.colorScheme.surfaceContainer,
                      ),
                      textInputAction: index < 11 ? TextInputAction.next : TextInputAction.done,
                      onSubmitted: (_) {
                        if (index < 11) {
                          _wordFocusNodes[index + 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _pasteMnemonic,
                icon: const Icon(Icons.content_paste_go_rounded, size: 18),
                label: Text('pasteFromClipboard'.tr()),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _mnemonicValid ? _validateAndProceed : null,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24)),
                child: Text('restoreThisSafe'.tr(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Step 1: PIN creation + confirmation ───

  Widget _buildPinStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            !_pinConfirmed ? 'hereIsThePasswordKeepIt'.tr() : 'geckoWillCheckPassword'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: context.colorScheme.onSurface),
          ),
          if (_pinError)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _pinErrorMessage,
                style: const TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.w500),
              ),
            ),
          const SizedBox(height: 24),
          if (!_pinConfirmed)
            GeckoPinField(
              pinController: _pinController,
              length: pinLength,
              onChanged: (value) {
                if (_pinError && value.isNotEmpty) setState(() => _pinError = false);
              },
              onCompleted: (pin) {
                if (isPinComplex(pin)) {
                  setState(() {
                    _pinCode = pin.toUpperCase();
                    _pinConfirmed = true;
                    _pinError = false;
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) => _confirmPinFocusNode.requestFocus());
                } else {
                  setState(() {
                    _pinError = true;
                    _pinErrorMessage = 'passwordTooSimple'.tr();
                  });
                  _pinTextController.clear();
                  _pinFocusNode.requestFocus();
                }
              },
            )
          else
            GeckoPinField(
              pinController: _confirmPinController,
              length: _pinCode.isEmpty ? pinLength : _pinCode.length,
              onChanged: (value) {
                if (_pinError && value.isNotEmpty) setState(() => _pinError = false);
              },
              onCompleted: (pin) async {
                if (pin.toUpperCase() == _pinCode) {
                  PinCodeService.pinCode = pin.toUpperCase();
                  await _handlePinConfirmed();
                } else {
                  setState(() {
                    _pinError = true;
                    _pinErrorMessage = 'thisIsNotAGoodCode'.tr();
                  });
                  _confirmPinTextController.clear();
                  _confirmPinFocusNode.requestFocus();
                }
              },
            ),
          const Spacer(),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  if (_pinConfirmed) {
                    setState(() {
                      _pinConfirmed = false;
                      _pinCode = '';
                      _pinError = false;
                      _pinTextController.clear();
                      _confirmPinTextController.clear();
                    });
                  } else {
                    setState(() => _currentStep = 0);
                  }
                },
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text(MaterialLocalizations.of(context).backButtonTooltip),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingOverlay(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: context.colorScheme.primary, strokeWidth: 3),
          const SizedBox(height: 24),
          Text('creatingSafe'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'creatingSafePleaseWait'.tr(),
            style: TextStyle(fontSize: 14, color: context.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Congrats ───

  Widget _buildCongratsStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Icon(Icons.celebration_rounded, size: 64, color: context.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            'allGood'.tr(),
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: context.colorScheme.onSurface),
          ),
          const SizedBox(height: 12),
          Text(
            'yourSafeAndWalletWereRestoredSuccessfully'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: context.colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text('accessMySafe'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
