import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/cesium_plus.dart';
import 'package:gecko/models/wallets_profiles.dart';
import 'package:gecko/models/queries.dart';
import 'package:gecko/screens/avatar_fullscreen.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/history.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';

class WalletViewScreen extends StatelessWidget {
  const WalletViewScreen(
      {@required this.pubkey, this.username, this.avatar, Key key})
      : super(key: key);
  final String pubkey;
  final String username;
  final Image avatar;
  final double buttonSize = 100;
  final double buttonFontSize = 18;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    WalletsProfilesProvider _historyProvider =
        Provider.of<WalletsProfilesProvider>(context, listen: false);
    CesiumPlusProvider _cesiumPlusProvider =
        Provider.of<CesiumPlusProvider>(context, listen: false);

    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          toolbarHeight: 60 * ratio,
          title: const SizedBox(
            height: 22,
            child: Text('Voir un portefeuille'),
          ),
        ),
        body: SafeArea(
          child: Column(children: <Widget>[
            headerProfileView(context, _historyProvider, _cesiumPlusProvider),
            SizedBox(height: isTall ? 120 : 70),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              Column(children: <Widget>[
                SizedBox(
                  height: buttonSize,
                  child: ClipOval(
                    child: Material(
                      color: const Color(0xffFFD58D), // button color
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
                            Navigator.push(
                              context,
                              FaderTransition(
                                  page: HistoryScreen(
                                    pubkey: pubkey,
                                    username: username ??
                                        g1WalletsBox.get(pubkey)?.username,
                                    avatar: avatar ??
                                        g1WalletsBox.get(pubkey)?.avatar,
                                  ),
                                  isFast: false),
                            );
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
                            _historyProvider.snackCopyKey(context);
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
                        null;
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
            SizedBox(height: isTall ? 120 : 70)
          ]),
        ));
  }

  Widget headerProfileView(
      BuildContext context,
      WalletsProfilesProvider _historyProvider,
      CesiumPlusProvider _cesiumPlusProvider) {
    const double _avatarSize = 140;

    return Column(children: <Widget>[
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
          padding: const EdgeInsets.only(left: 30, right: 40),
          child: Row(children: <Widget>[
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(children: [
                    GestureDetector(
                      key: const Key('copyPubkey'),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: pubkey));
                        _historyProvider.snackCopyKey(context);
                      },
                      child: Text(
                        _historyProvider.getShortPubkey(pubkey),
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  if (username == null &&
                      g1WalletsBox.get(pubkey)?.username == null)
                    Query(
                      options: QueryOptions(
                        document: gql(getId),
                        variables: {
                          'pubkey': pubkey,
                        },
                      ),
                      builder: (QueryResult result,
                          {VoidCallback refetch, FetchMore fetchMore}) {
                        if (result.isLoading || result.hasException) {
                          return const Text('...');
                        } else if (result.data['idty'] == null ||
                            result.data['idty']['username'] == null) {
                          g1WalletsBox.get(pubkey)?.username = '';
                          return const Text('');
                        } else {
                          g1WalletsBox.get(pubkey)?.username =
                              result?.data['idty']['username'] ?? '';
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
                  if (username == null &&
                      g1WalletsBox.get(pubkey)?.username != null)
                    SizedBox(
                      width: 230,
                      child: Text(
                        g1WalletsBox.get(pubkey)?.username,
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
                        username,
                        style: const TextStyle(
                          fontSize: 27,
                          color: Color(0xff814C00),
                        ),
                      ),
                    ),
                  const SizedBox(height: 25),
                  FutureBuilder(
                      future: _cesiumPlusProvider.getName(pubkey),
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
                    future: _cesiumPlusProvider.getAvatar(pubkey, _avatarSize),
                    builder:
                        (BuildContext context, AsyncSnapshot<Image> _avatar) {
                      if (_avatar.connectionState != ConnectionState.done) {
                        return Stack(children: [
                          ClipOval(
                            child:
                                _cesiumPlusProvider.defaultAvatar(_avatarSize),
                          ),
                          Positioned(
                            top: 15,
                            right: 45,
                            width: 51,
                            height: 51,
                            child: CircularProgressIndicator(
                              strokeWidth: 5,
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
                            child: Image(
                              image: _avatar.data.image,
                              height: _avatarSize,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      }
                      return ClipOval(
                        child: _cesiumPlusProvider.defaultAvatar(_avatarSize),
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
    ]);
  }
}
