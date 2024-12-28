import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/widgets/commons/wallet_app_bar.dart';
import 'package:provider/provider.dart';

class ConfirmIdentityScreen extends StatefulWidget {
  const ConfirmIdentityScreen({super.key, required this.address});
  final String address;

  @override
  State<ConfirmIdentityScreen> createState() => _ConfirmIdentityScreenState();
}

class _ConfirmIdentityScreenState extends State<ConfirmIdentityScreen> {
  final TextEditingController _identityNameController = TextEditingController();
  bool _canValidate = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _identityNameController.dispose();
    super.dispose();
  }

  Future<void> _validateIdentityName(DuniterIndexer duniterIndexer) async {
    final name = _identityNameController.text.trim();
    final idtyExist = await duniterIndexer.isIdtyExist(name);
    final hasNoSpaces = !name.contains(' ');
    final isValid = !idtyExist && hasNoSpaces && name.length >= 3 && name.length <= 32;

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
        _errorMessage = '';
      }
    });
  }

  Future<void> _confirmIdentity(BuildContext context) async {
    final name = _identityNameController.text.trim();
    final navigatorState = Navigator.of(context);
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);
    final sub = Provider.of<SubstrateSdk>(context, listen: false);

    // Afficher le dialogue de confirmation
    final confirmed = await showConfirmationDialog(
      context: context,
      type: ConfirmationDialogType.info,
      message: 'confirmIdentityNameChoice'.tr(args: [name]),
    );

    if (confirmed != true) return;

    if (!await myWalletProvider.askPinCode()) return;

    final transactionId = await sub.confirmIdentity(widget.address, name, myWalletProvider.pinCode);

    if (!mounted) return;
    navigatorState.pop();

    navigatorState.push(
      MaterialPageRoute(
        builder: (context) => TransactionInProgress(
          transactionId: transactionId,
          transType: 'comfirmIdty',
          fromAddress: widget.address,
          toAddress: widget.address,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: WalletAppBar(
        address: widget.address,
        title: 'chooseIdentityName'.tr(),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(scaleSize(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête avec icône
                    Center(
                      child: Container(
                        width: scaleSize(isSmallScreen ? 60 : 80),
                        height: scaleSize(isSmallScreen ? 60 : 80),
                        decoration: BoxDecoration(
                          color: orangeC.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_outline,
                          size: scaleSize(isSmallScreen ? 30 : 40),
                          color: orangeC,
                        ),
                      ),
                    ),
                    ScaledSizedBox(height: isSmallScreen ? 16 : 32),

                    // Titre principal
                    Text(
                      'identityInDuniterNetwork'.tr(args: [currencyName]),
                      style: scaledTextStyle(
                        fontSize: isSmallScreen ? 20 : 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    ScaledSizedBox(height: isSmallScreen ? 16 : 24),

                    // Texte explicatif
                    Text(
                      'identityExplanation'.tr(),
                      style: scaledTextStyle(fontSize: isSmallScreen ? 14 : 16),
                    ),
                    ScaledSizedBox(height: isSmallScreen ? 16 : 24),

                    // Points importants
                    ...[
                      'identityNameUnique'.tr(),
                      'identityNameSearchable'.tr(),
                      'identityNamePermanent'.tr(),
                    ].map((text) => Padding(
                          padding: EdgeInsets.only(bottom: scaleSize(isSmallScreen ? 8 : 12)),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: orangeC, size: scaleSize(isSmallScreen ? 16 : 20)),
                              ScaledSizedBox(width: isSmallScreen ? 8 : 12),
                              Expanded(
                                child: Text(
                                  text,
                                  style: scaledTextStyle(fontSize: isSmallScreen ? 14 : 16),
                                ),
                              ),
                            ],
                          ),
                        )),
                    ScaledSizedBox(height: isSmallScreen ? 24 : 32),

                    // Champ de saisie
                    TextField(
                      key: keyEnterIdentityUsername,
                      controller: _identityNameController,
                      onChanged: (_) => _validateIdentityName(duniterIndexer),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (_canValidate) {
                          _confirmIdentity(context);
                        }
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'^ ')),
                      ],
                      decoration: InputDecoration(
                        hintText: 'enterIdentityName'.tr(),
                        errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: scaleSize(16),
                          vertical: scaleSize(12),
                        ),
                      ),
                      style: scaledTextStyle(fontSize: isSmallScreen ? 14 : 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bouton de validation en position fixe
          Padding(
            padding: EdgeInsets.all(scaleSize(16)),
            child: SizedBox(
              width: double.infinity,
              height: scaleSize(isSmallScreen ? 44 : 50),
              child: ElevatedButton(
                key: keyConfirm,
                onPressed: _canValidate ? () => _confirmIdentity(context) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeC,
                  disabledBackgroundColor: Colors.grey[300],
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'validate'.tr(),
                  style: scaledTextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
