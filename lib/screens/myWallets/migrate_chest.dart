import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/screens/myWallets/migrate_chest_progress.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:provider/provider.dart';

class MigrateChestScreen extends StatefulWidget {
  const MigrateChestScreen({super.key});

  @override
  State<MigrateChestScreen> createState() => _MigrateChestScreenState();
}

class _MigrateChestScreenState extends State<MigrateChestScreen> {
  final _newMnemonicController = TextEditingController();
  bool _canMigrate = false;
  bool _isLoading = false;
  String _validationMessage = '';
  List<WalletData> _walletsToMigrate = [];

  @override
  void initState() {
    super.initState();
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);
    _walletsToMigrate = myWalletProvider.listWallets;
  }

  Future<void> _validateMnemonic(String newMnemonic) async {
    final sub = Provider.of<SubstrateSdk>(context, listen: false);

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

    final isMnemonicValid = await sub.isMnemonicValid(newMnemonic);
    if (!isMnemonicValid) {
      setState(() {
        _validationMessage = "thisMnemonicIsNotValid".tr();
        _isLoading = false;
      });
      return;
    }

    // Check if destination is empty
    final nbrScan = configBox.get('scanDerivations') ?? 20;
    List<String> destAddresses = [];

    final rootAddressData = await sub.sdk.api.keyring.addressFromMnemonic(
      sub.currencyParameters['ss58']!,
      cryptoType: CryptoType.sr25519,
      mnemonic: newMnemonic,
    );
    destAddresses.add(rootAddressData.address!);

    for (int i = 0; i < nbrScan; i++) {
      final addressData = await sub.sdk.api.keyring.addressFromMnemonic(
        sub.currencyParameters['ss58']!,
        cryptoType: CryptoType.sr25519,
        mnemonic: newMnemonic,
        derivePath: '//$i',
      );
      destAddresses.add(addressData.address!);
    }

    final destBalances = await sub.getBalanceMulti(destAddresses);
    final destIdtyStatus = await sub.idtyStatusMulti(destAddresses);

    if (destBalances.values.any((b) => b.total > 0) || destIdtyStatus.any((s) => s != IdtyStatus.none)) {
      setState(() {
        _validationMessage = 'destinationChestIsNotEmpty'.tr();
        _isLoading = false;
      });
      return;
    }

    // Check if all source wallets can be migrated
    for (final wallet in _walletsToMigrate) {
      if (wallet.isMembre) {
        final checks = await sub.getBalanceAndIdtyStatus(wallet.address, ''); // toAddress is irrelevant here
        if (!checks.canValidate) {
          setState(() {
            _validationMessage = 'cannotMigrateSmith'.tr(args: [wallet.name!]);
            _isLoading = false;
          });
          return;
        }
      }
    }

    setState(() {
      _validationMessage = 'youCanMigrateThisChest'.tr();
      _canMigrate = true;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isSmall = !isTall;
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: GeckoAppBar('migrateChest'.tr()),
      body: SafeArea(
        child: Column(
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
                              'migrateChestExplanation'.tr(),
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
                          color: Colors.grey[100],
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
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
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
                        color: _canMigrate ? Colors.green[600] : Colors.red[600],
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _canMigrate
                          ? () async {
                              final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);
                              if (!await myWalletProvider.askPinCode()) return;

                              Navigator.pushReplacement(
                                // ignore: use_build_context_synchronously
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MigrateChestProgressScreen(
                                    newMnemonic: _newMnemonicController.text,
                                    walletsToMigrate: _walletsToMigrate,
                                    oldChestPin: myWalletProvider.pinCode,
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: Text(
                        'migrateChest'.tr(),
                        style: scaledTextStyle(
                          fontSize: isSmall ? 15 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
