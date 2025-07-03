// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' show IdtyStatus, CertState, CertStatus;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers.dart';
import 'package:gecko/providers/block_height_provider.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/activity.dart';
import 'package:gecko/widgets/certify/cert_state.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/widgets/bottom_app_bar.dart';
import 'package:gecko/widgets/wallet_header.dart';
import 'package:gecko/widgets/page_route_no_transition.dart';
import 'package:gecko/widgets/payment_popup.dart';
import 'package:provider/provider.dart' as old_provider;
import 'package:gecko/widgets/commons/wallet_app_bar.dart';
import 'package:gecko/models/wallet_header_data.dart';
import 'package:gecko/providers/duniter_indexer.dart';

const double buttonSize = 75;
const double buttonFontSize = 13;

class WalletViewScreen extends ConsumerStatefulWidget {
  const WalletViewScreen({required this.address, required this.username, super.key});
  final String address;
  final String? username;

  @override
  ConsumerState<WalletViewScreen> createState() => _WalletViewScreenState();
}

class _WalletViewScreenState extends ConsumerState<WalletViewScreen> {
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
    final duniterIndexer = old_provider.Provider.of<DuniterIndexer>(context, listen: false);
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);

    final (idtyStatusValue, balanceResult, certData) = await (
      ref.read(storageServiceProvider).getIdtyStatus(widget.address),
      ref.read(storageServiceProvider).getBalance(widget.address),
      ref.read(storageServiceProvider).getCertsCounter(widget.address),
    ).wait;

    final data = WalletHeaderData(
      hasIdentity: idtyStatusValue != IdtyStatus.none,
      isOwner: myWalletProvider.isOwner(address),
      walletName: duniterIndexer.walletNameIndexer[address],
      balance: balanceResult.transferableBalance,
      certsReceived: certData.receivedCount,
      certsSent: certData.sentCount,
    );

    await walletHeaderDataBox.put(address, data);
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final walletProfile = old_provider.Provider.of<WalletsProfilesProvider>(context, listen: false);

    walletProfile.address = address;

    return FutureBuilder<WalletHeaderData>(
      future: _headerDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text(username == null ? 'seeAWallet'.tr() : 'memberAccountOf'.tr(args: [username ?? ''])),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: Text(username == null ? 'seeAWallet'.tr() : 'memberAccountOf'.tr(args: [username ?? ''])),
            ),
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
                                    PageNoTransit(builder: (context) => ActivityScreen(address: address)),
                                  ),
                                ),
                                old_provider.Consumer<BlockHeightProvider>(
                                  builder: (context, _, _) {
                                    final identityWallet = ref.read(walletServiceProvider).identityWallet;
                                    return identityWallet != null
                                        ? FutureBuilder(
                                            future: ref
                                                .read(storageServiceProvider)
                                                .getCertState(fromAddress: identityWallet.address, toAddress: address),
                                            builder: (context, AsyncSnapshot<CertState> snapshot) {
                                              if (!snapshot.hasData) return const SizedBox.shrink();
                                              final certState = snapshot.data!;
                                              return Visibility(
                                                visible: certState.status != CertStatus.none,
                                                child: CertStateWidget(certState: certState, address: address),
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
                            _buildTransferButton(ref),
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
    required Key key,
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
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2)),
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildTransferButton(WidgetRef ref) {
    return old_provider.Consumer<BlockHeightProvider>(
      builder: (context, _, _) {
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
                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 3)),
                ],
                border: Border.all(color: const Color(0xFF6c4204), width: 3),
              ),
              child: Opacity(
                opacity: ref.read(durtProvider).isConnected ? 1 : 0.5,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: keyPay,
                    borderRadius: BorderRadius.circular((buttonSize + 5) / 2),
                    onTap: ref.read(durtProvider).isConnected ? () => _handleTransfer(ref) : null,
                    child: Padding(
                      padding: EdgeInsets.all(scaleSize(15)),
                      child: Image.asset('assets/vector_white.png', color: Colors.white),
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
                color: ref.read(durtProvider).isConnected ? context.colorScheme.onSurface : Colors.grey[500],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleTransfer(WidgetRef ref) async {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(homeContext, listen: false);
    final defaultWallet = myWalletProvider.getDefaultWallet();

    if (myWalletProvider.pinCode == '') {
      await Navigator.push(homeContext, MaterialPageRoute(builder: (_) => UnlockingWallet(wallet: defaultWallet)));
    }
    if (myWalletProvider.pinCode == '') return;
    paymentPopup(ref: ref, toAddress: address, username: username);
  }
}
