import 'package:gecko/parsingGVA.dart';
import 'package:gecko/query.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:qrscan/qrscan.dart' as scanner;
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sentry/sentry.dart' as sentry;
import 'package:truncate/truncate.dart';

//ignore: must_be_immutable
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key keyHistory}) : super(key: keyHistory);

  @override
  State<StatefulWidget> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  Widget currentScreen;

  Uint8List bytes = Uint8List(0);
  final TextEditingController _outputPubkey = new TextEditingController();
  final nRepositories = 20;

  // String pubkey = 'D2meevcAHFTS2gQMvmRW5Hzi25jDdikk4nC4u1FkwRaU'; // For debug
  String pubkey = '';
  bool isBuilding = true;
  ScrollController _scrollController = new ScrollController();

  _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      setState(() {
        print("reach the bottom");
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    // _scrollController
    //   ..addListener(() {
    //     if (_scrollController.position.pixels ==
    //         _scrollController.position.maxScrollExtent) {
    //       // print(
    //       //     "DEBUG H fetchMoreCursor in scrollController: $fetchMoreCursor");
    //       fetchMore(opts);
    //     }
    //   });
  }

  @override
  Widget build(BuildContext context) {
    print('Build pubkey : ' + pubkey);
    print('Build this.pubkey : ' + this.pubkey);
    print('isBuilding: ' + isBuilding.toString());
    return Scaffold(
        floatingActionButton: Container(
          height: 80.0,
          width: 80.0,
          child: FittedBox(
            child: FloatingActionButton(
              heroTag: "buttonScan",
              onPressed: () async {
                await scan();
                // print(resultScan);
                // if (resultScan != 'false') {
                //   onTabTapped(0);
                // }
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
                this.pubkey = text;
                isPubkey(text);
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
          if (this.pubkey != '') historyQuery(),
        ]));
  }

  historyQuery() {
    return Expanded(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Query(
          options: QueryOptions(
            document: gql(getHistory),
            variables: <String, dynamic>{
              'pubkey': this.pubkey,
              'number': nRepositories,
              // set cursor to null so as to start at the beginning
              'cursor': null
            },
          ),
          builder: (QueryResult result, {refetch, FetchMore fetchMore}) {
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

            FetchMoreOptions opts = FetchMoreOptions(
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

            // _scrollController
            //   ..addListener(() {
            //     if (_scrollController.position.pixels ==
            //         _scrollController.position.maxScrollExtent) {
            //       if (!result.isLoading) {
            //         print(
            //             "DEBUG H fetchMoreCursor in scrollController: $fetchMoreCursor");
            //         fetchMore(opts);
            //       }
            //     }
            //   });

            // s/o : https://stackoverflow.com/questions/54065354/how-to-detect-scroll-position-of-listview-in-flutter/54188385#54188385
            // new NotificationListener(
            //   child: new ListView(
            //     controller: _scrollController,
            //   ),
            //   onNotification: (t) {
            //     if (t is ScrollEndNotification) {
            //       fetchMore(opts);
            //     }
            //   },
            // );

            // fetchMore(opts);

            print(
                "###### DEBUG H Parse blockchainTX list. Cursor: $fetchMoreCursor ######");
            List _transBC = parseHistory(blockchainTX);

            // Build history list
            return Expanded(
                child: ListView(
              controller: _scrollController,
              children: <Widget>[
                SizedBox(height: 7),
                if (this.pubkey != '')
                  Text(balance.toString() + ' Ğ1',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 30.0)),
                SizedBox(height: 12),
                for (var repository in _transBC)
                  ListTile(
                      contentPadding: const EdgeInsets.all(5.0),
                      leading:
                          Text(repository[3], style: TextStyle(fontSize: 14.0)),
                      title: Text(
                          repository[1].toString() +
                              '\n' +
                              truncate(repository[2], 17,
                                  omission: "...",
                                  position: TruncatePosition.end),
                          style: TextStyle(fontSize: 14.0)),
                      subtitle:
                          Text(repository[5], style: TextStyle(fontSize: 14.0)),
                      dense: true,
                      onTap: () {
                        isPubkey(repository[2]);
                      }),
                if (result.isLoading)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      CircularProgressIndicator(),
                    ],
                  ),
              ],
            ));
          },
        ),
      ],
    ));
  }

  Future scan() async {
    await Permission.camera.request();
    String barcode;
    try {
      barcode = await scanner.scan();
    } catch (e, stack) {
      print(e);
      if (kReleaseMode) {
        await sentry.Sentry.captureException(
          e,
          stackTrace: stack,
        );
      }
      return 'false';
    }
    // this._outputPubkey.text = "";
    if (barcode != null) {
      this._outputPubkey.text = barcode;
      isPubkey(barcode);
    } else {
      return 'false';
    }
    return barcode;
  }

  String isPubkey(pubkey) {
    final RegExp regExp = new RegExp(
      r'^[a-zA-Z0-9]+$',
      caseSensitive: false,
      multiLine: false,
    );

    if (regExp.hasMatch(pubkey) == true &&
        pubkey.length > 42 &&
        pubkey.length < 45) {
      print("C'est une pubkey !!!");

      setState(() {
        this.pubkey = pubkey;
        this._outputPubkey.text = pubkey;
      });

      // setState(() {
      //   this._outputBalance.text = balance.toString();
      // });

      return pubkey;
    }

    return '';
  }

  num removeDecimalZero(double n) {
    String result = n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 1);
    return num.parse(result);
  }
}
