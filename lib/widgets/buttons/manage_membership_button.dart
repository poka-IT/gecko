import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/screens/myWallets/manage_membership.dart';
import 'package:provider/provider.dart';

class ManageMembershipButton extends StatelessWidget {
  const ManageMembershipButton({
    Key? key,
  }) : super(key: key);

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
      child: SizedBox(
        height: 40,
        child: Row(children: <Widget>[
          const SizedBox(width: 32),
          Image.asset(
            'assets/medal.png',
            height: 45,
          ),
          const SizedBox(width: 22),
          Text('manageMembership'.tr(), style: const TextStyle(fontSize: 20)),
        ]),
      ),
    );
  }
}
