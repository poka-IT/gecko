// ignore_for_file: use_build_context_synchronously, must_be_immutable

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:durt/durt.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:provider/provider.dart';

class ChangePinScreen extends StatefulWidget with ChangeNotifier {
  ChangePinScreen(
      {Key? keyMyWallets,
      required this.walletName,
      required this.walletProvider})
      : super(key: keyMyWallets);
  final String? walletName;
  final MyWalletsProvider walletProvider;

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final newPin = TextEditingController();

  @override
  void initState() {
    newPin.text = randomSecretCode(pinLength);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    final myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);

    return PopScope(
      onPopInvokedWithResult: (_, __) {
        newPin.text = '';
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: GeckoAppBar(widget.walletName!),
        body: Center(
          child: SafeArea(
            child: Column(children: <Widget>[
              const SizedBox(height: 80),
              Text(
                'choosePassword'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 30),
              Stack(
                alignment: Alignment.centerRight,
                children: <Widget>[
                  TextField(
                      enabled: false,
                      controller: newPin,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(),
                      style: const TextStyle(
                          fontSize: 29.0,
                          color: Colors.black,
                          fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.replay),
                    color: orangeC,
                    onPressed: () async {
                      newPin.text = randomSecretCode(pinLength);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    elevation: 12,
                    backgroundColor: Colors.green[400],
                  ),
                  onPressed: () async {
                    final defaultWallet = myWalletProvider.getDefaultWallet();

                    if (!await myWalletProvider.askPinCode()) return;

                    await sub.changePassword(context, defaultWallet.address,
                        widget.walletProvider.pinCode, newPin.text);
                    widget.walletProvider.pinCode = newPin.text;
                    newPin.text = '';
                    Navigator.pop(context);
                  },
                  child: Text(
                    'confirm'.tr(),
                    style: const TextStyle(fontSize: 27),
                  ),
                ),
              )
            ]),
          ),
        ),
      ),
    );
  }
}
