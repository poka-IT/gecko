import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:permission_handler/permission_handler.dart';
import 'package:qrscan/qrscan.dart' as scanner;
import 'api.dart';
import "package:dio/dio.dart";
import 'package:graphql_flutter/graphql_flutter.dart';
import 'query.dart';

/// Integrates a list of articles with [ListPreferencesScreen].
class HistoryListScreen extends StatefulWidget {
  @override
  _HistoryListScreenState createState() => _HistoryListScreenState();
}

// class HistoryListScreen extends StatefulWidget {
//   // GeckoHome({Key key, this.title}) : super(key: key);
//   // final String title;

//   const HistoryListScreen({
//     @required this.repository,
// final String title,
//     Key key,
//   })  : assert(repository != null),
//         super(key: key);

//   final Repository repository;

//   @override
//   _GeckoHomeState createState() => _GeckoHomeState();
// }

class _HistoryListScreenState extends State<HistoryListScreen> {
  Uint8List bytes = Uint8List(0);
  TextEditingController _outputPubkey;
  TextEditingController _outputBalance;
  final nRepositories = 20;
  var pubkey = '';
  ScrollController _scrollController = new ScrollController();

  @override
  initState() {
    super.initState();
    this._outputPubkey = new TextEditingController();
    this._outputBalance = new TextEditingController();
    // checkNode().then((result) {
    //   setState(() {
    //     _result = result;
    //   });
    // });
  }

  @override
  Widget build(BuildContext context) {
    // final pubkey = 'D2meevcAHFTS2gQMvmRW5Hzi25jDdikk4nC4u1FkwRaU';

    // var pubkey = '';
    print('Build state : ' + pubkey);
    return MaterialApp(
        home: Scaffold(
            backgroundColor: Colors.grey[300],
            body: Container(
              child: Column(
                children: <Widget>[
                  SizedBox(height: 20),
                  TextField(
                      // enabled: false,
                      onChanged: (text) {
                        print("Clé tappé: $text");
                        // pubkey = text;
                        pubkey = isPubkey(text);
                      },
                      controller: this._outputPubkey,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'Tappez/Collez une clé publique, ou scannez',
                        hintStyle: TextStyle(fontSize: 15),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 7, vertical: 15),
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
                  TextField(
                      // Affichage balance
                      enabled: false,
                      controller: this._outputBalance,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '',
                        hintStyle: TextStyle(fontSize: 15),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 7, vertical: 15),
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                      ),
                      style: TextStyle(fontSize: 30.0, color: Colors.black)),
                  Expanded(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Query(
                        options: QueryOptions(
                          documentNode: gql(getMyRepositories),
                          variables: <String, dynamic>{
                            'pubkey':
                                'D2meevcAHFTS2gQMvmRW5Hzi25jDdikk4nC4u1FkwRaU', // pubkey,
                            'number': nRepositories,
                            // set cursor to null so as to start at the beginning
                            // 'cursor': 0
                          },
                        ),
                        builder: (QueryResult result,
                            {refetch, FetchMore fetchMore}) {
                          if (result.loading && result.data == null) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (result.hasException) {
                            return Text(
                                '\nErrors: \n  ' + result.exception.toString());
                          }

                          if (result.data == null &&
                              result.exception.toString() == null) {
                            return const Text(
                                'Both data and errors are null, this is a known bug after refactoring, you might forget to set Github token');
                          }

                          final List<dynamic> blockchainTX =
                              (result.data['txsHistoryBc']['both']['edges']
                                  as List<dynamic>);

                          // final List<dynamic> mempoolTX =
                          //     (result.data['txsHistoryBc']['both']['edges']
                          //         as List<dynamic>);

                          final Map pageInfo =
                              result.data['txsHistoryBc']['both']['pageInfo'];
                          final String fetchMoreCursor = pageInfo['endCursor'];

                          FetchMoreOptions opts = FetchMoreOptions(
                            variables: {'cursor': fetchMoreCursor},
                            updateQuery:
                                (previousResultData, fetchMoreResultData) {
                              // this is where you combine your previous data and response
                              // in this case, we want to display previous repos plus next repos
                              // so, we combine data in both into a single list of repos
                              final List<dynamic> repos = [
                                ...previousResultData['txsHistoryBc']['both']
                                    ['edges'] as List<dynamic>,
                                ...fetchMoreResultData['txsHistoryBc']['both']
                                    ['edges'] as List<dynamic>
                              ];

                              fetchMoreResultData['txsHistoryBc']['both']
                                  ['edges'] = repos;
                              print('A: ' + fetchMoreCursor + ' B');
                              return fetchMoreResultData;
                            },
                          );

                          _scrollController
                            ..addListener(() {
                              if (_scrollController.position.pixels ==
                                  _scrollController.position.maxScrollExtent) {
                                if (!result.loading) {
                                  fetchMore(opts);
                                }
                              }
                            });

                          List transBC = parseHistory(blockchainTX);
                          // parseHistory(mempoolTX);

                          return Expanded(
                            child: ListView(
                              controller: _scrollController,
                              children: <Widget>[
                                for (var repository in transBC)
                                  Card(
                                    // 1
                                    elevation: 2.0,
                                    // 2
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(3.0)),
                                    // 3
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      // 4
                                      child: Column(
                                        children: <Widget>[
                                          SizedBox(
                                            height: 8.0,
                                          ),
                                          Text(
                                            // Date
                                            repository[1].toString(),
                                            style: TextStyle(
                                              fontSize: 12.0,
                                              fontWeight: FontWeight.w300,
                                            ),
                                          ),
                                          Text(
                                            // Issuer
                                            repository[2],
                                            style: TextStyle(
                                              fontSize: 13.0,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            // Amount
                                            repository[3].toString(),
                                            style: TextStyle(
                                              fontSize: 15.0,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          // Text(
                                          //   // amountUD
                                          //   repository[4].toString(),
                                          //   style: TextStyle(
                                          //     fontSize: 12.0,
                                          //     fontWeight: FontWeight.w500,
                                          //   ),
                                          // ),
                                          Text(
                                            // Comment
                                            repository[5].toString(),
                                            style: TextStyle(
                                              fontSize: 12.0,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (result.loading)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      CircularProgressIndicator(),
                                    ],
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  )),
                ],
              ),
            ),
            floatingActionButton: Container(
              height: 80.0,
              width: 80.0,
              child: FittedBox(
                child: FloatingActionButton(
                  onPressed: () => _scan(),
                  // label: Text('Scanner'),
                  child: Container(
                      height: 40.0,
                      width: 40.0,
                      child: Image.asset('images/scanner.png')),
                  backgroundColor: Color.fromARGB(500, 204, 255, 255),
                ),
              ),
            )));
  }

  Future checkNode() async {
    final response = await Dio().post(graphqlEndpoint);
    showHistory(response);
    return response;
  }

  Future _scan() async {
    await Permission.camera.request();
    String barcode = await scanner.scan();
    // this._outputPubkey.text = "";
    if (barcode != null) {
      isPubkey(barcode);
    }
    return barcode;
  }

  String isPubkey(pubkey) {
    // final validCharacters = RegExp(r'^[a-zA-Z0-9]+$');
    RegExp regExp = new RegExp(
      r'^[a-zA-Z0-9]+$',
      caseSensitive: false,
      multiLine: false,
    );

    if (regExp.hasMatch(pubkey) == true &&
        pubkey.length > 42 &&
        pubkey.length < 45) {
      print("C'est une pubkey !!!");
      showHistory(pubkey);

      // setState(() {});

      return pubkey;

      // print(pubkey);
      // setState(({pubkey = 'D2meevcAHFTS2gQMvmRW5Hzi25jDdikk4nC4u1FkwRaU'}) {
      //   pubkey = pubkey;
      //   print('setState : ' + pubkey);
      // });
    } else {
      return '';
    }
  }

  Future showHistory(pubkey) async {
    // String pubkey = await _scan();
    if (pubkey == null) {
      print('nothing return.');
    } else {
      this._outputPubkey.text = "";
      this._outputBalance.text = "";
      // final udValue = await getUD();
      this._outputPubkey.text = pubkey;
      final myBalance = await getBalance(pubkey.toString());
      this._outputBalance.text = myBalance.toString() + " Ğ1";
    }
  }

  // Future _generateBarCode(String inputCode) async {
  //   if (inputCode != null && inputCode.isNotEmpty) {
  //     // print("Résultat du scan: " + inputCode);
  //     Uint8List result = await scanner.generateBarCode(inputCode);
  //     this.setState(() => this.bytes = result);
  //   } else {
  //     print("Veuillez renseigner une clé publique");
  //   }
  // }

}
