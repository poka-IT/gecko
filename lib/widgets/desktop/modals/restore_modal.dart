import 'package:durt2/durt2.dart' as d;
import 'package:durt2/durt2.dart' show BidouilleLang, Durt;
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
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/widgets/commons/text_markdown.dart';
import 'package:gecko/services/snackbar_service.dart';
import 'package:gecko/widgets/desktop/desktop_congrats_step.dart';
import 'package:gecko/widgets/desktop/desktop_modal.dart';
import 'package:gecko/widgets/pin/gecko_pin_entry.dart';

/// Opens the desktop restore modal for restoring a wallet from mnemonic.
///
/// 3 steps: Mnemonic entry -> PIN creation -> PIN confirmation + safe creation
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

  // PIN
  String _pinCode = '';
  bool _pinConfirmed = false;
  bool _pinError = false;
  String _pinErrorMessage = '';
  bool _isProcessing = false;
  bool _biometricSetupAttempted = false;
  int _validationGeneration = 0;
  late GeckoPinEntryController _pinController;
  late GeckoPinEntryController _confirmPinController;

  @override
  void initState() {
    super.initState();
    _pinController = GeckoPinEntryController();
    _confirmPinController = GeckoPinEntryController();
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

  Future<void> _pasteMnemonic() async {
    final success = await ref.read(pasteMnemonicProvider)();
    if (success) {
      // Read words from the provider controllers and fill ours
      final providerControllers = ref.read(mnemonicControllersProvider);
      final words = <String>[];
      for (int i = 0; i < 12 && i < providerControllers.length; i++) {
        _wordControllers[i].text = providerControllers[i].text;
        words.add(providerControllers[i].text.trim().toLowerCase());
      }
      // Validate via mnemonicInputProvider
      await ref.read(mnemonicInputProvider.notifier).fillWords(words);
    }
  }

  Future<void> _validateAndProceed() async {
    await ref.read(mnemonicStateProvider.notifier).setMnemonic(_mnemonicString);
    final mnemonicState = ref.read(mnemonicStateProvider);

    if (mnemonicState.mnemonicResult == null) {
      if (context.mounted) {
        if (!mounted) return;
        await showConfirmationDialog(
          context: context,
          type: ConfirmationDialogType.error,
          title: 'error'.tr(),
          message: 'thisIsNotAValidMnemonic'.tr(),
          hideCancelButton: true,
        );
      }
      return;
    }

    setState(() => _currentStep = 1);
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
      PinCodeService.setAuthenticatedSafe(currentSafe);

      // Scan derivations for existing wallets (use service directly to avoid
      // navigator side effects from the provider's error/timeout handlers)
      final mnemonicState = ref.read(mnemonicStateProvider);
      if (mnemonicState.mnemonicResult != null) {
        final scanResult = await ref
            .read(walletScanServiceProvider)
            .scanDerivations(
              mnemonicResult: mnemonicState.mnemonicResult!,
              onStatusChanged: (_) {},
              onWalletCountChanged: (_) {},
            );
        if (!scanResult.hasWallets) {
          // No on-chain wallets found, or timeout/error: import root wallet
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
        setState(() {
          _isProcessing = false;
          _currentStep = 2;
        });
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
    final mnemonicInput = ref.watch(mnemonicInputProvider);

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
                  final isWordValid = mnemonicInput.wordValidations[index] ?? true;
                  final suggestion = mnemonicInput.wordSuggestions[index];

                  return SizedBox(
                    width: 120,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 44,
                          child: TextField(
                            controller: _wordControllers[index],
                            focusNode: _wordFocusNodes[index],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: isWordValid ? context.colorScheme.onSurface : context.geckoColors.danger,
                            ),
                            decoration: InputDecoration(
                              labelText: '${index + 1}',
                              labelStyle: TextStyle(fontSize: 12, color: context.colorScheme.primary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              filled: true,
                              fillColor: context.colorScheme.surfaceContainer,
                            ),
                            textInputAction: TextInputAction.none,
                            onSubmitted: (_) {
                              if (index < 11) {
                                _wordFocusNodes[index + 1].requestFocus();
                              }
                            },
                            onChanged: (value) async {
                              final cleanText = value.trim().toLowerCase();

                              // Update validation via provider
                              await ref.read(mnemonicInputProvider.notifier).updateWord(index, cleanText);

                              // Auto-advance: if word uniquely identifies a BIP39 word, move to next
                              if (cleanText.isNotEmpty && index < 11) {
                                // Track this validation call to discard stale results
                                final thisGeneration = ++_validationGeneration;
                                try {
                                  // ignore: use_build_context_synchronously
                                  final languageCode = context.locale.languageCode;
                                  final preferredLanguage = BidouilleLang.fromLanguageCode(languageCode);
                                  final isUnique = await Durt.i.wallets.multilangService.isValidWordInAnyLanguage(
                                    cleanText,
                                    checkRedundance: true,
                                    preferredLanguage: preferredLanguage,
                                  );
                                  // Only advance if this is still the latest validation AND this field still has focus
                                  if (isUnique &&
                                      thisGeneration == _validationGeneration &&
                                      _wordFocusNodes[index].hasFocus) {
                                    _wordFocusNodes[index + 1].requestFocus();
                                  }
                                } catch (_) {}
                              }
                            },
                          ),
                        ),
                        // Show suggestion for invalid words
                        if (suggestion != null)
                          GestureDetector(
                            onTap: () {
                              _wordControllers[index].text = suggestion;
                              ref.read(mnemonicInputProvider.notifier).updateWord(index, suggestion);
                              if (index < 11) {
                                _wordFocusNodes[index + 1].requestFocus();
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                suggestion,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
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
                onPressed: mnemonicInput.isValid ? _validateAndProceed : null,
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
          TextMarkDown(
            !_pinConfirmed ? 'hereIsThePasswordKeepIt'.tr() : 'geckoWillCheckPassword'.tr(),
            style: TextStyle(fontSize: 15, color: context.colorScheme.onSurface),
            textAlign: WrapAlignment.center,
          ),
          if (_pinError)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _pinErrorMessage,
                style: TextStyle(fontSize: 14, color: context.geckoColors.danger, fontWeight: FontWeight.w500),
              ),
            ),
          const SizedBox(height: 24),
          if (!_pinConfirmed)
            GeckoPinEntry(
              controller: _pinController,
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
                } else {
                  setState(() {
                    _pinError = true;
                    _pinErrorMessage = 'passwordTooSimple'.tr();
                  });
                  _pinController.triggerError();
                }
              },
            )
          else
            GeckoPinEntry(
              controller: _confirmPinController,
              length: _pinCode.isEmpty ? pinLength : _pinCode.length,
              onChanged: (value) {
                if (_pinError && value.isNotEmpty) setState(() => _pinError = false);
              },
              onCompleted: (pin) async {
                if (pin.toUpperCase() == _pinCode) {
                  PinCodeService.cachePin(pin.toUpperCase());
                  await _handlePinConfirmed();
                } else {
                  setState(() {
                    _pinError = true;
                    _pinErrorMessage = 'thisIsNotAGoodCode'.tr();
                  });
                  _confirmPinController.triggerError();
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
                    });
                    _pinController.clear();
                    _confirmPinController.clear();
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
    _triggerBiometricSetup(context);

    return DesktopCongratsStep(
      message: 'yourSafeAndWalletWereRestoredSuccessfully'.tr(),
      buttonLabel: 'accessMySafe'.tr(),
      onButtonPressed: () => Navigator.of(context).pop(true),
    );
  }

  void _triggerBiometricSetup(BuildContext context) {
    if (_pinCode.isEmpty || _biometricSetupAttempted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final biometricNotifier = ref.read(biometricProvider.notifier);
      await biometricNotifier.waitForInitialization();
      final biometricState = ref.read(biometricProvider);
      if (biometricState.canEnroll && !_biometricSetupAttempted && mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted && !_biometricSetupAttempted) {
          // ignore: use_build_context_synchronously
          _handleBiometricSetup(context);
        }
      }
    });
  }

  Future<void> _handleBiometricSetup(BuildContext context) async {
    try {
      _biometricSetupAttempted = true;
      final shouldSetup = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        constraints: const BoxConstraints(maxWidth: 600),
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.fingerprint, color: context.colorScheme.primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'setupBiometric'.tr(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: context.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'wouldYouLikeToSetupBiometricAuth'.tr(),
                    style: TextStyle(fontSize: 16, color: context.colorScheme.onSurface.withValues(alpha: 0.8)),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'setupBiometric'.tr(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'skip'.tr(),
                        style: TextStyle(fontSize: 16, color: context.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (shouldSetup == true && context.mounted) {
        await _setupBiometricAuthentication(context);
      }
    } catch (e) {
      log.e('Error setting up biometric during restore: $e');
    }
  }

  Future<void> _setupBiometricAuthentication(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('settingUpBiometric'.tr()),
                ],
              ),
            ),
          ),
        ),
      );

      final biometricNotifier = ref.read(biometricProvider.notifier);
      final result = await biometricNotifier.enrollBiometric(_pinCode);

      if (context.mounted) {
        Navigator.pop(context);
        if (result.success) {
          SnackbarService.showSuccess(context, message: 'biometricSetupSuccessful'.tr());
        } else {
          SnackbarService.showError(context, message: 'biometricSetupFailed'.tr());
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        SnackbarService.showError(context, message: 'Error: $e');
      }
    }
  }
}
