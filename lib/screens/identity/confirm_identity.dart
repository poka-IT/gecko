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
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/stream_providers.dart';

import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/widgets/bottom_sheets/mnemonic_challenge_sheet.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/widgets/commons/wallet_app_bar.dart';

class ConfirmIdentityScreen extends ConsumerStatefulWidget {
  const ConfirmIdentityScreen({super.key, required this.address});
  final String address;

  @override
  ConsumerState<ConfirmIdentityScreen> createState() => _ConfirmIdentityScreenState();
}

class _ConfirmIdentityScreenState extends ConsumerState<ConfirmIdentityScreen> {
  final TextEditingController _identityNameController = TextEditingController();
  bool _canValidate = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _identityNameController.dispose();
    super.dispose();
  }

  Future<void> _validateIdentityName() async {
    final name = _identityNameController.text.trim();

    // Check basic validation criteria first
    final hasNoSpaces = !name.contains(' ');
    final isLengthValid = name.length >= 3 && name.length <= 32;

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

    setState(() {
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

    if (!await PinCodeService.askPinCode()) return;

    if (!await showMnemonicChallenge(context: context, ref: ref, address: widget.address)) return;

    final keypair = await ref
        .read(walletServiceProvider)
        .getKeyPairFromAddress(address: widget.address, pinCode: PinCodeService.pinCode);
    final transactionStatus = ref.read(duniterServiceProvider).confirmIdentity(keypair: keypair, name: name);

    // Convert to broadcast stream to allow multiple listeners
    final broadcastStream = transactionStatus.asBroadcastStream();

    // Listen to transaction stream to invalidate providers on success
    // Use mounted check to avoid using ref after widget disposal
    broadcastStream.listen((status) {
      if ((status.state == TransactionState.finalized || status.state == TransactionState.inBlock) && mounted) {
        // Invalidate identity-related providers to refresh cache
        ref.invalidate(identityNameProvider(widget.address));
        ref.invalidate(hybridIdtyStatusProvider(widget.address));
        // Also update the squid service cache
        ref.read(squidServiceProvider).walletNameIndexer[widget.address] = name;
      }
    });

    if (!mounted) return;
    navigatorState.pop();

    navigatorState.push(
      MaterialPageRoute(
        builder: (context) => TransactionInProgressScreen(
          transactionStatus: broadcastStream,
          transType: 'comfirmIdty',
          fromAddress: widget.address,
          toAddress: widget.address,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    return Scaffold(
      appBar: WalletAppBar(address: widget.address, title: 'chooseIdentityName'.tr()),
      body: Column(
        children: [
          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
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
                    // Add extra bottom padding to ensure content doesn't get cut off
                    ScaledSizedBox(height: isSmallScreen ? 24 : 32),
                  ],
                ),
              ),
            ),
          ),

          // Fixed input section at bottom
          Container(
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
                    // Identity name input field
                    TextField(
                      key: keyEnterIdentityUsername,
                      controller: _identityNameController,
                      onChanged: (_) => _validateIdentityName(),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (_canValidate) {
                          _confirmIdentity(context);
                        }
                      },
                      inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'^ '))],
                      decoration: InputDecoration(
                        hintText: 'enterIdentityName'.tr(),
                        errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
                        errorStyle: scaledTextStyle(color: Colors.red),
                        filled: true,
                        fillColor: context.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
                      ),
                      style: scaledTextStyle(fontSize: isSmallScreen ? 14 : 16),
                    ),
                    ScaledSizedBox(height: 16),

                    // Validate button
                    SizedBox(
                      width: double.infinity,
                      height: scaleSize(isSmallScreen ? 44 : 50),
                      child: ElevatedButton(
                        key: keyConfirm,
                        onPressed: _canValidate ? () => _confirmIdentity(context) : null,
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
          ),
        ],
      ),
    );
  }
}
