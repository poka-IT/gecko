import 'dart:async';

import 'package:durt2/durt2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/stream_providers.dart';

import 'package:gecko/main.dart';
import 'package:gecko/screens/license_page.dart';
import 'package:gecko/widgets/desktop/modals/transaction_progress_modal.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/widgets/bottom_sheets/mnemonic_challenge_sheet.dart';
import 'package:gecko/widgets/commons/async_elevated_button.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/widgets/commons/shimmer_placeholder.dart';
import 'package:gecko/widgets/commons/responsive_center.dart';
import 'package:gecko/widgets/commons/wallet_app_bar.dart';

class ConfirmIdentityScreen extends ConsumerStatefulWidget {
  const ConfirmIdentityScreen({super.key, required this.address, this.embeddedMode = false});
  final String address;
  final bool embeddedMode;

  @override
  ConsumerState<ConfirmIdentityScreen> createState() => _ConfirmIdentityScreenState();
}

class _ConfirmIdentityScreenState extends ConsumerState<ConfirmIdentityScreen> {
  final TextEditingController _identityNameController = TextEditingController();
  final PageController _pageController = PageController();
  final FocusNode _usernameFocusNode = FocusNode();
  bool _canValidate = false;
  bool _singleIdentityCommitment = false;
  bool _isValidating = false;
  String _errorMessage = '';
  Timer? _debounceTimer;
  int _currentPage = 0;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _identityNameController.dispose();
    _pageController.dispose();
    _usernameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _validateIdentityName() async {
    final name = _identityNameController.text.trim();

    // Check basic validation criteria first
    final hasNoSpaces = !name.contains(' ');
    final isLengthValid = name.length >= 3 && name.length <= 32;

    if (mounted) setState(() => _isValidating = true);

    // Try to check if identity exists via Squid, but handle errors gracefully
    bool idtyExist = false;
    bool squidAvailable = false;

    try {
      // Check if Squid is connected first
      final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
      squidAvailable = squidConnectionStatus == ConnectionStatus.connected;

      if (squidAvailable) {
        idtyExist = await SquidService.client.isIdtyExist(name);
      }
    } catch (e) {
      // If Squid check fails, log the error but continue in degraded mode
      log.w('Identity name validation failed due to Squid unavailability: $e');
      squidAvailable = false;
      idtyExist = false;
    }

    // In degraded mode (no Squid), only validate format
    final isValid = !idtyExist && hasNoSpaces && isLengthValid;

    if (!mounted) return;

    setState(() {
      _isValidating = false;
      _canValidate = isValid;
      if (idtyExist) {
        _errorMessage = 'thisIdentityAlreadyExist'.tr();
      } else if (!hasNoSpaces) {
        _errorMessage = 'identityNameNoSpaces'.tr();
      } else if (name.length < 3) {
        _errorMessage = 'identityNameTooShort'.tr();
      } else if (name.length > 32) {
        _errorMessage = 'identityNameTooLong'.tr();
      } else {
        // Show warning if in degraded mode but validation is otherwise valid
        if (!squidAvailable && isLengthValid && hasNoSpaces) {
          _errorMessage = 'squidUnavailableIdentityValidationLimited'.tr();
        } else {
          _errorMessage = '';
        }
      }
    });
  }

  Future<void> _confirmIdentity(BuildContext context) async {
    final name = _identityNameController.text.trim();
    final navigatorState = Navigator.of(context);

    // Afficher le dialogue de confirmation
    final confirmed = await showConfirmationDialog(
      context: context,
      type: ConfirmationDialogType.info,
      message: 'confirmIdentityNameChoice'.tr(args: [name]),
    );

    if (confirmed != true) return;

    // Authenticate and capture the PIN locally in one call. The PIN must
    // survive the mnemonic challenge (several seconds of user interaction)
    // which comes next — see askPinCodeAndCapture for rationale.
    if (!context.mounted) return;
    final capturedPin = await PinCodeService.askPinCodeAndCapture(
      context,
      wallet: ref.read(walletServiceProvider).getWalletData(widget.address),
    );
    if (capturedPin == null) return;

    if (!context.mounted) return;
    if (!await showMnemonicChallenge(context: context, ref: ref, address: widget.address, pinCode: capturedPin)) {
      return;
    }

    final DurtKeyPair keypair;
    try {
      keypair = await ref
          .read(walletServiceProvider)
          .getKeyPairFromAddress(address: widget.address, pinCode: capturedPin);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('incorrectPinCode'.tr()), backgroundColor: context.geckoColors.danger));
      return;
    }
    final transactionStatus = ref.read(duniterServiceProvider).confirmIdentity(keypair: keypair, name: name);

    // Convert to broadcast stream to allow multiple listeners
    final broadcastStream = transactionStatus.asBroadcastStream();

    // Listen to transaction stream to invalidate providers on success
    // Use mounted check to avoid using ref after widget disposal
    final invalidateSubscription = broadcastStream.listen((status) {
      if ((status.state == TransactionState.finalized || status.state == TransactionState.inBlock) && mounted) {
        // Invalidate identity-related providers to refresh cache
        ref.invalidate(hybridIdtyStatusProvider(widget.address));
        // Also update the squid service cache
        ref.read(squidServiceProvider).walletNameIndexer[widget.address] = name;
      }
    });

    if (!mounted) return;
    navigatorState.pop();

    try {
      await navigateToTransactionProgress(
        widget.embeddedMode ? Gecko.navigatorContext! : navigatorState.context,
        transactionStatus: broadcastStream,
        transType: 'comfirmIdty',
        fromAddress: widget.address,
        toAddress: widget.address,
      );
    } finally {
      await invalidateSubscription.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    final body = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: [_buildPage1(context, isSmallScreen), _buildPage2(context, isSmallScreen)],
            ),
          ),
          _buildBottomSection(context, isSmallScreen),
        ],
      ),
    );

    if (widget.embeddedMode) {
      return Center(child: body);
    }

    return Scaffold(
      appBar: WalletAppBar(address: widget.address, title: 'chooseIdentityName'.tr()),
      body: ResponsiveCenter(maxWidth: 500, padding: EdgeInsets.zero, child: body),
    );
  }

  /// Page 1: Explanatory content + license link
  Widget _buildPage1(BuildContext context, bool isSmallScreen) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(scaleSize(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Center(
              child: Container(
                width: scaleSize(isSmallScreen ? 60 : 80),
                height: scaleSize(isSmallScreen ? 60 : 80),
                decoration: BoxDecoration(
                  color: context.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline,
                  size: scaleSize(isSmallScreen ? 30 : 40),
                  color: context.colorScheme.primary,
                ),
              ),
            ),
            ScaledSizedBox(height: isSmallScreen ? 16 : 32),

            // Main title
            Text(
              'identityInDuniterNetwork'.tr(args: [Durt.i.network.symbol]),
              style: scaledTextStyle(fontSize: isSmallScreen ? 20 : 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            ScaledSizedBox(height: isSmallScreen ? 16 : 24),

            // Explanatory text
            Text('identityExplanation'.tr(), style: scaledTextStyle(fontSize: isSmallScreen ? 14 : 16)),
            ScaledSizedBox(height: isSmallScreen ? 16 : 24),

            // Important points
            ...['identityNameUnique'.tr(), 'identityNameSearchable'.tr(), 'identityNamePermanent'.tr()].map(
              (text) => Padding(
                padding: EdgeInsets.only(bottom: scaleSize(isSmallScreen ? 8 : 12)),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: context.colorScheme.primary,
                      size: scaleSize(isSmallScreen ? 16 : 20),
                    ),
                    ScaledSizedBox(width: isSmallScreen ? 8 : 12),
                    Expanded(
                      child: Text(text, style: scaledTextStyle(fontSize: isSmallScreen ? 14 : 16)),
                    ),
                  ],
                ),
              ),
            ),
            ScaledSizedBox(height: isSmallScreen ? 24 : 32),
          ],
        ),
      ),
    );
  }

  /// Page 2: Username input + commitment checkbox
  Widget _buildPage2(BuildContext context, bool isSmallScreen) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(scaleSize(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScaledSizedBox(height: isSmallScreen ? 8 : 16),

            // Identity name input field
            TextField(
              key: keyEnterIdentityUsername,
              controller: _identityNameController,
              focusNode: _usernameFocusNode,
              onChanged: (_) {
                _debounceTimer?.cancel();
                setState(() => _isValidating = true);
                _debounceTimer = Timer(const Duration(milliseconds: 400), () {
                  _validateIdentityName();
                });
              },
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (_canValidate && _singleIdentityCommitment) {
                  _confirmIdentity(context);
                }
              },
              inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'^ '))],
              decoration: InputDecoration(
                hintText: 'enterIdentityName'.tr(),
                errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
                errorStyle: scaledTextStyle(color: context.geckoColors.danger),
                filled: true,
                fillColor: context.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
                suffixIcon: _isValidating
                    ? Padding(
                        padding: EdgeInsets.only(right: scaleSize(12)),
                        child: ShimmerPlaceholder(width: scaleSize(40), height: scaleSize(16)),
                      )
                    : null,
                suffixIconConstraints: BoxConstraints(maxHeight: scaleSize(24), maxWidth: scaleSize(52)),
              ),
              style: scaledTextStyle(fontSize: isSmallScreen ? 14 : 16),
            ),
            ScaledSizedBox(height: isSmallScreen ? 16 : 24),

            // Commitment checkbox
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _singleIdentityCommitment = !_singleIdentityCommitment),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: scaleSize(8)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: scaleSize(24),
                      height: scaleSize(24),
                      child: Checkbox(
                        value: _singleIdentityCommitment,
                        onChanged: (value) => setState(() => _singleIdentityCommitment = value ?? false),
                        activeColor: context.colorScheme.primary,
                      ),
                    ),
                    ScaledSizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'commitSingleIdentity'.tr(),
                        style: scaledTextStyle(fontSize: isSmallScreen ? 14 : 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// License link widget (same style as currency_page.dart)
  Widget _buildLicenseLink(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MonetaryLicensePage())),
        child: Ink(
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colorScheme.primary.withValues(alpha: 0.2)),
          ),
          padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(14)),
          child: Row(
            children: [
              Icon(Icons.article_outlined, color: context.colorScheme.primary, size: scaleSize(22)),
              ScaledSizedBox(width: 12),
              Expanded(
                child: Text(
                  'readMonetaryLicense'.tr(),
                  style: scaledTextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: context.colorScheme.primary),
                ),
              ),
              Icon(Icons.chevron_right, color: context.colorScheme.primary, size: scaleSize(22)),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom section with page indicator and action button
  Widget _buildBottomSection(BuildContext context, bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        border: Border(top: BorderSide(color: context.colorScheme.outline.withValues(alpha: 0.2), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.all(scaleSize(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Page indicator dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(2, (index) {
                  final isActive = index == _currentPage;
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: scaleSize(4)),
                    width: scaleSize(isActive ? 10 : 8),
                    height: scaleSize(isActive ? 10 : 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? context.colorScheme.primary
                          : context.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  );
                }),
              ),
              ScaledSizedBox(height: 16),

              // Action button
              if (_currentPage == 0) ...[
                _buildLicenseLink(context),
                ScaledSizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: scaleSize(isSmallScreen ? 44 : 50),
                  child: ElevatedButton(
                    onPressed: () {
                      _pageController.animateToPage(
                        1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                      Future.delayed(const Duration(milliseconds: 350), () {
                        if (mounted) _usernameFocusNode.requestFocus();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colorScheme.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'continue'.tr(),
                      style: scaledTextStyle(fontSize: isSmallScreen ? 14 : 16, color: Colors.white),
                    ),
                  ),
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  height: scaleSize(isSmallScreen ? 44 : 50),
                  child: AsyncElevatedButton(
                    key: keyConfirm,
                    onPressed: _canValidate && _singleIdentityCommitment ? () => _confirmIdentity(context) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colorScheme.primary,
                      disabledBackgroundColor: Colors.grey[300],
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'validate'.tr(),
                      style: scaledTextStyle(fontSize: isSmallScreen ? 14 : 16, color: Colors.white),
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
