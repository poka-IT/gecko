// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' as d;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
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
import 'package:gecko/services/snackbar_service.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/widgets/commons/mnemonic_display.dart';
import 'package:gecko/widgets/desktop/desktop_modal.dart';
import 'package:gecko/widgets/gecko_pin_field.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

/// Opens the desktop onboarding modal for creating a new wallet.
///
/// Condenses the 11-step mobile onboarding into 5 desktop steps:
/// 1. Introduction (info summary)
/// 2. Mnemonic generation
/// 3. Mnemonic verification
/// 4. PIN creation + confirmation
/// 5. Congratulations
Future<bool?> showDesktopOnboardingModal(BuildContext context) {
  return showDesktopModal<bool>(
    context: context,
    size: DesktopModalSize.large,
    barrierDismissible: false,
    showCloseButton: false,
    contentPadding: EdgeInsets.zero,
    builder: (context) => const _OnboardingModalContent(),
  );
}

class _OnboardingModalContent extends ConsumerStatefulWidget {
  const _OnboardingModalContent();

  @override
  ConsumerState<_OnboardingModalContent> createState() => _OnboardingModalContentState();
}

class _OnboardingModalContentState extends ConsumerState<_OnboardingModalContent> {
  int _currentStep = 0;
  static const _totalSteps = 5;

  // Mnemonic state
  List<String>? _mnemonicWords;
  bool _mnemonicLoading = false;

  // Word challenge state
  int? _challengeWordIndex;
  String? _challengeExpectedWord;
  bool _wordVerified = false;
  final _wordController = TextEditingController();

  // PIN state
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
    _pinFocusNode = FocusNode(debugLabel: 'desktop_onboarding_pin');
    _pinTextController = TextEditingController();
    _pinController = PinInputController(textController: _pinTextController, focusNode: _pinFocusNode);
    _confirmPinFocusNode = FocusNode(debugLabel: 'desktop_onboarding_confirm_pin');
    _confirmPinTextController = TextEditingController();
    _confirmPinController = PinInputController(
      textController: _confirmPinTextController,
      focusNode: _confirmPinFocusNode,
    );
  }

  @override
  void dispose() {
    _wordController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  // ─── Navigation ───

  void _next() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  // ─── Mnemonic generation ───

  Future<void> _generateMnemonic() async {
    setState(() => _mnemonicLoading = true);
    try {
      final languageCode = context.locale.languageCode;
      final targetLanguage = d.BidouilleLang.fromLanguageCode(languageCode);
      await ref
          .read(mnemonicStateProvider.notifier)
          .generateMnemonic(
            targetLanguage: targetLanguage,
            forceEnglish: configBox.get('generateMnemonicsInEnglish') ?? false,
          );
      final state = ref.read(mnemonicStateProvider);
      if (mounted && state.mnemonicResult != null) {
        setState(() {
          _mnemonicWords = state.mnemonicResult!.displayWords;
          _mnemonicLoading = false;
          _setupWordChallenge();
        });
      }
    } catch (e) {
      log.e('Error generating mnemonic: $e');
      if (mounted) setState(() => _mnemonicLoading = false);
    }
  }

  void _setupWordChallenge() {
    if (_mnemonicWords == null || _mnemonicWords!.isEmpty) return;
    final challenge = ref.read(wordValidationChallengeProvider);
    if (challenge != null) {
      _challengeWordIndex = challenge.wordIndex;
      _challengeExpectedWord = challenge.expectedWord;
    }
  }

  // ─── PIN + Safe creation ───

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

      // Create safe
      await _createSafe();

      // Sync providers
      ref.read(defaultSafeBoxNumberProvider.notifier).refresh();
      await ref.read(biometricProvider.notifier).refresh();
      final currentSafe = ref.read(walletServiceProvider).defaultSafeBoxNumber;

      // Import root wallet
      await ref.read(walletServiceProvider).importRootWallet(pinCode: _pinCode);

      // Load wallets
      await ref.read(walletsListProvider.notifier).loadWallets(safeBoxNumber: currentSafe);
      ref.read(walletActionsProvider.notifier).invalidateProviders();
      ref.invalidate(idtyWalletAsyncProvider);
      ref.invalidate(identityWalletsAsyncProvider);

      // Select default wallet
      final defaultWallet = await _selectDefaultWallet();
      if (defaultWallet != null) {
        await ref.read(walletServiceProvider).setDefaultAddress(defaultWallet.address);
      }

      // Clear sensitive state
      ref.read(resetMnemonicStateProvider)();
      PinCodeService.debounceResetPinCode();

      // Final reload
      final currentSafeNumber = ref.read(walletServiceProvider).defaultSafeBoxNumber;
      ref.read(defaultSafeBoxNumberProvider.notifier).refresh();
      await ref.read(walletsListProvider.notifier).loadWallets(safeBoxNumber: currentSafeNumber);

      // Move to congratulations step
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _currentStep = _totalSteps - 1;
        });
      }
    } catch (e) {
      log.e('Error during desktop onboarding safe setup: $e');
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

  Future<void> _createSafe() async {
    final originalMnemonic = ref.read(mnemonicStateProvider).mnemonicResult?.displayMnemonic ?? '';
    if (originalMnemonic.isEmpty) return;

    try {
      await ref
          .read(walletServiceProvider)
          .createSafe(mnemonic: originalMnemonic, pinCode: _pinCode, safeName: 'safeBoxName'.tr());
    } catch (e) {
      if (!e.toString().contains('already exists') && !e.toString().contains('detect source language')) {
        rethrow;
      }
      log.i('Safe already exists - continuing with existing safe');
    }
  }

  Future<d.WalletEntity?> _selectDefaultWallet() async {
    d.WalletEntity? defaultWallet;
    try {
      defaultWallet = await ref.read(idtyWalletAsyncProvider.future);
    } catch (e) {
      log.w('Error getting identity wallet: $e');
    }
    final walletsList = ref.read(walletsListProvider).wallets;
    defaultWallet ??= walletsList.firstWhereOrNull((w) => w.number == 0);
    if (defaultWallet == null && walletsList.isNotEmpty) {
      defaultWallet = walletsList.first;
    }
    return defaultWallet;
  }

  // ─── Build ───

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
    final titles = ['info'.tr(), 'yourMnemonic'.tr(), 'yourMnemonic'.tr(), 'myPassword'.tr(), 'allGood'.tr()];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titles[_currentStep],
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: context.colorScheme.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_currentStep < _totalSteps - 1 && !_isProcessing)
            IconButton(
              onPressed: () => Navigator.of(context).pop(false),
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
        return _buildIntroStep(context);
      case 1:
        return _buildMnemonicStep(context);
      case 2:
        return _buildVerificationStep(context);
      case 3:
        return _buildPinStep(context);
      case 4:
        return _buildCongratsStep(context);
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Step 0: Introduction ───

  Widget _buildIntroStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildInfoCard(
                    context,
                    icon: Icons.vpn_key_rounded,
                    title: 'geckoGenerateYourWalletFromMnemonic'.tr(),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(context, icon: Icons.shield_rounded, title: 'keepThisMnemonicSecure'.tr()),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    context,
                    icon: Icons.warning_amber_rounded,
                    title: 'warningForgotPassword'.tr(),
                    isWarning: true,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(context, icon: Icons.edit_note_rounded, title: 'itsTimeToUseAPenAndPaper'.tr()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                _generateMnemonic();
                _next();
              },
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text('continue'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required IconData icon, required String title, bool isWarning = false}) {
    final color = isWarning ? const Color(0xFFFF9800) : context.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title, style: TextStyle(fontSize: 14, height: 1.5, color: context.colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }

  // ─── Step 1: Mnemonic Generation ───

  Widget _buildMnemonicStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'geckoGeneratedYourMnemonicKeepItSecret'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: context.colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _mnemonicWords != null
                ? SingleChildScrollView(
                    child: Column(
                      children: [
                        MnemonicDisplayWidget(mnemonicWords: _mnemonicWords!, isLoading: _mnemonicLoading),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                final mnemonic = ref.read(mnemonicStateProvider).mnemonicResult?.displayMnemonic;
                                if (mnemonic != null) {
                                  SnackbarService.copyMnemonicToClipboard(context, mnemonic);
                                }
                              },
                              icon: const Icon(Icons.copy_rounded, size: 18),
                              label: Text('copy'.tr()),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: _regenerateMnemonic,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: Text('chooseAnotherMnemonic'.tr()),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton.icon(
                onPressed: _back,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text(MaterialLocalizations.of(context).backButtonTooltip),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _mnemonicWords != null
                    ? () {
                        // Store mnemonic for safe creation
                        final mnemonicState = ref.read(mnemonicStateProvider);
                        if (mnemonicState.mnemonicResult != null) {
                          ref
                              .read(derivationStateProvider.notifier)
                              .setMnemonic(mnemonicState.mnemonicResult!.displayMnemonic);
                        }
                        _setupWordChallenge();
                        _wordController.clear();
                        setState(() => _wordVerified = false);
                        _next();
                      }
                    : null,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24)),
                child: Text('iNotedMyMnemonic'.tr(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _regenerateMnemonic() async {
    setState(() => _mnemonicLoading = true);
    await _generateMnemonic();
  }

  // ─── Step 2: Mnemonic Verification ───

  Widget _buildVerificationStep(BuildContext context) {
    if (_challengeWordIndex == null || _challengeExpectedWord == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            'didYouNoteMnemonicToBeSureTypeWord'.tr(args: [(_challengeWordIndex! + 1).toString()]),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: context.colorScheme.onSurface),
          ),
          const SizedBox(height: 12),
          Text(
            '${_challengeWordIndex! + 1}',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: context.colorScheme.primary),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: TextField(
              controller: _wordController,
              autofocus: true,
              enabled: !_wordVerified,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: _wordVerified ? Colors.green[700] : context.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                labelText: _wordVerified ? 'itsTheGoodWord'.tr() : 'nthMnemonicWord'.tr(),
                labelStyle: TextStyle(color: _wordVerified ? Colors.green : Colors.grey[500]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: context.colorScheme.surfaceContainer,
              ),
              onChanged: (value) {
                final trimmed = value.trim().toLowerCase();
                final expected = _challengeExpectedWord!.trim().toLowerCase();
                final isValid = trimmed == expected || (kDebugMode && trimmed == 'triche');
                if (isValid != _wordVerified) {
                  setState(() => _wordVerified = isValid);
                }
              },
            ),
          ),
          const Spacer(),
          Row(
            children: [
              TextButton.icon(
                onPressed: _back,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text(MaterialLocalizations.of(context).backButtonTooltip),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _wordVerified
                    ? () {
                        ref.read(wordChallengeProvider.notifier).reset();
                        _next();
                      }
                    : null,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24)),
                child: Text('continue'.tr(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Step 3: PIN Creation + Confirmation ───

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
          const SizedBox(height: 12),
          Text(
            !_pinConfirmed ? 'myPassword'.tr() : 'geckoWillCheckPassword'.tr(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          if (!_pinConfirmed) _buildPinEntry(context) else _buildPinConfirmation(context),
          const Spacer(),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  if (_pinConfirmed) {
                    // Go back to PIN entry
                    setState(() {
                      _pinConfirmed = false;
                      _pinCode = '';
                      _pinError = false;
                      _pinTextController.clear();
                      _confirmPinTextController.clear();
                    });
                  } else {
                    _back();
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

  Widget _buildPinEntry(BuildContext context) {
    return GeckoPinField(
      pinController: _pinController,
      length: pinLength,
      onChanged: (value) {
        if (_pinError && value.isNotEmpty) {
          setState(() => _pinError = false);
        }
      },
      onCompleted: (pin) {
        if (isPinComplex(pin)) {
          setState(() {
            _pinCode = pin.toUpperCase();
            _pinConfirmed = true;
            _pinError = false;
          });
          // Focus the confirmation field after build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _confirmPinFocusNode.requestFocus();
          });
        } else {
          setState(() {
            _pinError = true;
            _pinErrorMessage = 'passwordTooSimple'.tr();
          });
          _pinTextController.clear();
          _pinFocusNode.requestFocus();
        }
      },
    );
  }

  Widget _buildPinConfirmation(BuildContext context) {
    return GeckoPinField(
      pinController: _confirmPinController,
      length: _pinCode.isEmpty ? pinLength : _pinCode.length,
      onChanged: (value) {
        if (_pinError && value.isNotEmpty) {
          setState(() => _pinError = false);
        }
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
    );
  }

  // ─── Processing overlay ───

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

  // ─── Step 4: Congratulations ───

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
            'yourSafeAndWalletWereCreatedSuccessfully'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: context.colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text('accessMySafe'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
