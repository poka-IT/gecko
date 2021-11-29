import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/cesium_plus.dart';
import 'package:gecko/models/history.dart';
import 'package:provider/provider.dart';
// import 'package:gecko/models/home.dart';
// import 'package:provider/provider.dart';

// ignore: must_be_immutable
class WalletViewScreen extends StatelessWidget {
  TextEditingController tplController = TextEditingController();

  WalletViewScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    HistoryProvider _historyProvider = Provider.of<HistoryProvider>(context);
    CesiumPlusProvider _cesiumPlusProvider =
        Provider.of<CesiumPlusProvider>(context);
    double _avatarSize = 150;

    return Scaffold(
        appBar: AppBar(
            elevation: 0,
            toolbarHeight: 60 * ratio,
            title: const SizedBox(
              height: 22,
              child: Text('Voir un portefeuille'),
            )),
        body: SafeArea(
          child: Column(children: <Widget>[
            Container(
              height: isTall ? 30 : 10,
              color: yellowC,
            ),
            Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  yellowC,
                  const Color(0xFFE7811A),
                ],
              )),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Row(children: <Widget>[
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        GestureDetector(
                          key: const Key('copyPubkey'),
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: _historyProvider.pubkey));
                            _historyProvider.snackCopyKey(context);
                          },
                          child: Text(
                            _historyProvider
                                .getShortPubkey(_historyProvider.pubkey),
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        FutureBuilder(
                            future: _cesiumPlusProvider
                                .getName(_historyProvider.pubkey),
                            initialData: '...',
                            builder: (context, snapshot) {
                              return SizedBox(
                                width: 230,
                                child: Text(
                                  snapshot.data ?? '-',
                                  style: const TextStyle(
                                      fontSize: 20, color: Color(0xff814C00)),
                                ),
                              );
                            }),
                        const SizedBox(height: 30),
                      ]),
                  const Spacer(),
                  Column(children: <Widget>[
                    FutureBuilder(
                        future: _cesiumPlusProvider.getAvatar(
                            _historyProvider.pubkey, _avatarSize),
                        builder: (BuildContext context,
                            AsyncSnapshot<Image> _avatar) {
                          if (_avatar.connectionState != ConnectionState.done ||
                              _avatar.hasError) {
                            return Stack(children: [
                              ClipOval(
                                child: _cesiumPlusProvider
                                    .defaultAvatar(_avatarSize),
                              ),
                              Positioned(
                                top: 16.5,
                                right: 47.5,
                                width: 55,
                                height: 55,
                                child: CircularProgressIndicator(
                                  strokeWidth: 6,
                                  color: orangeC,
                                ),
                              ),
                            ]);
                          }
                          if (_avatar.hasData) {
                            return ClipOval(
                              child: _avatar.data,
                            );
                          }
                          return ClipOval(
                            child:
                                _cesiumPlusProvider.defaultAvatar(_avatarSize),
                          );
                        }),
                    const SizedBox(height: 30),
                  ]),
                ]),
              ),
            ),
            SizedBox(height: isTall ? 60 : 30),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              Column(children: <Widget>[
                SizedBox(
                  height: 120,
                  child: ClipOval(
                    child: Material(
                      color: const Color(0xffFFD58D), // button color
                      child: InkWell(
                          key: const Key('viewHistory'),
                          splashColor: orangeC, // inkwell color
                          child: const Padding(
                              padding: EdgeInsets.all(15),
                              child: Image(
                                  image: AssetImage(
                                      'assets/walletOptions/clock.png'),
                                  height: 90)),
                          onTap: () {
                            null;
                          }),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  "Voir\nl'historique",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
              ]),
              Column(children: <Widget>[
                SizedBox(
                  height: 120,
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
                            Clipboard.setData(
                                ClipboardData(text: _historyProvider.pubkey));
                            _historyProvider.snackCopyKey(context);
                          }),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  "Copier\nla clef",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
              ]),
            ]),
            const Spacer(),
            Container(
              height: 120,
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
                          padding: EdgeInsets.all(16),
                          child: Image(
                            image: AssetImage('assets/vector_white.png'),
                          )),
                      onTap: () {
                        null;
                      }),
                ),
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              "Faire un\nvirement",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: isTall ? 100 : 50)
          ]),
        ));
  }
}
