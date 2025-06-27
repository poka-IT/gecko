// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' show Durt, IdtyStatus, CertState, CertStatus;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/my_wallets.dart';
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
import 'package:gecko/models/wallet_header_data.dart';
import 'package:gecko/providers/duniter_indexer.dart';

const double buttonSize = 75;
const double buttonFontSize = 13;

class WalletViewScreen extends StatefulWidget {
  const WalletViewScreen({required this.address, required this.username, super.key});
  final String address;
  final String? username;

  @override
  State<WalletViewScreen> createState() => _WalletViewScreenState();
}

class _WalletViewScreenState extends State<WalletViewScreen> {
  late String address;
  late String? username;
  late Future<WalletHeaderData> _headerDataFuture;

  @override
  void initState() {
    super.initState();
    address = widget.address;
    username = widget.username;
    _headerDataFuture = _loadWalletData();
  }

  Future<WalletHeaderData> _loadWalletData() async {
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);

    final (idtyStatusValue, balanceResult, certData) = await (
      Durt.i.storage.getIdtyStatus(widget.address),
      Durt.i.storage.getBalance(widget.address),
      Durt.i.storage.getCertsCounter(widget.address),
    ).wait;

    final data = WalletHeaderData(
      hasIdentity: idtyStatusValue != IdtyStatus.none,
      isOwner: myWalletProvider.isOwner(address),
      walletName: duniterIndexer.walletNameIndexer[address],
      balance: balanceResult.transferableBalance,
      certCount: certData,
    );

    await walletHeaderDataBox.put(address, data);
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final walletProfile = Provider.of<WalletsProfilesProvider>(context, listen: false);

    walletProfile.address = address;
    Durt.i.walletService.setDefaultWallet(address);

    return FutureBuilder<WalletHeaderData>(
      future: _headerDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text(username == null ? 'seeAWallet'.tr() : 'memberAccountOf'.tr(args: [username ?? '']))),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: Text(username == null ? 'seeAWallet'.tr() : 'memberAccountOf'.tr(args: [username ?? '']))),
            body: Center(child: Text('errorLoadingWalletData'.tr())),
          );
        }

        final walletData = snapshot.data!;

        return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: WalletAppBar(
            address: address,
            currentBalance: walletData.balance,
            titleBuilder: (uname) => uname == null ? 'seeAWallet'.tr() : 'memberAccountOf'.tr(args: [uname]),
          ),
          bottomNavigationBar: const GeckoBottomAppBar(),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          children: [
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
                                    PageNoTransit(
                                      builder: (context) => ActivityScreen(address: address),
                                    ),
                                  ),
                                ),
                                Consumer<SubstrateSdk>(
                                  builder: (context, sub, _) {
                                    final identityWallet = Durt.i.walletService.identityWallet;
                                    return identityWallet != null
                                        ? FutureBuilder(
                                            future: Durt.i.storage.getCertState(fromAddress: identityWallet.address, toAddress: address),
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
                                          )
                                        : const SizedBox.shrink();
                                  },
                                ),
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
                          ],
                        ),
                        Column(
                          children: [
                            _buildTransferButton(context),
                            ScaledSizedBox(height: isTall ? 40 : 7),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
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
            color: context.colorScheme.secondary,
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
                child: Image.asset(icon, color: context.colorScheme.onSurface),
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
              color: context.colorScheme.primary,
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
              opacity: Durt.i.isConnected ? 1 : 0.5,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: keyPay,
                  borderRadius: BorderRadius.circular((buttonSize + 5) / 2),
                  onTap: Durt.i.isConnected ? () => _handleTransfer(context) : null,
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
                  color: Durt.i.isConnected ? context.colorScheme.onSurface : Colors.grey[500],
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
