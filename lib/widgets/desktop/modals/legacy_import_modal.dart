import 'dart:async';

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
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/screens/onBoarding/9.dart' show isPinComplex;
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/services/wallet_name_service.dart';
import 'package:gecko/widgets/balance_display.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/widgets/commons/text_markdown.dart';
import 'package:gecko/widgets/desktop/desktop_congrats_step.dart';
import 'package:gecko/widgets/desktop/desktop_modal.dart';
import 'package:gecko/widgets/gecko_pin_field.dart';
import 'package:gecko/utils.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

/// Opens the desktop legacy import modal for importing a Cesium v1 wallet.
///
/// 3 steps: Credentials entry → PIN creation + confirmation → Done
Future<bool?> showDesktopLegacyImportModal(BuildContext context) {
  return showDesktopModal<bool>(
    context: context,
    size: DesktopModalSize.medium,
    barrierDismissible: false,
    showCloseButton: false,
    contentPadding: EdgeInsets.zero,
    builder: (context) => const _LegacyImportModalContent(),
  );
}

class _LegacyImportModalContent extends ConsumerStatefulWidget {
  const _LegacyImportModalContent();

  @override
  ConsumerState<_LegacyImportModalContent> createState() => _LegacyImportModalContentState();
}

class _LegacyImportModalContentState extends ConsumerState<_LegacyImportModalContent> {
  int _currentStep = 0;
  static const _totalSteps = 3;

  // Credentials
  final _saltController = TextEditingController();
  final _passwordController = TextEditingController();
  Timer? _debounce;
  d.CsToV2AddressResult? _addressResult;
  d.WalletBalance? _walletBalance;
  d.IdtyStatus? _idtyStatus;
  String? _identityName;
  bool _isLoadingAddress = false;
  bool _isSaltVisible = false;
  bool _isPasswordVisible = false;

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
    _pinFocusNode = FocusNode(debugLabel: 'legacy_pin');
    _pinTextController = TextEditingController();
    _pinController = PinInputController(textController: _pinTextController, focusNode: _pinFocusNode);
    _confirmPinFocusNode = FocusNode(debugLabel: 'legacy_confirm_pin');
    _confirmPinTextController = TextEditingController();
    _confirmPinController = PinInputController(
      textController: _confirmPinTextController,
      focusNode: _confirmPinFocusNode,
    );
  }

  @override
  void dispose() {
    _saltController.dispose();
    _passwordController.dispose();
    _debounce?.cancel();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  bool get _canImport =>
      _addressResult != null && _walletBalance != null && _walletBalance!.transferableBalance > BigInt.zero;

  void _onCredentialsChanged() {
    _debounce?.cancel();
    setState(() {
      _addressResult = null;
      _walletBalance = null;
      _idtyStatus = null;
      _identityName = null;
    });
    _debounce = Timer(const Duration(milliseconds: 2000), () {
      if (_saltController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
        _computeAddresses();
      }
    });
  }

  Future<void> _computeAddresses() async {
    if (_saltController.text.isEmpty || _passwordController.text.isEmpty) return;
    setState(() => _isLoadingAddress = true);

    try {
      final result = await d.Utils().csToV2Address(_saltController.text, _passwordController.text);
      final balance = await ref.read(storageServiceProvider).getBalance(result.address);
      final idtyStatus = await ref.read(storageServiceProvider).getIdtyStatus(result.address);
      String? identityName;
      if (idtyStatus != d.IdtyStatus.none && idtyStatus != d.IdtyStatus.unknown) {
        identityName = ref.read(squidServiceProvider).walletNameIndexer[result.address];
      }
      setState(() {
        _addressResult = result;
        _walletBalance = balance;
        _idtyStatus = idtyStatus;
        _identityName = identityName;
        _isLoadingAddress = false;
      });
    } catch (e) {
      log.e('Error computing addresses: $e');
      setState(() => _isLoadingAddress = false);
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

      // Import legacy wallet
      try {
        await ref
            .read(walletServiceProvider)
            .importLegacyWallet(
              salt: _saltController.text,
              password: _passwordController.text,
              pinCode: _pinCode,
              name: WalletNameService.defaultLegacy(),
            );
      } catch (e) {
        if (!e.toString().contains('already been imported')) rethrow;
      }

      // Sync providers
      ref.read(defaultSafeBoxNumberProvider.notifier).refresh();
      await ref.read(biometricProvider.notifier).refresh();
      final currentSafe = ref.read(walletServiceProvider).defaultSafeBoxNumber;
      PinCodeService.setAuthenticatedSafe(currentSafe);

      // Load wallets
      await ref.read(walletsListProvider.notifier).loadWallets(safeBoxNumber: currentSafe);
      ref.read(walletActionsProvider.notifier).invalidateProviders();
      ref.invalidate(idtyWalletAsyncProvider);
      ref.invalidate(identityWalletsAsyncProvider);

      PinCodeService.debounceResetPinCode();

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _currentStep = _totalSteps - 1;
        });
      }
    } catch (e) {
      log.e('Error during legacy import: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        await showConfirmationDialog(
          context: context,
          type: ConfirmationDialogType.error,
          title: 'error'.tr(),
          message: e.toString(),
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
    final titles = ['importLegacyAccount'.tr(), 'myPassword'.tr(), 'allGood'.tr()];
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
        return _buildCredentialsStep(context);
      case 1:
        return _buildPinStep(context);
      case 2:
        return _buildCongratsStep(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProcessingOverlay(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: context.colorScheme.primary, strokeWidth: 3),
          const SizedBox(height: 24),
          Text('creatingSafe'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ─── Step 0: Credentials ───

  Widget _buildCredentialsStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Warning banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.geckoColors.warningContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.geckoColors.warning.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: context.geckoColors.warning, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'importLegacyDescription'.tr(),
                    style: TextStyle(fontSize: 13, color: context.colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Salt field
          TextField(
            controller: _saltController,
            obscureText: !_isSaltVisible,
            onChanged: (_) => _onCredentialsChanged(),
            decoration: InputDecoration(
              labelText: 'cesiumIdentifier'.tr(),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.person_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(_isSaltVisible ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _isSaltVisible = !_isSaltVisible),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Password field
          TextField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            onChanged: (_) => _onCredentialsChanged(),
            decoration: InputDecoration(
              labelText: 'cesiumPassword'.tr(),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Account preview
          Expanded(child: _buildAccountPreview(context)),
          const SizedBox(height: 16),
          // Import button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _canImport ? () => setState(() => _currentStep = 1) : null,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text('importAccount'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountPreview(BuildContext context) {
    if (_isLoadingAddress) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_addressResult == null) {
      return Center(
        child: Text(
          'importLegacyDescription'.tr(),
          style: TextStyle(color: context.colorScheme.onSurface.withValues(alpha: 0.4)),
        ),
      );
    }

    final colorScheme = context.colorScheme;

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Identity name + status
            if (_identityName != null ||
                (_idtyStatus != null && _idtyStatus != d.IdtyStatus.none && _idtyStatus != d.IdtyStatus.unknown))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    if (_identityName != null)
                      Expanded(
                        child: Text(
                          _identityName!,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                        ),
                      ),
                    if (_idtyStatus != null && _idtyStatus != d.IdtyStatus.none && _idtyStatus != d.IdtyStatus.unknown)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _idtyStatusColor(_idtyStatus!, context).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _idtyStatus.toString().split('.').last,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _idtyStatusColor(_idtyStatus!, context),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            // Balance
            if (_walletBalance != null) ...[
              BalanceDisplay(
                value: _walletBalance!.transferableBalance,
                size: 22,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 14),
            ],
            // V1 Public Key
            _buildCopyableAddress(
              context,
              label: 'v1PublicKey'.tr(),
              value: _addressResult!.pubkey,
              shortValue: getShortPubkey(_addressResult!.pubkey),
            ),
            const SizedBox(height: 10),
            // V2 Address
            _buildCopyableAddress(
              context,
              label: 'v2Address'.tr(),
              value: _addressResult!.address,
              shortValue: getShortPubkey(_addressResult!.address),
              highlighted: true,
            ),
            // V2 info banner
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: colorScheme.primary.withValues(alpha: 0.7)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'v2AddressInfo'.tr(),
                        style: TextStyle(fontSize: 11.5, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Warning if no balance
            if (_walletBalance != null && _walletBalance!.transferableBalance == BigInt.zero) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.geckoColors.warningContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.geckoColors.warning.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 16, color: context.geckoColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'noWalletFound'.tr(),
                        style: TextStyle(fontSize: 13, color: context.geckoColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCopyableAddress(
    BuildContext context, {
    required String label,
    required String value,
    required String shortValue,
    bool highlighted = false,
  }) {
    final colorScheme = context.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$label — ${'copied'.tr()}'), duration: const Duration(seconds: 2)));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: highlighted
                ? colorScheme.primary.withValues(alpha: 0.06)
                : colorScheme.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      shortValue,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.copy_rounded, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.35)),
            ],
          ),
        ),
      ),
    );
  }

  Color _idtyStatusColor(d.IdtyStatus status, BuildContext context) {
    final colors = context.geckoColors;
    return switch (status) {
      d.IdtyStatus.validated => colors.statusMember,
      d.IdtyStatus.confirmed => colors.statusConfirmed,
      d.IdtyStatus.created => colors.statusCreated,
      d.IdtyStatus.expired => colors.statusExpired,
      d.IdtyStatus.revoked => colors.statusRevoked,
      _ => colors.statusNone,
    };
  }

  // ─── Step 1: PIN ───

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

  // ─── Step 2: Congrats ───

  Widget _buildCongratsStep(BuildContext context) {
    return DesktopCongratsStep(
      message: 'yourSafeAndWalletWereCreatedSuccessfully'.tr(),
      buttonLabel: 'accessMyWallet'.tr(),
      onButtonPressed: () => Navigator.of(context).pop(true),
    );
  }
}
