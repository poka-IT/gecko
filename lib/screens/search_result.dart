import 'dart:io';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/cesium_plus.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/history.dart';
import 'package:gecko/models/search.dart';
import 'package:provider/provider.dart';

class SearchResultScreen extends StatelessWidget {
  const SearchResultScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SearchProvider _searchProvider = Provider.of<SearchProvider>(context);
    CesiumPlusProvider _cesiumPlusProvider =
        Provider.of<CesiumPlusProvider>(context);
    HistoryProvider _historyClass =
        Provider.of<HistoryProvider>(context, listen: false);

    // int nbrResult = 0;
    int keyID = 0;
    const double avatarsSize = 50;

    // _searchProvider.searchPubkey();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60 * ratio,
        title: const SizedBox(
          height: 22,
          child: Text('Résultats de votre recherche'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: <
                  Widget>[
            const SizedBox(height: 30),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[700],
                ),
                children: <TextSpan>[
                  const TextSpan(
                    text: "Résultats pour ",
                  ),
                  TextSpan(
                    text: '"${_searchProvider.searchController.text}"',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Dans la blockchain Ğ1',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            FutureBuilder(
              future: _searchProvider.searchBlockchain(),
              // initialData: const [],
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Expanded(
                    child: ListView(children: <Widget>[
                      for (G1WalletsList g1Wallet in snapshot.data)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: ListTile(
                              key: Key('searchResult${keyID++}'),
                              contentPadding: const EdgeInsets.all(5),
                              leading: FutureBuilder(
                                  future: _cesiumPlusProvider
                                      .getAvatar(g1Wallet.pubkey),
                                  initialData: [
                                    File(appPath.path + '/default_avatar.png')
                                  ],
                                  builder: (BuildContext context,
                                      AsyncSnapshot<List> _avatar) {
                                    if (_avatar.connectionState !=
                                        ConnectionState.done) {
                                      return Image.file(
                                          File(appPath.path +
                                              '/default_avatar.png'),
                                          height: avatarsSize);
                                    }
                                    if (_avatar.hasError) {
                                      return Image.file(
                                          File(appPath.path +
                                              '/default_avatar.png'),
                                          height: avatarsSize);
                                    }
                                    if (_avatar.hasData) {
                                      return SingleChildScrollView(
                                          padding: const EdgeInsets.all(0.0),
                                          child: Image.file(_avatar.data.single,
                                              height: avatarsSize));
                                    }
                                    return Image.file(
                                        File(appPath.path +
                                            '/default_avatar.png'),
                                        height: avatarsSize);
                                  }),
                              title: Text(
                                  _historyClass.getShortPubkey(g1Wallet.pubkey),
                                  style: const TextStyle(
                                      fontSize: 15.0, fontFamily: 'Monospace'),
                                  textAlign: TextAlign.center),
                              subtitle: Text(g1Wallet?.id?.username ?? '',
                                  style: const TextStyle(fontSize: 12.0),
                                  textAlign: TextAlign.center),
                              trailing: Text("${g1Wallet.balance} Ğ1",
                                  style: const TextStyle(fontSize: 14.0),
                                  textAlign: TextAlign.justify),
                              dense: false,
                              isThreeLine: false,
                              onTap: () {
                                _historyClass.isPubkey(
                                    context, g1Wallet.pubkey);
                              }),
                        ),
                    ]),
                  );
                }
                return Center(
                  heightFactor: 5,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    backgroundColor: yellowC,
                    color: orangeC,
                  ),
                );
              },
            ),
            // Text(
            //   _searchProvider.searchResult.toString(),
            // )
          ]),
        ),
      ),
    );
  }
}
