// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/activity.dart';
import 'package:gecko/widgets/certify/cert_state.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/widgets/bottom_app_bar.dart';
import 'package:gecko/widgets/wallet_header.dart';
import 'package:gecko/widgets/page_route_no_transition.dart';
import 'package:gecko/widgets/payment_popup.dart';
import 'package:provider/provider.dart';
import 'package:gecko/widgets/commons/wallet_app_bar.dart';

const double buttonSize = 75;
const double buttonFontSize = 13;

class WalletViewScreen extends StatelessWidget {
  const WalletViewScreen({required this.address, required this.username, super.key});
  final String address;
  final String? username;

  @override
  Widget build(BuildContext context) {
    final walletProfile = Provider.of<WalletsProfilesProvider>(context, listen: false);
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);
    final defaultWallet = myWalletProvider.getDefaultWallet();
    // final wallet = myWalletProvider.getWalletDataByAddress(address)!;

    walletProfile.address = address;
    sub.setCurrentWallet(defaultWallet);

    return Scaffold(
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: true,
        appBar: WalletAppBar(
          address: address,
          titleBuilder: (username) => username == null ? 'seeAWallet'.tr() : 'memberAccountOf'.tr(args: [username]),
        ),
        bottomNavigationBar: const GeckoBottomAppBar(),
        body: SafeArea(
          child: Column(children: <Widget>[
            WalletHeader(address: address),
            ScaledSizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  context: context,
                  key: keyViewActivity,
                  icon: 'assets/walletOptions/clock.png',
                  label: "displayNActivity".tr(),
                  onTap: () => Navigator.push(
                    context,
                    PageNoTransit(builder: (context) => ActivityScreen(address: address)),
                  ),
                ),
                Consumer<SubstrateSdk>(builder: (context, sub, _) {
                  WalletData? defaultWallet = myWalletProvider.getDefaultWallet();
                  return FutureBuilder(
                    future: sub.certState(defaultWallet.address, address),
                    builder: (context, AsyncSnapshot<CertState> snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final certState = snapshot.data!;
                      return Visibility(
                        visible: certState.status != CertStatus.none,
                        child: CertStateWidget(
                          certState: certState,
                          address: address,
                        ),
                      );
                    },
                  );
                }),
                _buildActionButton(
                  context: context,
                  key: keyCopyAddress,
                  icon: 'assets/copy_key.png',
                  label: "copyAddress".tr(),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: address));
                    snackCopyKey(context);
                  },
                ),
              ],
            ),
            const Spacer(),
            _buildTransferButton(context),
            ScaledSizedBox(height: isTall ? 40 : 7),
          ]),
        ));
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String icon,
    required String label,
    required VoidCallback onTap,
    Key? key,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: scaleSize(buttonSize),
          width: scaleSize(buttonSize),
          decoration: BoxDecoration(
            color: yellowC,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: key,
              borderRadius: BorderRadius.circular(buttonSize / 2),
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.all(scaleSize(15)),
                child: Image.asset(icon, color: Colors.black87),
              ),
            ),
          ),
        ),
        ScaledSizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Widget _buildTransferButton(BuildContext context) {
    return Consumer<SubstrateSdk>(builder: (context, sub, _) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: scaleSize(buttonSize + 5),
            width: scaleSize(buttonSize + 5),
            decoration: BoxDecoration(
              color: orangeC,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: const Color(0xFF6c4204),
                width: 3,
              ),
            ),
            child: Opacity(
              opacity: sub.nodeConnected ? 1 : 0.5,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: keyPay,
                  borderRadius: BorderRadius.circular((buttonSize + 5) / 2),
                  onTap: sub.nodeConnected ? () => _handleTransfer(context) : null,
                  child: Padding(
                    padding: EdgeInsets.all(scaleSize(15)),
                    child: Image.asset(
                      'assets/vector_white.png',
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          ScaledSizedBox(height: 6),
          Text(
            'doATransfer'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: sub.nodeConnected ? Colors.black87 : Colors.grey[500],
                ),
          ),
        ],
      );
    });
  }

  Future<void> _handleTransfer(BuildContext context) async {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);
    final defaultWallet = myWalletProvider.getDefaultWallet();

    if (myWalletProvider.pinCode == '') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (homeContext) => UnlockingWallet(wallet: defaultWallet),
        ),
      );
    }
    if (myWalletProvider.pinCode == '') return;
    paymentPopup(context, address, username);
  }
}
