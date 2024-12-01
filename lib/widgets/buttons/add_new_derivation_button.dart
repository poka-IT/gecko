// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:provider/provider.dart';

class AddNewDerivationButton extends StatelessWidget {
  const AddNewDerivationButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context);

    String newDerivationName = '${'wallet'.tr()} ${myWalletProvider.listWallets.last.number! + 2}';
    return Padding(
      padding: EdgeInsets.all(scaleSize(11)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: <Widget>[
            Expanded(
              child: InkWell(
                key: keyAddDerivation,
                onTap: () async {
                  if (!myWalletProvider.isNewDerivationLoading) {
                    if (!await myWalletProvider.askPinCode()) return;

                    await myWalletProvider.generateNewDerivation(context, newDerivationName);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: floattingYellow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: myWalletProvider.isNewDerivationLoading
                        ? ScaledSizedBox(
                            height: 50,
                            width: 50,
                            child: const CircularProgressIndicator(
                              color: orangeC,
                              strokeWidth: 6,
                            ),
                          )
                        : Text(
                            '+',
                            style: scaledTextStyle(
                              fontSize: 100,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFCB437),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
