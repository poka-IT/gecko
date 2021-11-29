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

    int keyID = 0;
    double _avatarSize = 55;

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
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
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
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return Expanded(
                        child: ListView(children: <Widget>[
                          for (G1WalletsList g1Wallet in snapshot.data)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              child: ListTile(
                                  key: Key('searchResult${keyID++}'),
                                  horizontalTitleGap: 40,
                                  contentPadding: const EdgeInsets.all(5),
                                  leading: FutureBuilder(
                                      future: _cesiumPlusProvider.getAvatar(
                                          g1Wallet.pubkey, _avatarSize),
                                      builder: (BuildContext context,
                                          AsyncSnapshot<Image> _avatar) {
                                        if (_avatar.connectionState !=
                                                ConnectionState.done ||
                                            _avatar.hasError) {
                                          return Stack(children: [
                                            _cesiumPlusProvider
                                                .defaultAvatar(_avatarSize),
                                            Positioned(
                                              top: 8,
                                              right: 0,
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 1,
                                                color: orangeC,
                                              ),
                                            ),
                                          ]);
                                        }
                                        if (_avatar.hasData) {
                                          return ClipOval(child: _avatar.data);
                                        }
                                        return _cesiumPlusProvider
                                            .defaultAvatar(_avatarSize);
                                      }),
                                  title: Row(children: <Widget>[
                                    Text(
                                        _historyClass
                                            .getShortPubkey(g1Wallet.pubkey),
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontFamily: 'Monospace',
                                            fontWeight: FontWeight.w500),
                                        textAlign: TextAlign.center),
                                  ]),
                                  subtitle: Row(children: <Widget>[
                                    Text(g1Wallet?.id?.username ?? '',
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500),
                                        textAlign: TextAlign.center),
                                  ]),
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
