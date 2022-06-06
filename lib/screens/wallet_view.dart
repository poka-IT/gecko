import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/providers/cesium_plus.dart';
import 'package:gecko/providers/home.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/avatar_fullscreen.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/myWallets/choose_wallet.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/screens/qrcode_fullscreen.dart';
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class WalletViewScreen extends StatelessWidget {
  const WalletViewScreen(
      {required this.pubkey, this.username, this.avatar, Key? key})
      : super(key: key);
  final String? pubkey;
  final String? username;
  final Image? avatar;
  final double buttonSize = 100;
  final double buttonFontSize = 18;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    WalletsProfilesProvider _walletViewProvider =
        Provider.of<WalletsProfilesProvider>(context, listen: false);
    CesiumPlusProvider _cesiumPlusProvider =
        Provider.of<CesiumPlusProvider>(context, listen: false);
    _walletViewProvider.address = pubkey!;
    SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);
    HomeProvider _homeProvider =
        Provider.of<HomeProvider>(context, listen: false);

    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);
    WalletData? defaultWallet = _myWalletProvider.getDefaultWallet();
    _sub.setCurrentWallet(defaultWallet);

    return Scaffold(
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          elevation: 0,
          toolbarHeight: 60 * ratio,
          actions: [
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) {
                    return QrCodeFullscreen(
                      _walletViewProvider.address!,
                    );
                  }),
                );
              },
              child: QrImageWidget(
                data: _walletViewProvider.address!,
                version: QrVersions.auto,
                size: 80,
              ),
            ),
          ],
          title: const SizedBox(
            height: 22,
            child: Text('Voir un portefeuille'),
          ),
        ),
        bottomNavigationBar: _homeProvider.bottomAppBar(context),
        // floatingActionButton: _homeProvider.floatingAction(context, 1),
        // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        body: SafeArea(
          child: Column(children: <Widget>[
            headerProfileView(
                context, _walletViewProvider, _cesiumPlusProvider),
            SizedBox(height: isTall ? 10 : 0),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              Column(children: <Widget>[
                SizedBox(
                  height: buttonSize,
                  child: ClipOval(
                    child: Material(
                      color: Colors
                          .grey[300], //const Color(0xffFFD58D), // button color
                      child: InkWell(
                          key: const Key('viewHistory'),
                          splashColor: orangeC, // inkwell color
                          child: const Padding(
                              padding: EdgeInsets.all(13),
                              child: Image(
                                  image: AssetImage(
                                      'assets/walletOptions/clock.png'),
                                  height: 90)),
                          onTap: () {
                            //// Wait for subsquid indexer
                            // _historyProvider.nPage = 1;
                            // Navigator.push(
                            //   context,
                            //   FaderTransition(
                            //       page: HistoryScreen(
                            //         pubkey: pubkey,
                            //         username: username ??
                            //             g1WalletsBox.get(pubkey)?.username,
                            //         avatar: avatar ??
                            //             g1WalletsBox.get(pubkey)?.avatar,
                            //       ),
                            //       isFast: false),
                            // );
                          }),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  "Voir\nl'historique",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: buttonFontSize, fontWeight: FontWeight.w500),
                ),
              ]),
              Consumer<SubstrateSdk>(builder: (context, _sub, _) {
                WalletData? _defaultWallet =
                    _myWalletProvider.getDefaultWallet();
                return FutureBuilder(
                  future: _sub.certState(_defaultWallet.address!,
                      pubkey!), // .canCertify(_defaultWallet.address!, pubkey!),
                  builder: (context, AsyncSnapshot<Map<String, int>> snapshot) {
                    // log.d(snapshot.data);
                    if (snapshot.data == null) return const SizedBox();
                    String _duration = '';
                    if (snapshot.data!['certDelay'] != null ||
                        snapshot.data!['certRenewable'] != null) {
                      final Duration _durationSeconds = Duration(
                          seconds: snapshot.data!['certDelay'] ??
                              snapshot.data!['certRenewable']!);
                      final int _seconds = _durationSeconds.inSeconds;
                      final int _minutes = _durationSeconds.inMinutes;

                      if (_seconds <= 60) {
                        _duration = '$_seconds secondes';
                      } else if (_seconds <= 3600) {
                        _duration = '$_minutes minutes';
                      } else if (_seconds <= 86400) {
                        final int _hours = _durationSeconds.inHours;
                        final int _minutesLeft = _minutes - _hours * 60;
                        String _showMinutes = '';
                        if (_minutesLeft < 60) {}
                        _showMinutes = ' $_minutesLeft minutes';
                        _duration = '$_hours heures$_showMinutes';
                      } else if (_seconds <= 2592000) {
                        final int _days = _durationSeconds.inDays;
                        _duration = '$_days jours';
                      } else {
                        final int _months =
                            (_durationSeconds.inDays / 30).round();
                        _duration = '$_months mois';
                      }
                    }
                    return Visibility(
                      visible: (snapshot.data != {}),
                      child: Column(children: <Widget>[
                        if (snapshot.data!['canCert'] != null)
                          Column(children: <Widget>[
                            SizedBox(
                              height: buttonSize,
                              child: ClipOval(
                                child: Material(
                                  color:
                                      const Color(0xffFFD58D), // button color
                                  child: InkWell(
                                      key: const Key('copyKey'),
                                      splashColor: orangeC, // inkwell color
                                      child: const Padding(
                                        padding: EdgeInsets.only(bottom: 0),
                                        child: Image(
                                            image: AssetImage(
                                                'assets/gecko_certify.png')),
                                      ),
                                      onTap: () async {
                                        final bool? _result = await confirmPopup(
                                            context,
                                            "Êtes-vous certain de vouloir certifier l'adresse:\n\n${getShortPubkey(pubkey!)}");

                                        if (_result ?? false) {
                                          String? _pin;
                                          if (_myWalletProvider.pinCode == '') {
                                            _pin = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (homeContext) {
                                                  return UnlockingWallet(
                                                      wallet: defaultWallet);
                                                },
                                              ),
                                            );
                                          }
                                          if (_pin != null ||
                                              _myWalletProvider.pinCode != '') {
                                            WalletsProfilesProvider
                                                _walletViewProvider = Provider
                                                    .of<WalletsProfilesProvider>(
                                                        context,
                                                        listen: false);
                                            final acc = _sub.getCurrentWallet();
                                            _sub.certify(
                                                acc.address!,
                                                _pin ??
                                                    _myWalletProvider.pinCode,
                                                _walletViewProvider.address!);

                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) {
                                                return const TransactionInProgress(
                                                    transType: 'cert');
                                              }),
                                            );
                                          }
                                        }
                                      }),
                                ),
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              "Certifier",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: buttonFontSize,
                                  fontWeight: FontWeight.w500),
                            ),
                          ]),
                        if (snapshot.data!['certDelay'] != null)
                          Column(children: <Widget>[
                            SizedBox(
                              height: buttonSize,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 0),
                                child: Container(
                                  foregroundDecoration: const BoxDecoration(
                                    color: Colors.grey,
                                    backgroundBlendMode: BlendMode.saturation,
                                  ),
                                  child: const Opacity(
                                    opacity: 0.5,
                                    child: Image(
                                        image: AssetImage(
                                            'assets/gecko_certify.png')),
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              "Vous devez attendre\n$_duration avant\nde pouvoir certifier",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: buttonFontSize - 4,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey[600]),
                            ),
                          ]),
                        if (snapshot.data!['certRenewable'] != null)
                          Column(children: <Widget>[
                            SizedBox(
                              height: buttonSize,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 0),
                                child: Container(
                                  foregroundDecoration: const BoxDecoration(
                                    color: Colors.grey,
                                    backgroundBlendMode: BlendMode.saturation,
                                  ),
                                  child: const Opacity(
                                    opacity: 0.5,
                                    child: Image(
                                        image: AssetImage(
                                            'assets/gecko_certify.png')),
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              "Vous pourrez renouveller\ncette certification\ndans $_duration",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: buttonFontSize - 4,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey[600]),
                            ),
                          ]),
                      ]),
                    );
                  },
                );
              }),
              Column(children: <Widget>[
                SizedBox(
                  height: buttonSize,
                  child: ClipOval(
                    child: Material(
                      color: const Color(0xffFFD58D), // button color
                      child: InkWell(
                          key: const Key('copyKey'),
                          splashColor: orangeC, // inkwell color
                          child: const Padding(
                              padding: EdgeInsets.all(20),
                              child: Image(
                                  image: AssetImage('assets/copy_key.png'),
                                  height: 90)),
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: pubkey));
                            snackCopyKey(context);
                          }),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  "Copier\nla clef",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: buttonFontSize, fontWeight: FontWeight.w500),
                ),
              ]),
            ]),
            // FutureBuilder(
            //   future: _walletOptions.generateQRcode(_historyProvider.pubkey),
            //   builder: (context, snapshot) {
            //     return snapshot.data != null
            //         ? GestureDetector(
            //             key: const Key('openQrcode'),
            //             onTap: () {
            //               Navigator.push(
            //                 context,
            //                 MaterialPageRoute(builder: (context) {
            //                   return AvatarFullscreen(
            //                     Image.memory(snapshot.data),
            //                     title: 'QrCode du profil',
            //                     color: Colors.white,
            //                   );
            //                 }),
            //               );
            //             },
            //             child: Image.memory(snapshot.data, height: 60 * ratio),
            //           )
            //         : const Text('-', style: TextStyle(fontSize: 20));
            //   },
            // ),
            const Spacer(),
            Container(
              height: buttonSize,
              decoration: BoxDecoration(
                color: const Color(0xff7c94b6),
                borderRadius: const BorderRadius.all(Radius.circular(100)),
                border: Border.all(
                  color: const Color(0xFF6c4204),
                  width: 4,
                ),
              ),
              child: ClipOval(
                child: Material(
                  color: orangeC, // button color
                  child: InkWell(
                      key: const Key('pay'),
                      splashColor: yellowC, // inkwell color
                      child: const Padding(
                          padding: EdgeInsets.all(14),
                          child: Image(
                            image: AssetImage('assets/vector_white.png'),
                          )),
                      onTap: () {
                        paymentPopup(context, _walletViewProvider);
                      }),
                ),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              "Faire un\nvirement",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: buttonFontSize, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: isTall ? 50 : 20)
          ]),
        ));
  }

  void paymentPopup(
      BuildContext context, WalletsProfilesProvider _walletViewProvider) {
    // WalletsProfilesProvider _walletViewProvider =
    //     Provider.of<WalletsProfilesProvider>(context, listen: false);

    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);
    // SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);

    const double shapeSize = 20;
    WalletData? defaultWallet = _myWalletProvider.getDefaultWallet();
    log.d(defaultWallet.address);

    bool canValidate = false;

    showModalBottomSheet<void>(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(shapeSize),
            topLeft: Radius.circular(shapeSize),
          ),
        ),
        isScrollControlled: true,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            if (_walletViewProvider.payAmount.text != '' &&
                double.parse(_walletViewProvider.payAmount.text) <=
                    balanceCache[defaultWallet.address]! &&
                _walletViewProvider.address != defaultWallet.address) {
              canValidate = true;
            } else {
              canValidate = false;
            }
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                height: 400,
                decoration: const ShapeDecoration(
                  color: Color(0xffffeed1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(shapeSize),
                      topLeft: Radius.circular(shapeSize),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                      top: 24, bottom: 0, left: 24, right: 24),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Effectuer un virement',
                                style: TextStyle(
                                    fontSize: 26, fontWeight: FontWeight.w700),
                              ),
                              IconButton(
                                iconSize: 40,
                                icon: const Icon(Icons.cancel_outlined),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ]),
                        const SizedBox(height: 20),
                        Text(
                          'Depuis:',
                          style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 10),
                        Consumer<SubstrateSdk>(builder: (context, _sub, _) {
                          return InkWell(
                            onTap: () async {
                              String? _pin;
                              if (_myWalletProvider.pinCode == '') {
                                _pin = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (homeContext) {
                                      return UnlockingWallet(
                                          wallet: defaultWallet);
                                    },
                                  ),
                                );
                              }
                              if (_pin != null ||
                                  _myWalletProvider.pinCode != '') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) {
                                    return ChooseWalletScreen(
                                        pin: _pin ?? _myWalletProvider.pinCode);
                                  }),
                                );
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.blueAccent.shade200,
                                    width: 2),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(10.0)),
                              ),
                              padding: const EdgeInsets.all(10),
                              child: Row(children: [
                                Text(defaultWallet.name!),
                                const Spacer(),
                                FutureBuilder(
                                    future:
                                        _sub.getBalance(defaultWallet.address!),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<double> _balance) {
                                      if (_balance.connectionState !=
                                              ConnectionState.done ||
                                          _balance.hasError) {
                                        if (balanceCache[
                                                defaultWallet.address!] !=
                                            null) {
                                          return Text(
                                              balanceCache[
                                                      defaultWallet.address!]
                                                  .toString(),
                                              style: const TextStyle(
                                                fontSize: 20,
                                              ));
                                        } else {
                                          return SizedBox(
                                            height: 15,
                                            width: 15,
                                            child: CircularProgressIndicator(
                                              color: orangeC,
                                              strokeWidth: 2,
                                            ),
                                          );
                                        }
                                      }
                                      balanceCache[defaultWallet.address!] =
                                          _balance.data!;
                                      return Text(
                                        balanceCache[defaultWallet.address]
                                            .toString(),
                                        style: const TextStyle(
                                          fontSize: 20,
                                        ),
                                      );
                                    }),
                              ]),
                            ),
                          );
                        }),
                        const Spacer(),

                        // const SizedBox(height: 10),
                        Text(
                          'Montant:',
                          style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _walletViewProvider.payAmount,
                          autofocus: true,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {
                            // _walletViewProvider.reload();
                          }),
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          // onChanged: (v) => _searchProvider.rebuildWidget(),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            suffix: Text(currencyName),
                            filled: true,
                            fillColor: Colors.transparent,
                            // border: OutlineInputBorder(
                            //     borderSide:
                            //         BorderSide(color: Colors.grey[500], width: 2),
                            //     borderRadius: BorderRadius.circular(8)),

                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.grey[500]!, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.all(20),
                          ),
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // const SizedBox(height: 40),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 4,
                              primary: orangeC, // background
                              onPrimary: Colors.white, // foreground
                            ),
                            onPressed: canValidate
                                ? () async {
                                    String? _pin;
                                    if (_myWalletProvider.pinCode == '') {
                                      _pin = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (homeContext) {
                                            return UnlockingWallet(
                                                wallet: defaultWallet);
                                          },
                                        ),
                                      );
                                    }
                                    log.d(_pin);
                                    if (_pin != null ||
                                        _myWalletProvider.pinCode != '') {
                                      // Payment workflow !
                                      WalletsProfilesProvider
                                          _walletViewProvider =
                                          Provider.of<WalletsProfilesProvider>(
                                              context,
                                              listen: false);
                                      SubstrateSdk _sub =
                                          Provider.of<SubstrateSdk>(context,
                                              listen: false);
                                      final acc = _sub.getCurrentWallet();
                                      log.d(
                                          "fromAddress: ${acc.address!},destAddress: ${_walletViewProvider.address!}, amount: ${double.parse(_walletViewProvider.payAmount.text)},  password: $_pin");
                                      _sub.pay(
                                          fromAddress: acc.address!,
                                          destAddress:
                                              _walletViewProvider.address!,
                                          amount: double.parse(
                                              _walletViewProvider
                                                  .payAmount.text),
                                          password: _pin ??
                                              _myWalletProvider.pinCode);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) {
                                          return const TransactionInProgress();
                                        }),
                                      );
                                    }
                                  }
                                : null,
                            child: const Text(
                              'Effectuer le virement',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const Spacer(),
                      ]),
                ),
              ),
            );
          });
        }).then((value) => _walletViewProvider.payAmount.text = '');
  }

  Widget headerProfileView(
      BuildContext context,
      WalletsProfilesProvider _historyProvider,
      CesiumPlusProvider _cesiumPlusProvider) {
    const double _avatarSize = 140;

    WalletOptionsProvider _walletOptions =
        Provider.of<WalletOptionsProvider>(context, listen: false);
    // SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);

    bool isAccountExist = balanceCache[pubkey] != 0;

    return Stack(children: <Widget>[
      Consumer<SubstrateSdk>(builder: (context, _sub, _) {
        return Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  isAccountExist ? yellowC : Colors.grey[400]!,
                  isAccountExist ? const Color(0xFFE7811A) : Colors.grey[600]!,
                ],
              ),
            ));
      }),
      Padding(
        padding: const EdgeInsets.only(left: 30, right: 40),
        child: Row(children: <Widget>[
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: 10,
                  color: yellowC, // Colors.grey[400],
                ),
                Row(children: [
                  GestureDetector(
                    key: const Key('copyPubkey'),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: pubkey));
                      snackCopyKey(context);
                    },
                    child: Text(
                      getShortPubkey(pubkey!),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 25),

                balance(context, pubkey!, 22),
                const SizedBox(height: 10),
                _walletOptions.idtyStatus(context, pubkey!,
                    isOwner: false, color: Colors.black),
                getCerts(context, pubkey!, 14),

                // if (username == null &&
                //     g1WalletsBox.get(pubkey)?.username == null)
                //   Query(
                //     options: QueryOptions(
                //       document: gql(getId),
                //       variables: {
                //         'pubkey': pubkey,
                //       },
                //     ),
                //     builder: (QueryResult result,
                //         {VoidCallback? refetch, FetchMore? fetchMore}) {
                //       if (result.isLoading || result.hasException) {
                //         return const Text('...');
                //       } else if (result.data!['idty'] == null ||
                //           result.data!['idty']['username'] == null) {
                //         g1WalletsBox.get(pubkey)?.username = '';
                //         return const Text('');
                //       } else {
                //         g1WalletsBox.get(pubkey)?.username =
                //             result.data!['idty']['username'] ?? '';
                //         return SizedBox(
                //           width: 230,
                //           child: Text(
                //             result.data!['idty']['username'] ?? '',
                //             style: const TextStyle(
                //               fontSize: 27,
                //               color: Color(0xff814C00),
                //             ),
                //           ),
                //         );
                //       }
                //     },
                //   ),
                if (username == null &&
                    g1WalletsBox.get(pubkey)?.username != null)
                  SizedBox(
                    width: 230,
                    child: Text(
                      g1WalletsBox.get(pubkey)?.username ?? '',
                      style: const TextStyle(
                        fontSize: 27,
                        color: Color(0xff814C00),
                      ),
                    ),
                  ),
                if (username != null)
                  SizedBox(
                    width: 230,
                    child: Text(
                      username!,
                      style: const TextStyle(
                        fontSize: 27,
                        color: Color(0xff814C00),
                      ),
                    ),
                  ),
                const SizedBox(height: 25),
                //// To get Cs+ name
                // FutureBuilder(
                //     future: _cesiumPlusProvider.getName(pubkey),
                //     initialData: '...',
                //     builder: (context, snapshot) {
                //       return SizedBox(
                //         width: 230,
                //         child: Text(
                //           snapshot.data.toString(),
                //           style: const TextStyle(
                //               fontSize: 18, color: Colors.black),
                //         ),
                //       );
                //     }),
                const SizedBox(height: 30),
              ]),
          const Spacer(),
          Column(children: <Widget>[
            if (avatar == null)
              ClipOval(
                child: _cesiumPlusProvider.defaultAvatar(_avatarSize),
              ),
            // FutureBuilder(
            //     future: _cesiumPlusProvider.getAvatar(pubkey, _avatarSize),
            //     builder:
            //         (BuildContext context, AsyncSnapshot<Image?> _avatar) {
            //       if (_avatar.connectionState != ConnectionState.done) {
            //         return Stack(children: [
            //           ClipOval(
            //             child:
            //                 _cesiumPlusProvider.defaultAvatar(_avatarSize),
            //           ),
            //           Positioned(
            //             top: 15,
            //             right: 45,
            //             width: 51,
            //             height: 51,
            //             child: CircularProgressIndicator(
            //               strokeWidth: 5,
            //               color: orangeC,
            //             ),
            //           ),
            //         ]);
            //       }
            //       if (_avatar.hasData) {
            //         return GestureDetector(
            //           key: const Key('openAvatar'),
            //           onTap: () {
            //             Navigator.push(
            //               context,
            //               MaterialPageRoute(builder: (context) {
            //                 return AvatarFullscreen(_avatar.data);
            //               }),
            //             );
            //           },
            //           child: ClipOval(
            //             child: Image(
            //               image: _avatar.data!.image,
            //               height: _avatarSize,
            //               fit: BoxFit.cover,
            //             ),
            //           ),
            //         );
            //       }
            //       return ClipOval(
            //         child: _cesiumPlusProvider.defaultAvatar(_avatarSize),
            //       );
            //     }),
            if (avatar != null)
              GestureDetector(
                key: const Key('openAvatar'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) {
                      return AvatarFullscreen(avatar);
                    }),
                  );
                },
                child: ClipOval(
                  child: Image(
                    image: avatar!.image,
                    height: _avatarSize,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 25),
          ]),
        ]),
      ),
    ]);
  }
}
