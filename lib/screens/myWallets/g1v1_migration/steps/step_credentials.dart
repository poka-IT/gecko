import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/g1v1_migration.provider.dart';
import 'package:gecko/services/snackbar_service.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/balance_display.dart';
import 'package:gecko/widgets/certifications.dart';
import 'package:gecko/widgets/idty_status.dart';

class StepCredentials extends ConsumerStatefulWidget {
  const StepCredentials({super.key});

  @override
  ConsumerState<StepCredentials> createState() => _StepCredentialsState();
}

class _StepCredentialsState extends ConsumerState<StepCredentials> {
  Timer? _debounce;
  static const int _debounceTime = 2000;
  bool _keyboardDismissed = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onCredentialChanged() {
    _keyboardDismissed = false;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceTime), () {
      final salt = ref.read(csSaltControllerProvider).text;
      final password = ref.read(csPasswordControllerProvider).text;
      if (salt.isNotEmpty && password.isNotEmpty) {
        ref.read(g1v1MigrationFlowProvider.notifier).convertAndFetchAccountInfo();
      }
    });
  }

  void _onFieldSubmitted() {
    final salt = ref.read(csSaltControllerProvider).text;
    final password = ref.read(csPasswordControllerProvider).text;
    if (salt.isNotEmpty && password.isNotEmpty) {
      _debounce?.cancel();
      ref.read(g1v1MigrationFlowProvider.notifier).convertAndFetchAccountInfo();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<G1v1MigrationFlowState>(g1v1MigrationFlowProvider, (previous, next) {
      if (!next.isConverting && next.hasBalance && !_keyboardDismissed) {
        _keyboardDismissed = true;
        FocusScope.of(context).unfocus();
      }
    });

    final flowState = ref.watch(g1v1MigrationFlowProvider);
    final uiState = ref.watch(g1v1MigrationUiProvider);
    final saltController = ref.watch(csSaltControllerProvider);
    final passwordController = ref.watch(csPasswordControllerProvider);
    final isSmallScreen = MediaQuery.of(context).size.height < 700;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(scaleSize(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'migration_credentials_title'.tr(),
                  style: scaledTextStyle(fontSize: isSmallScreen ? 18 : 20, fontWeight: FontWeight.bold),
                ),
                ScaledSizedBox(height: 4),
                Text(
                  'migration_credentials_subtitle'.tr(),
                  style: scaledTextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                ScaledSizedBox(height: isSmallScreen ? 12 : 16),

                // Credentials card
                Card(
                  color: context.colorScheme.surfaceContainer,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: EdgeInsets.all(scaleSize(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'cesiumCredentials'.tr(),
                          style: scaledTextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: context.colorScheme.onSecondaryContainer,
                          ),
                        ),
                        ScaledSizedBox(height: 8),
                        // Cesium ID field
                        TextFormField(
                          key: keyCesiumId,
                          autofocus: true,
                          autocorrect: false,
                          onChanged: (_) => _onCredentialChanged(),
                          onFieldSubmitted: (_) => _onFieldSubmitted(),
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          controller: saltController,
                          obscureText: !uiState.isCesiumIDVisible,
                          style: scaledTextStyle(fontSize: 13, color: context.colorScheme.onSecondaryContainer),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            hintText: 'enterCesiumId'.tr(),
                            hintStyle: scaledTextStyle(fontSize: 13),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            suffixIcon: IconButton(
                              key: keyCesiumIdVisible,
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              icon: Icon(
                                uiState.isCesiumIDVisible ? Icons.visibility_off : Icons.visibility,
                                color: Colors.black,
                                size: scaleSize(18),
                              ),
                              onPressed: () {
                                ref.read(g1v1MigrationUiProvider.notifier).toggleCesiumIDVisibility();
                              },
                            ),
                          ),
                        ),
                        ScaledSizedBox(height: 8),
                        // Cesium Password field
                        TextFormField(
                          key: keyCesiumPassword,
                          autocorrect: false,
                          onChanged: (_) => _onCredentialChanged(),
                          onFieldSubmitted: (_) => _onFieldSubmitted(),
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.done,
                          controller: passwordController,
                          obscureText: !uiState.isCesiumPasswordVisible,
                          style: scaledTextStyle(fontSize: 13, color: context.colorScheme.onSecondaryContainer),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            hintText: 'enterCesiumPassword'.tr(),
                            hintStyle: scaledTextStyle(fontSize: 13),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            suffixIcon: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              icon: Icon(
                                uiState.isCesiumPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                color: Colors.black,
                                size: scaleSize(18),
                              ),
                              onPressed: () {
                                ref.read(g1v1MigrationUiProvider.notifier).toggleCesiumPasswordVisibility();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Converting indicator
                if (flowState.isConverting)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: scaleSize(16)),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: scaleSize(20),
                            height: scaleSize(20),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          ScaledSizedBox(width: 12),
                          Text(
                            'migration_converting'.tr(),
                            style: scaledTextStyle(fontSize: 13, color: context.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Account info section (shown after conversion)
                if (flowState.hasValidCredentials && !flowState.isConverting) ...[
                  ScaledSizedBox(height: 8),
                  // V1 Pubkey (copiable)
                  Card(
                    elevation: 2,
                    color: context.colorScheme.surfaceContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: EdgeInsets.all(scaleSize(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'migration_v1_pubkey_label'.tr(),
                            style: scaledTextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: context.colorScheme.onSecondaryContainer,
                            ),
                          ),
                          ScaledSizedBox(height: 8),
                          // V1 pubkey row
                          GestureDetector(
                            key: keyCopyPubkey,
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: flowState.v1Pubkey));
                              SnackbarService.showAddressCopied(context);
                            },
                            child: Row(
                              children: [
                                Text(
                                  'v1: ',
                                  style: scaledTextStyle(fontSize: 13, color: context.colorScheme.onSecondaryContainer),
                                ),
                                Text(
                                  getShortPubkey(flowState.v1Pubkey),
                                  style: scaledTextStyle(
                                    fontSize: 13,
                                    fontFamily: 'Monospace',
                                    color: context.colorScheme.onSecondaryContainer,
                                  ),
                                ),
                                ScaledSizedBox(width: 6),
                                Icon(Icons.copy, size: scaleSize(14), color: Colors.grey),
                              ],
                            ),
                          ),
                          ScaledSizedBox(height: 8),
                          // V2 address (collapsible)
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(
                              'migration_v2_address_hint'.tr(),
                              style: scaledTextStyle(fontSize: 12, color: context.colorScheme.onSurfaceVariant),
                            ),
                            children: [
                              GestureDetector(
                                key: keyCopyAddress,
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: flowState.v2Address));
                                  SnackbarService.showAddressCopied(context);
                                },
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: scaleSize(8)),
                                  child: Row(
                                    children: [
                                      Text(
                                        'v2: ',
                                        style: scaledTextStyle(
                                          fontSize: 13,
                                          color: context.colorScheme.onSecondaryContainer,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          getShortPubkey(flowState.v2Address),
                                          style: scaledTextStyle(
                                            fontSize: 13,
                                            fontFamily: 'Monospace',
                                            color: context.colorScheme.onSecondaryContainer,
                                          ),
                                        ),
                                      ),
                                      Icon(Icons.copy, size: scaleSize(14), color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  ScaledSizedBox(height: 8),

                  // Contextual account info card
                  _buildAccountInfoCard(context, flowState, isSmallScreen),
                ],

                // Error message
                if (flowState.errorMessage != null)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: scaleSize(8)),
                    child: Text(flowState.errorMessage!, style: scaledTextStyle(fontSize: 12, color: Colors.red)),
                  ),
              ],
            ),
          ),
        ),

        // Navigation buttons
        _buildNavigationButtons(context, ref, flowState, isSmallScreen),
      ],
    );
  }

  Widget _buildAccountInfoCard(BuildContext context, G1v1MigrationFlowState flowState, bool isSmallScreen) {
    switch (flowState.accountType) {
      case MigrationAccountType.empty:
        return Card(
          color: Colors.red.shade50,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.red.shade300, width: 1),
          ),
          child: Padding(
            padding: EdgeInsets.all(scaleSize(12)),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: scaleSize(20)),
                ScaledSizedBox(width: 12),
                Expanded(
                  child: Text(
                    'migration_account_empty'.tr(),
                    style: scaledTextStyle(fontSize: 13, color: Colors.red.shade900),
                  ),
                ),
              ],
            ),
          ),
        );

      case MigrationAccountType.alreadyMigrated:
        final migration = flowState.migrationFromData!;
        final dateStr = DateFormat.yMMMd(safeLocale(context.locale.languageCode)).format(migration.migrationDate);
        return Card(
          color: Colors.orange.shade50,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.orange.shade300, width: 1),
          ),
          child: Padding(
            padding: EdgeInsets.all(scaleSize(12)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700, size: scaleSize(20)),
                ScaledSizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'migration_account_already_migrated'.tr(),
                        style: scaledTextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade900,
                        ),
                      ),
                      ScaledSizedBox(height: 4),
                      Text(
                        'migration_account_already_migrated_details'.tr(
                          args: [dateStr, getShortPubkey(migration.toAddress)],
                        ),
                        style: scaledTextStyle(fontSize: 12, color: Colors.orange.shade800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

      case MigrationAccountType.balanceOnly:
        return Card(
          color: Colors.green.shade50,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.green.shade300, width: 1),
          ),
          child: Padding(
            padding: EdgeInsets.all(scaleSize(12)),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: scaleSize(20)),
                ScaledSizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'migration_account_has_balance'.tr(),
                        style: scaledTextStyle(fontSize: 13, color: Colors.green.shade900),
                      ),
                      ScaledSizedBox(height: 4),
                      BalanceDisplay(
                        value: flowState.sourceBalance?.transferableBalance ?? BigInt.zero,
                        size: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade900,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

      case MigrationAccountType.withIdentity:
        return Card(
          color: Colors.green.shade50,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.green.shade300, width: 1),
          ),
          child: Padding(
            padding: EdgeInsets.all(scaleSize(12)),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: scaleSize(20)),
                ScaledSizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'migration_account_has_identity'.tr(),
                        style: scaledTextStyle(fontSize: 13, color: Colors.green.shade900),
                      ),
                      ScaledSizedBox(height: 4),
                      BalanceDisplay(
                        value: flowState.sourceBalance?.transferableBalance ?? BigInt.zero,
                        size: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade900,
                      ),
                      ScaledSizedBox(height: 4),
                      Row(
                        children: [
                          IdentityStatus(address: flowState.v2Address, color: Colors.green.shade800),
                          ScaledSizedBox(width: 4),
                          if (flowState.sourceIdentityName != null)
                            Text(
                              flowState.sourceIdentityName!,
                              style: scaledTextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.green.shade900,
                              ),
                            ),
                          ScaledSizedBox(width: 8),
                          Certifications(address: flowState.v2Address, size: 12, color: Colors.green.shade900),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

      case MigrationAccountType.unknown:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavigationButtons(
    BuildContext context,
    WidgetRef ref,
    G1v1MigrationFlowState flowState,
    bool isSmallScreen,
  ) {
    final canContinue = flowState.hasBalance && !flowState.isConverting;

    return Padding(
      padding: EdgeInsets.all(scaleSize(12)),
      child: Row(
        children: [
          TextButton(
            onPressed: () {
              ref.read(g1v1MigrationFlowProvider.notifier).previousStep();
            },
            child: Text('cancel'.tr()),
          ),
          const Spacer(),
          SizedBox(
            height: scaleSize(isSmallScreen ? 40 : 44),
            child: ElevatedButton(
              key: keyMigrationCredentialsContinue,
              onPressed: canContinue ? () => ref.read(g1v1MigrationFlowProvider.notifier).nextStep() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colorScheme.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'continue'.tr(),
                style: scaledTextStyle(fontSize: isSmallScreen ? 14 : 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
