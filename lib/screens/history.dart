import 'package:gecko/models/parsingGVA.dart';
import 'package:gecko/models/query.dart';
import 'package:gecko/models/history.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:truncate/truncate.dart';

// ignore: must_be_immutable
class HistoryScreen extends StatelessWidget with ChangeNotifier {
  final TextEditingController _outputPubkey = TextEditingController();
  ScrollController scrollController = ScrollController();
  final nRepositories = 20;
  // HistoryProvider _historyProvider;
  bool isTheEnd = false;
  List _transBC;

  FetchMore fetchMore;
  FetchMoreOptions opts;

  @override
  Widget build(BuildContext context) {
    HistoryProvider _historyProvider = Provider.of<HistoryProvider>(context);
    this._outputPubkey.text = _historyProvider.pubkey;
    print('Build pubkey : ' + _historyProvider.pubkey);
    return Scaffold(
        floatingActionButton: Container(
          height: 80.0,
          width: 80.0,
          child: FittedBox(
            child: FloatingActionButton(
              heroTag: "buttonScan",
              onPressed: () async {
                await _historyProvider.scan();
              },
              child: Container(
                  height: 40.0,
                  width: 40.0,
                  child: Image.asset('images/scanner.png')),
              backgroundColor: Color(
                  0xffEFEFBF), //Color(0xffFFD68E), //Color.fromARGB(500, 204, 255, 255),
            ),
          ),
        ),
        body: Column(children: <Widget>[
          SizedBox(height: 8),
          TextField(
              // Entrée de la pubkey
              onChanged: (text) {
                print("Clé tappxé: $text");
                _historyProvider.isPubkey(text);
              },
              controller: this._outputPubkey,
              maxLines: 1,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Tappez/Collez une clé publique, ou scannez',
                hintStyle: TextStyle(fontSize: 14),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 7, vertical: 15),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
              style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold)),
          if (_historyProvider.pubkey != '') historyQuery(context),
        ]));
  }

  historyQuery(context) {
    HistoryProvider _historyProvider = Provider.of<HistoryProvider>(context);
    return Expanded(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Query(
          options: QueryOptions(
            document: gql(getHistory),
            variables: <String, dynamic>{
              'pubkey': _historyProvider.pubkey,
              'number': nRepositories,
              'cursor': null
            },
          ),
          builder: (QueryResult result, {refetch, fetchMore}) {
            if (result.isLoading && result.data == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (result.hasException) {
              print('Error GVA: ' + result.exception.toString());
              return Column(children: <Widget>[
                SizedBox(height: 50),
                Text(
                  "Aucun noeud GVA valide n'a pu être trouvé.\nVeuillez réessayer ultérieurement.",
                  style: TextStyle(fontSize: 17.0),
                )
              ]);
            }

            if (result.data == null && result.exception.toString() == null) {
              return const Text('Aucune donnée à afficher.');
            }

            final List<dynamic> blockchainTX =
                (result.data['txsHistoryBc']['both']['edges'] as List<dynamic>);

            final Map pageInfo =
                result.data['txsHistoryBc']['both']['pageInfo'];

            final String fetchMoreCursor = pageInfo['endCursor'];

            final num balance =
                removeDecimalZero(result.data['balance']['amount'] / 100);

            if (fetchMoreCursor != null) {
              opts = FetchMoreOptions(
                variables: {'cursor': fetchMoreCursor},
                updateQuery: (previousResultData, fetchMoreResultData) {
                  final List<dynamic> repos = [
                    ...previousResultData['txsHistoryBc']['both']['edges']
                        as List<dynamic>,
                    ...fetchMoreResultData['txsHistoryBc']['both']['edges']
                        as List<dynamic>
                  ];

                  fetchMoreResultData['txsHistoryBc']['both']['edges'] = repos;
                  return fetchMoreResultData;
                },
              );
            }

            print(
                "###### DEBUG H Parse blockchainTX list. Cursor: $fetchMoreCursor ######");
            if (fetchMoreCursor != null) {
              _transBC = parseHistory(blockchainTX);
              isTheEnd = false;
            } else {
              print("###### DEBUG H - Début de l'historique");
              isTheEnd = true;
            }

            // Build history list
            return NotificationListener(
                child: Expanded(
                    child: ListView(
                  controller: scrollController,
                  children: <Widget>[
                    SizedBox(height: 7),
                    if (_historyProvider.pubkey != '')
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(width: 32.0, height: 0.0),
                            Text(balance.toString() + ' Ğ1',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 30.0)),
                            Container(
                                padding: const EdgeInsets.only(right: 80),
                                child: Text("Payer")),
                          ]),
                    SizedBox(height: 12),
                    for (var repository in _transBC)
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: ListTile(
                              contentPadding: const EdgeInsets.all(5.0),
                              leading: Text(repository[1].toString(),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.w700),
                                  textAlign: TextAlign.center),
                              title: Text(repository[5],
                                  style: TextStyle(fontSize: 14.0),
                                  textAlign: TextAlign.center),
                              subtitle: Text(
                                  truncate(repository[2], 20,
                                      omission: "...",
                                      position: TruncatePosition.end),
                                  style: TextStyle(fontSize: 11.0),
                                  textAlign: TextAlign.center),
                              trailing: Text("${repository[3]} Ğ1",
                                  style: TextStyle(fontSize: 14.0),
                                  textAlign: TextAlign.justify),
                              dense: true,
                              isThreeLine: false,
                              onTap: () {
                                // this._outputPubkey.text = repository[2];
                                _historyProvider.isPubkey(repository[2]);
                              })),
                    if (result.isLoading)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          CircularProgressIndicator(),
                        ],
                      ),
                    if (isTheEnd)
                      Column(children: <Widget>[
                        SizedBox(height: 15),
                        Text("Début de l'historique.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20)),
                        SizedBox(height: 15)
                      ])
                  ],
                )),
                onNotification: (t) {
                  if (t is ScrollEndNotification &&
                      scrollController.position.pixels >=
                          scrollController.position.maxScrollExtent * 0.7) {
                    fetchMore(opts);
                  }
                  return true;
                });
          },
        ),
      ],
    ));
  }

  num removeDecimalZero(double n) {
    String result = n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 1);
    return num.parse(result);
  }
}
