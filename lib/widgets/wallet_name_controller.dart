import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:provider/provider.dart';

class WalletNameController extends StatelessWidget {
  const WalletNameController({Key? key, required this.wallet, this.size = 20})
      : super(key: key);
  final WalletData wallet;
  final double size;

  @override
  Widget build(BuildContext context) {
    final walletOptions =
        Provider.of<WalletOptionsProvider>(context, listen: false);
    walletOptions.nameController.text = wallet.name ?? '';
    final walletNameFocus = FocusNode();

    return SizedBox(
      width: 260,
      child: Stack(children: <Widget>[
        TextField(
          key: keyWalletName,
          autofocus: false,
          focusNode: walletNameFocus,
          enabled: walletOptions.isEditing,
          controller: walletOptions.nameController,
          minLines: 1,
          maxLines: 3,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            contentPadding: EdgeInsets.all(15.0),
          ),
          style: TextStyle(
            fontSize: isTall ? size : size * 0.9,
            color: Colors.black,
            fontWeight: FontWeight.w400,
          ),
        ),
        Positioned(
          right: 0,
          child: InkWell(
            key: keyRenameWallet,
            onTap: () async {
              // _isNewNameValid =
              // walletProvider.editWalletName(wallet.id(), isCesium: false);
              await walletOptions.editWalletName(context, wallet.id());
              await Future.delayed(const Duration(milliseconds: 30));
              walletNameFocus.requestFocus();
            },
            child: ClipRRect(
              child: Image.asset(
                  walletOptions.isEditing
                      ? 'assets/walletOptions/android-checkmark.png'
                      : 'assets/walletOptions/edit.png',
                  width: 25,
                  height: 25),
            ),
          ),
        ),
      ]),
    );
  }
}
