import 'package:durt2/durt2.dart' as d;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/biometric_provider.dart';
import 'package:gecko/services/config_service.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/wallet_generation_providers.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/services/snackbar_service.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/widgets/commons/text_markdown.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gecko/widgets/commons/mnemonic_display.dart';
import 'package:gecko/widgets/desktop/desktop_congrats_step.dart';
import 'package:gecko/widgets/desktop/desktop_modal.dart';
import 'package:gecko/widgets/pin/gecko_pin_entry.dart';

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
  bool _hasAcceptedIntro = false;
  bool _biometricSetupAttempted = false;

  // Mnemonic state
  List<String>? _mnemonicWords;
  bool _mnemonicLoading = false;

  // Word challenge state
  int? _challengeWordIndex;
  String? _challengeExpectedWord;
  bool _wordVerified = false;
  final _wordController = TextEditingController();
  late FocusNode _wordFocusNode;

  // PIN state
  String _pinCode = '';
  bool _pinConfirmed = false;
  bool _pinError = false;
  String _pinErrorMessage = '';
  bool _isProcessing = false;
  late GeckoPinEntryController _pinController;
  late GeckoPinEntryController _confirmPinController;

  @override
  void initState() {
    super.initState();
    _wordFocusNode = FocusNode(debugLabel: 'desktop_onboarding_word');
    _pinController = GeckoPinEntryController();
    _confirmPinController = GeckoPinEntryController();
  }

  @override
  void dispose() {
    _wordController.dispose();
    _wordFocusNode.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  // ─── Navigation ───

  void _next() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _autoFocusCurrentStep();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _autoFocusCurrentStep();
    }
  }

  void _autoFocusCurrentStep() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (_currentStep) {
        case 2: // Word verification step
          _wordFocusNode.requestFocus();
          break;
      }
    });
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
            forceEnglish: ref.read(configServiceProvider).generateMnemonicsInEnglish,
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
      PinCodeService.setAuthenticatedSafe(currentSafe);

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
                  const SizedBox(height: 20),
                  // Checkbox confirmation
                  GestureDetector(
                    onTap: () => setState(() => _hasAcceptedIntro = !_hasAcceptedIntro),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: _hasAcceptedIntro
                              ? context.colorScheme.primary.withValues(alpha: 0.08)
                              : context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _hasAcceptedIntro
                                ? context.colorScheme.primary.withValues(alpha: 0.4)
                                : context.colorScheme.outline.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _hasAcceptedIntro ? context.colorScheme.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: _hasAcceptedIntro
                                      ? context.colorScheme.primary
                                      : context.colorScheme.onSurface.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: _hasAcceptedIntro
                                  ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'iUnderstandTheImportanceOfMnemonic'.tr(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.colorScheme.onSurface.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _hasAcceptedIntro
                  ? () {
                      _generateMnemonic();
                      _next();
                    }
                  : null,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text('continue'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required IconData icon, required String title, bool isWarning = false}) {
    final color = isWarning ? context.geckoColors.warning : context.colorScheme.primary;
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
            child: TextMarkDown(
              title,
              style: TextStyle(fontSize: 14, height: 1.5, color: context.colorScheme.onSurface),
              textAlign: WrapAlignment.start,
              markdownStyle: MarkdownStyleSheet(
                p: TextStyle(fontSize: 14, height: 1.5, color: context.colorScheme.onSurface),
                strong: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: context.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: WrapAlignment.start,
              ),
            ),
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
          TextMarkDown(
            'didYouNoteMnemonicToBeSureTypeWord'.tr(args: [(_challengeWordIndex! + 1).toString()]),
            style: TextStyle(fontSize: 15, color: context.colorScheme.onSurface),
            textAlign: WrapAlignment.center,
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
              focusNode: _wordFocusNode,
              autofocus: true,
              enabled: !_wordVerified,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: _wordVerified ? context.geckoColors.successText : context.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                labelText: _wordVerified ? 'itsTheGoodWord'.tr() : 'nthMnemonicWord'.tr(),
                labelStyle: TextStyle(color: _wordVerified ? context.geckoColors.success : Colors.grey[500]),
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
          const SizedBox(height: 12),
          if (!_pinConfirmed)
            Text(
              'myPassword'.tr(),
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
                    });
                    _pinController.clear();
                    _confirmPinController.clear();
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
    return GeckoPinEntry(
      controller: _pinController,
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
        } else {
          setState(() {
            _pinError = true;
            _pinErrorMessage = 'passwordTooSimple'.tr();
          });
          _pinController.triggerError();
        }
      },
    );
  }

  Widget _buildPinConfirmation(BuildContext context) {
    return GeckoPinEntry(
      controller: _confirmPinController,
      length: _pinCode.isEmpty ? pinLength : _pinCode.length,
      onChanged: (value) {
        if (_pinError && value.isNotEmpty) {
          setState(() => _pinError = false);
        }
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
    _triggerBiometricSetup(context);

    return DesktopCongratsStep(
      message: 'yourSafeAndWalletWereCreatedSuccessfully'.tr(),
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.fingerprint, color: context.colorScheme.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'setupBiometric'.tr(),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: context.colorScheme.onSurface),
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
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('setupNow'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.colorScheme.outline),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('skip'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 8),
            ],
          ),
        ),
      );

      if (shouldSetup == true && context.mounted) {
        await _setupBiometricAuthentication(context);
      }
    } catch (e) {
      log.e('Error setting up biometric during onboarding: $e');
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
        SnackbarService.showError(context, message: 'anErrorOccurred'.tr());
      }
    }
  }
}
