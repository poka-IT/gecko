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
  int currentIndex = 0;
  Widget currentScreen;

  void onTabTapped(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  Uint8List bytes = Uint8List(0);
  final TextEditingController _outputPubkey = new TextEditingController();
  final nRepositories = 20;

  String pubkey = 'D2meevcAHFTS2gQMvmRW5Hzi25jDdikk4nC4u1FkwRaU'; // For debug
  // String pubkey = '';
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
    return Column(children: <Widget>[
      TextField(
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
            hintStyle: TextStyle(fontSize: 15),
            contentPadding: EdgeInsets.symmetric(horizontal: 7, vertical: 15),
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
          ),
          style: TextStyle(
              fontSize: 15.0,
              color: Colors.black,
              fontWeight: FontWeight.bold)),
      historyQuery(),
    ]);
  }

  Expanded historyQuery() {
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
              return Text('\nErrors: \n  ' + result.exception.toString());
            }

            if (result.data == null && result.exception.toString() == null) {
              return const Text('Both data and errors are null');
            }

            final List<dynamic> blockchainTX =
                (result.data['txsHistoryBc']['both']['edges'] as List<dynamic>);

            final Map pageInfo =
                result.data['txsHistoryBc']['both']['pageInfo'];

            final String fetchMoreCursor = pageInfo['endCursor'];

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

            return Expanded(
                child: ListView(
              controller: _scrollController,
              children: <Widget>[
                for (var repository in _transBC)
                  ListTile(
                      contentPadding: const EdgeInsets.all(5.0),
                      leading: Text(repository[3].toString()),
                      title: Text(repository[1].toString() +
                          '\n' +
                          truncate(repository[2], 17,
                              omission: "...", position: TruncatePosition.end)),
                      subtitle: Text(repository[5]),
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
    }
    // this._outputPubkey.text = "";
    if (barcode != null) {
      this._outputPubkey.text = barcode;
      isPubkey(barcode);
      onTabTapped(0);
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

      return pubkey;
    }

    return '';
  }
}
