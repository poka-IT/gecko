import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/cesium_plus.dart';
import 'package:gecko/models/wallets_profiles.dart';
import 'package:gecko/models/queries.dart';
// import 'package:gecko/models/wallet_options.dart';
import 'package:gecko/screens/avatar_fullscreen.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';

class WalletViewScreen extends StatelessWidget {
  const WalletViewScreen({this.pubkey, this.username, this.avatar, Key key})
      : super(key: key);
  final String pubkey;
  final String username;
  final Image avatar;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    WalletsProfilesProvider _historyProvider =
        Provider.of<WalletsProfilesProvider>(context);
    CesiumPlusProvider _cesiumPlusProvider =
        Provider.of<CesiumPlusProvider>(context);
    // WalletOptionsProvider _walletOptions = WalletOptionsProvider();
    double _avatarSize = 150;

    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          toolbarHeight: 60 * ratio,
          title: const SizedBox(
            height: 22,
            child: Text('Voir un portefeuille'),
          ),
          // actions: [
          //   FutureBuilder(
          //     future: _walletOptions.generateQRcode(_historyProvider.pubkey),
          //     builder: (context, snapshot) {
          //       return snapshot.data != null
          //           ? GestureDetector(
          //               key: const Key('openAvatar'),
          //               onTap: () {
          //                 Navigator.push(
          //                   context,
          //                   MaterialPageRoute(builder: (context) {
          //                     return AvatarFullscreen(
          //                       Image.memory(snapshot.data),
          //                       title: 'QrCode du profil',
          //                     );
          //                   }),
          //                 );
          //                 // isAvatarView = !isAvatarView;
          //                 // _historyProvider.resetdHistory();
          //               },
          //               child: Image.memory(snapshot.data, height: 40 * ratio),
          //             )
          //           : const Text('-', style: TextStyle(fontSize: 20));
          //     },
          //   ),
          //   const SizedBox(width: 75)
          // ],
        ),
        body: SafeArea(
          child: Column(children: <Widget>[
            Container(
              height: 10,
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
                        Row(children: [
                          GestureDetector(
                            key: const Key('copyPubkey'),
                            onTap: () {
                              Clipboard.setData(ClipboardData(
                                  text: pubkey ?? _historyProvider.pubkey));
                              _historyProvider.snackCopyKey(context);
                            },
                            child: Text(
                              _historyProvider.getShortPubkey(
                                  pubkey ?? _historyProvider.pubkey),
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        if (username == null)
                          Query(
                            options: QueryOptions(
                              document: gql(getId),
                              variables: {
                                'pubkey': _historyProvider.pubkey,
                              },
                            ),
                            builder: (QueryResult result,
                                {VoidCallback refetch, FetchMore fetchMore}) {
                              if (result.isLoading || result.hasException) {
                                return const Text('...');
                              } else if (result.data['idty'] == null ||
                                  result.data['idty']['username'] == null) {
                                return const Text('');
                              } else {
                                return SizedBox(
                                  width: 230,
                                  child: Text(
                                    result?.data['idty']['username'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 27,
                                      color: Color(0xff814C00),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        if (username != null)
                          Text(
                            username,
                            style: const TextStyle(
                              fontSize: 27,
                              color: Color(0xff814C00),
                            ),
                          ),
                        const SizedBox(height: 25),
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
                                      fontSize: 18, color: Colors.black),
                                ),
                              );
                            }),
                        const SizedBox(height: 30),
                      ]),
                  const Spacer(),
                  Column(children: <Widget>[
                    if (avatar == null)
                      FutureBuilder(
                          future: _cesiumPlusProvider.getAvatar(
                              _historyProvider.pubkey, _avatarSize),
                          builder: (BuildContext context,
                              AsyncSnapshot<Image> _avatar) {
                            if (_avatar.connectionState !=
                                    ConnectionState.done ||
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
                              return GestureDetector(
                                key: const Key('openAvatar'),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) {
                                      return AvatarFullscreen(_avatar.data);
                                    }),
                                  );
                                },
                                child: ClipOval(
                                  child: _avatar.data,
                                ),
                              );
                            }
                            return ClipOval(
                              child: _cesiumPlusProvider
                                  .defaultAvatar(_avatarSize),
                            );
                          }),
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
                            image: avatar.image,
                            height: _avatarSize,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    const SizedBox(height: 25),
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
