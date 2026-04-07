import 'package:durt2/durt2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/services/config_service.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/screens/myWallets/migrate_safe_progress.dart';
import 'package:gecko/services/mnemonic_service.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/widgets/commons/responsive_center.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';

class MigrateSafeScreen extends ConsumerStatefulWidget {
  const MigrateSafeScreen({super.key, this.embeddedMode = false});
  final bool embeddedMode;

  @override
  ConsumerState<MigrateSafeScreen> createState() => _MigrateSafeScreenState();
}

class _MigrateSafeScreenState extends ConsumerState<MigrateSafeScreen> {
  final _newMnemonicController = TextEditingController();
  bool _canMigrate = false;
  bool _isLoading = false;
  String _validationMessage = '';
  String _englishMnemonic = '';
  List<WalletEntity> _walletsToMigrate = [];
  bool _isInitialized = false;

  void _initWallets() {
    if (!_isInitialized) {
      _walletsToMigrate = ref.read(walletsListProvider).wallets;
      _isInitialized = true;
    }
  }

  Future<void> _validateMnemonic(String newMnemonic) async {
    setState(() {
      _isLoading = true;
      _validationMessage = '';
      _canMigrate = false;
    });

    if (newMnemonic.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Validate mnemonic with multilingual support
    final mnemonicResult = await MnemonicService.validateAndProcessMnemonic(newMnemonic);
    if (mnemonicResult == null) {
      setState(() {
        _validationMessage = "thisMnemonicIsNotValid".tr();
        _isLoading = false;
      });
      return;
    }

    _englishMnemonic = mnemonicResult.englishMnemonic;

    try {
      // Check if destination is empty
      final nbrScan = ref.read(configServiceProvider).scanDerivations;
      List<String> destAddresses = [];

      // Generate root address (without derivation)
      final rootKeypair = await ref
          .read(walletServiceProvider)
          .getKeyPairFromMnemonic(_englishMnemonic, keyPairType: Durt.defaultKeyPairType);
      destAddresses.add(rootKeypair.address);

      // Generate derived addresses (derivation //0, //1, //2, etc.)
      for (int i = 0; i < nbrScan; i++) {
        final derivedKeypair = await ref
            .read(walletServiceProvider)
            .getKeyPairFromMnemonic(_englishMnemonic, derivation: i, keyPairType: Durt.defaultKeyPairType);
        destAddresses.add(derivedKeypair.address);
      }

      // Check balances using Durt storage service
      final destBalances = await ref.read(durtProvider).storage.getBalances(destAddresses);

      // Check if any destination address has funds or identity
      bool hasExistingData = false;
      for (final address in destAddresses) {
        final balance = destBalances[address];
        if (balance != null && balance.transferableBalance > BigInt.zero) {
          hasExistingData = true;
          break;
        }

        // Check identity status
        try {
          final idtyIndex = await ref.read(durtProvider).storage.getIdentityIndexOf(address);
          if (idtyIndex != null) {
            hasExistingData = true;
            break;
          }
        } catch (e) {
          // Identity doesn't exist, continue
        }
      }

      if (hasExistingData) {
        setState(() {
          _validationMessage = 'destinationSafeIsNotEmpty'.tr();
          _isLoading = false;
        });
        return;
      }

      // Check if all source wallets can be migrated
      for (final wallet in _walletsToMigrate) {
        // Check if wallet is a member using storage service directly
        final idtyStatus = await ref.read(storageServiceProvider).getIdtyStatus(wallet.address);
        if (idtyStatus == IdtyStatus.validated) {
          final checks = await ref
              .read(storageServiceProvider)
              .getMigrateWalletChecks(fromAddress: wallet.address, toAddress: destAddresses.first);
          if (checks.errors.contains(MigrateWalletValidationError.sourceAccountIsEmpty)) {
            setState(() {
              _validationMessage = 'thisAccountIsEmpty'.tr();
              _isLoading = false;
            });
            return;
          }
          if (checks.errors.contains(MigrateWalletValidationError.cannotMigrateIdentityToIdentity)) {
            setState(() {
              _validationMessage = 'youCannotMigrateIdentityToExistingIdentity'.tr();
              _isLoading = false;
            });
            return;
          }
        }
      }

      setState(() {
        _validationMessage = 'youCanMigrateThisSafe'.tr();
        _canMigrate = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _validationMessage = 'validationError'.tr();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _initWallets();
    bool isSmall = !isTall;

    final body = Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: scaleSize(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScaledSizedBox(height: isSmall ? 16 : 24),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: scaleSize(isSmall ? 50 : 70),
                          height: scaleSize(isSmall ? 50 : 70),
                          decoration: BoxDecoration(
                            color: context.colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.emergency_share_outlined,
                            size: scaleSize(isSmall ? 25 : 35),
                            color: context.colorScheme.primary,
                          ),
                        ),
                        ScaledSizedBox(height: isSmall ? 16 : 24),
                        Text(
                          'migrateSafeExplanation'.tr(),
                          textAlign: TextAlign.center,
                          style: scaledTextStyle(
                            fontSize: isSmall ? 14 : 15,
                            color: context.colorScheme.onSurface,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ScaledSizedBox(height: isSmall ? 24 : 40),
                  Text(
                    'enterYourNewMnemonic'.tr(),
                    style: scaledTextStyle(
                      fontSize: isSmall ? 15 : 16,
                      fontWeight: FontWeight.w600,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                  ScaledSizedBox(height: isSmall ? 12 : 16),
                  Container(
                    decoration: BoxDecoration(
                      color: context.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _newMnemonicController,
                      minLines: isSmall ? 2 : 3,
                      maxLines: isSmall ? 2 : 3,
                      style: scaledTextStyle(
                        fontSize: isSmall ? 14 : 15,
                        color: context.colorScheme.onSurface,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(scaleSize(isSmall ? 12 : 16)),
                        border: InputBorder.none,
                        hintText: 'word1 word2 word3 word4 ...',
                        hintStyle: scaledTextStyle(
                          fontSize: isSmall ? 14 : 15,
                          color: Colors.grey[400],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      onChanged: (newMnemonic) async {
                        await _validateMnemonic(newMnemonic);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(scaleSize(isSmall ? 16 : 24)),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainer,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading)
                const CircularProgressIndicator()
              else if (_validationMessage.isNotEmpty)
                Text(
                  _validationMessage,
                  textAlign: TextAlign.center,
                  style: scaledTextStyle(
                    fontSize: isSmall ? 12 : 13,
                    color: _canMigrate ? context.geckoColors.success : context.geckoColors.danger,
                  ),
                ),
              ScaledSizedBox(height: isSmall ? 12 : 16),
              SizedBox(
                width: double.infinity,
                height: scaleSize(isSmall ? 44 : 50),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _canMigrate
                      ? () async {
                          final confirmed = await showConfirmationDialog(
                            context: context,
                            type: ConfirmationDialogType.warning,
                            title: 'confirmMigrationTitle'.tr(),
                            message: 'confirmMigrationMessage'.tr(),
                          );

                          if (!confirmed) return;
                          if (!context.mounted) return;

                          final capturedPin = await PinCodeService.askPinCodeAndCapture(
                            context,
                            wallet: ref.read(firstWalletProvider),
                          );
                          if (capturedPin == null) return;

                          if (!context.mounted) return;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MigrateSafeProgressScreen(
                                newMnemonic: _englishMnemonic,
                                walletsToMigrate: _walletsToMigrate,
                                oldSafePin: capturedPin,
                              ),
                            ),
                          );
                        }
                      : null,
                  child: Text(
                    'migrateSafe'.tr(),
                    style: scaledTextStyle(fontSize: isSmall ? 15 : 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.embeddedMode) {
      return ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: body);
    }

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: GeckoAppBar('migrateSafe'.tr()),
      body: SafeArea(
        child: ResponsiveCenter(maxWidth: 600, padding: EdgeInsets.zero, child: body),
      ),
    );
  }
}
