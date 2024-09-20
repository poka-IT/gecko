import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/screens/myWallets/manage_membership.dart';
import 'package:provider/provider.dart';

class ManageMembershipButton extends StatelessWidget {
  const ManageMembershipButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final walletOptions =
        Provider.of<WalletOptionsProvider>(context, listen: false);
    return InkWell(
      key: keyManageMembership,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) {
            return ManageMembership(
              address: walletOptions.address.text,
            );
          }),
        );
      },
      child: ScaledSizedBox(
        height: 40,
        child: Row(children: <Widget>[
          ScaledSizedBox(width: 28),
          Image.asset(
            'assets/medal.png',
            height: scaleSize(42),
          ),
          ScaledSizedBox(width: 20),
          Text('manageMembership'.tr(), style: scaledTextStyle(fontSize: 17)),
        ]),
      ),
    );
  }
}
