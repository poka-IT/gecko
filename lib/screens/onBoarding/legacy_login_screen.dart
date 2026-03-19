import 'dart:async';
import 'package:durt2/durt2.dart' show CsToV2AddressResult, Utils, IdtyStatus, WalletBalance;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/screens/onBoarding/9.dart';
import 'package:gecko/services/snackbar_service.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/commons/responsive_center.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/widgets/balance_display.dart';
import 'package:gecko/widgets/certifications.dart';

/// Screen for importing legacy Cesium wallets with salt/password
class LegacyLoginScreen extends ConsumerStatefulWidget {
  const LegacyLoginScreen({super.key});

  static const int debounceTime = 2000;

  @override
  ConsumerState<LegacyLoginScreen> createState() => _LegacyLoginScreenState();
}

class _LegacyLoginScreenState extends ConsumerState<LegacyLoginScreen> {
  final _saltController = TextEditingController();
  final _passwordController = TextEditingController();

  Timer? _debounce;
  CsToV2AddressResult? _addressResult;
  WalletBalance? _walletBalance;
  IdtyStatus? _idtyStatus;
  String? _identityName;
  bool _isLoading = false;
  bool _isSaltVisible = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _saltController.dispose();
    _passwordController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onCredentialsChanged() {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    setState(() {
      _addressResult = null;
      _walletBalance = null;
      _idtyStatus = null;
      _identityName = null;
    });

    _debounce = Timer(const Duration(milliseconds: LegacyLoginScreen.debounceTime), () {
      if (_saltController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
        _computeAddresses();
      }
    });
  }

  Future<void> _computeAddresses() async {
    if (_saltController.text.isEmpty || _passwordController.text.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final utils = Utils();
      final result = await utils.csToV2Address(_saltController.text, _passwordController.text);

      // Get balance and identity information
      final balance = await ref.read(storageServiceProvider).getBalance(result.address);
      final idtyStatus = await ref.read(storageServiceProvider).getIdtyStatus(result.address);
      String? identityName;

      // Get identity name from squid indexer if available
      if (idtyStatus != IdtyStatus.none && idtyStatus != IdtyStatus.unknown) {
        identityName = ref.read(squidServiceProvider).walletNameIndexer[result.address];
      }

      setState(() {
        _addressResult = result;
        _walletBalance = balance;
        _idtyStatus = idtyStatus;
        _identityName = identityName;
        _isLoading = false;
      });
    } catch (e) {
      log.e('Error computing addresses: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _importWallet() async {
    if (_addressResult == null || _walletBalance == null || _walletBalance!.transferableBalance == BigInt.zero) return;

    // Navigate to PIN creation with legacy credentials
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) => OnboardingStepNine(
          scanDerivation: false,
          fromRestore: true,
          legacySalt: _saltController.text,
          legacyPassword: _passwordController.text,
        ),
      ),
    );

    if (result == null) return;

    // The legacy wallet creation is handled by the onboarding flow
    // No need to do anything here, the flow will continue automatically
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: GeckoAppBar('legacyLoginTitle'.tr()),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 500,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(scaleSize(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info card - only show when no valid wallet is detected
                      if (!(_addressResult != null &&
                          _walletBalance != null &&
                          _walletBalance!.transferableBalance > BigInt.zero)) ...[
                        Card(
                          color: context.geckoColors.warning.withValues(alpha: 0.1),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: context.geckoColors.warning, width: 1),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(scaleSize(16)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.warning_amber, color: context.geckoColors.warning, size: scaleSize(24)),
                                ScaledSizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'legacyLoginWarning'.tr(),
                                        style: scaledTextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: context.geckoColors.warningText,
                                        ),
                                      ),
                                      ScaledSizedBox(height: 8),
                                      Text(
                                        'legacyLoginInfo'.tr(),
                                        style: scaledTextStyle(fontSize: 13, color: context.colorScheme.onSurface),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ScaledSizedBox(height: 24),
                      ],

                      // Cesium credentials section
                      Card(
                        color: context.colorScheme.surfaceContainer,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: EdgeInsets.all(scaleSize(16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.login, color: context.colorScheme.primary, size: scaleSize(24)),
                                  ScaledSizedBox(width: 12),
                                  Text(
                                    'cesiumCredentials'.tr(),
                                    style: scaledTextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: context.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              ScaledSizedBox(height: 16),

                              // Salt field
                              TextFormField(
                                controller: _saltController,
                                autofocus: true,
                                autocorrect: false,
                                onChanged: (_) => _onCredentialsChanged(),
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.next,
                                obscureText: !_isSaltVisible,
                                style: scaledTextStyle(fontSize: 14, color: context.colorScheme.onSurface),
                                decoration: InputDecoration(
                                  labelText: 'cesiumIdentifier'.tr(),
                                  hintText: 'enterCesiumId'.tr(),
                                  hintStyle: scaledTextStyle(fontSize: 13),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isSaltVisible ? Icons.visibility_off : Icons.visibility,
                                      color: context.colorScheme.onSurfaceVariant,
                                      size: scaleSize(20),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isSaltVisible = !_isSaltVisible;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              ScaledSizedBox(height: 16),

                              // Password field
                              TextFormField(
                                controller: _passwordController,
                                autocorrect: false,
                                onChanged: (_) => _onCredentialsChanged(),
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.done,
                                obscureText: !_isPasswordVisible,
                                style: scaledTextStyle(fontSize: 14, color: context.colorScheme.onSurface),
                                decoration: InputDecoration(
                                  labelText: 'cesiumPassword'.tr(),
                                  hintText: 'enterCesiumPassword'.tr(),
                                  hintStyle: scaledTextStyle(fontSize: 13),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                      color: context.colorScheme.onSurfaceVariant,
                                      size: scaleSize(20),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Address display section
                      if (_isLoading || _addressResult != null) ...[
                        ScaledSizedBox(height: 24),
                        Card(
                          color: context.colorScheme.surfaceContainer,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: EdgeInsets.all(scaleSize(16)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet,
                                      color: context.colorScheme.primary,
                                      size: scaleSize(24),
                                    ),
                                    ScaledSizedBox(width: 12),
                                    Text(
                                      'accountInformation'.tr(),
                                      style: scaledTextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: context.colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                ScaledSizedBox(height: 16),

                                if (_isLoading)
                                  Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(context.colorScheme.primary),
                                    ),
                                  )
                                else if (_addressResult != null) ...[
                                  // Check if account exists (has balance)
                                  if (_walletBalance != null && _walletBalance!.transferableBalance == BigInt.zero) ...[
                                    // Account doesn't exist
                                    Container(
                                      padding: EdgeInsets.all(scaleSize(12)),
                                      decoration: BoxDecoration(
                                        color: context.geckoColors.danger.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: context.geckoColors.danger.withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: context.geckoColors.danger,
                                            size: scaleSize(20),
                                          ),
                                          ScaledSizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'accountNotFound'.tr(),
                                              style: scaledTextStyle(
                                                fontSize: 13,
                                                color: context.geckoColors.dangerText,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    // Account exists - show full information
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Balance et informations d'identité
                                        if (_idtyStatus != null && _idtyStatus != IdtyStatus.none) ...[
                                          // CAS AVEC IDENTITÉ : 2 colonnes parfaitement alignées
                                          Table(
                                            columnWidths: const {0: FlexColumnWidth(1), 1: IntrinsicColumnWidth()},
                                            children: [
                                              // ROW 1 : Nom d'identité + Balance
                                              TableRow(
                                                children: [
                                                  // Nom d'identité (ou espace vide si pas de nom)
                                                  Padding(
                                                    padding: EdgeInsets.only(bottom: scaleSize(8)),
                                                    child: _identityName != null
                                                        ? Text(
                                                            _identityName!,
                                                            style: scaledTextStyle(
                                                              fontSize: 15,
                                                              fontWeight: FontWeight.w600,
                                                              color: context.colorScheme.onSurface,
                                                            ),
                                                          )
                                                        : const SizedBox(),
                                                  ),
                                                  // Balance
                                                  Align(
                                                    alignment: Alignment.centerRight,
                                                    child: Padding(
                                                      padding: EdgeInsets.only(bottom: scaleSize(8)),
                                                      child: BalanceDisplay(
                                                        value: _walletBalance?.transferableBalance ?? BigInt.zero,
                                                        size: 16,
                                                        fontWeight: FontWeight.w600,
                                                        color: context.colorScheme.onSurface,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              // ROW 2 : Badge de statut + Certifications
                                              TableRow(
                                                children: [
                                                  // Badge de statut
                                                  Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: _buildStatusBadge(context, _idtyStatus!),
                                                  ),
                                                  // Certifications
                                                  Align(
                                                    alignment: Alignment.centerRight,
                                                    child: Certifications(address: _addressResult!.address, size: 12),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ] else ...[
                                          // CAS SANS IDENTITÉ : Balance centrée
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              BalanceDisplay(
                                                value: _walletBalance?.transferableBalance ?? BigInt.zero,
                                                size: 16,
                                                fontWeight: FontWeight.w600,
                                                color: context.colorScheme.onSurface,
                                              ),
                                            ],
                                          ),
                                          ScaledSizedBox(height: 8),
                                        ],

                                        ScaledSizedBox(height: 16),

                                        // Address information section
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // V1 Public Key
                                            _buildAddressRow(
                                              context: context,
                                              label: 'v1PublicKey'.tr(),
                                              value: _addressResult!.pubkey,
                                              onTap: () {
                                                Clipboard.setData(ClipboardData(text: _addressResult!.pubkey));
                                                SnackbarService.showAddressCopied(context);
                                              },
                                            ),
                                            ScaledSizedBox(height: 12),

                                            // V2 Address
                                            _buildAddressRow(
                                              context: context,
                                              label: 'v2Address'.tr(),
                                              value: _addressResult!.address,
                                              isHighlighted: true,
                                              onTap: () {
                                                Clipboard.setData(ClipboardData(text: _addressResult!.address));
                                                SnackbarService.showAddressCopied(context);
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    ScaledSizedBox(height: 12),

                                    // Info text
                                    Container(
                                      padding: EdgeInsets.all(scaleSize(12)),
                                      decoration: BoxDecoration(
                                        color: context.colorScheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: context.colorScheme.primary,
                                            size: scaleSize(16),
                                          ),
                                          ScaledSizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'v2AddressInfo'.tr(),
                                              style: scaledTextStyle(
                                                fontSize: 12,
                                                color: context.colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Fixed import button at bottom
              Container(
                padding: EdgeInsets.all(scaleSize(16)),
                decoration: BoxDecoration(
                  color: context.colorScheme.surface,
                  border: Border(top: BorderSide(color: context.colorScheme.outline.withValues(alpha: 0.2), width: 1)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: scaleSize(50),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    onPressed:
                        _addressResult != null &&
                            !_isLoading &&
                            _walletBalance != null &&
                            _walletBalance!.transferableBalance > BigInt.zero
                        ? _importWallet
                        : null,
                    child: Text(
                      'importAccount'.tr(),
                      style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, IdtyStatus idtyStatus) {
    final Map<IdtyStatus, String> statusText = {
      IdtyStatus.none: '',
      IdtyStatus.created: 'identityCreated'.tr(),
      IdtyStatus.confirmed: 'identityConfirmed'.tr(),
      IdtyStatus.validated: 'memberValidated'.tr(),
      IdtyStatus.expired: 'identityExpired'.tr(),
      IdtyStatus.revoked: 'identityRevoked'.tr(),
      IdtyStatus.unknown: '',
    };

    Color getStatusColor(IdtyStatus status) {
      switch (status) {
        case IdtyStatus.validated:
          return context.geckoColors.statusMember;
        case IdtyStatus.confirmed:
          return context.geckoColors.statusConfirmed;
        case IdtyStatus.created:
          return context.geckoColors.statusCreated;
        case IdtyStatus.expired:
          return context.geckoColors.statusExpired;
        case IdtyStatus.revoked:
          return Colors.grey;
        case IdtyStatus.none:
        case IdtyStatus.unknown:
          return Colors.grey;
      }
    }

    final color = getStatusColor(idtyStatus);
    final text = statusText[idtyStatus] ?? '';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: scaleSize(10), vertical: scaleSize(4)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(scaleSize(12)),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        text,
        style: scaledTextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildAddressRow({
    required BuildContext context,
    required String label,
    required String value,
    bool isHighlighted = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(scaleSize(12)),
        decoration: BoxDecoration(
          color: isHighlighted ? context.colorScheme.primary.withValues(alpha: 0.05) : context.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isHighlighted
                ? context.colorScheme.primary.withValues(alpha: 0.3)
                : context.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: scaledTextStyle(fontSize: 12, color: context.colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                  ScaledSizedBox(height: 4),
                  Text(
                    getShortPubkey(value),
                    style: scaledTextStyle(
                      fontSize: 14,
                      fontFamily: 'Monospace',
                      fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.copy, size: scaleSize(18), color: context.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
