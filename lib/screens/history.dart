import 'dart:io';

import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/cesiumPlus.dart';
import 'package:gecko/models/queries.dart';
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
  final _formKey = GlobalKey<FormState>();
  FocusNode _pubkeyFocus = FocusNode();
  List cesiumData;

  FetchMore fetchMore;
  FetchMoreOptions opts;

  @override
  Widget build(BuildContext context) {
    HistoryProvider _historyProvider = Provider.of<HistoryProvider>(context);
    this._outputPubkey.text = _historyProvider.pubkey;
    print('Build pubkey : ' + _historyProvider.pubkey);
    // _historyProvider.snackNode(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _historyProvider.snackNode(context);
    });

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
          SizedBox(height: 20),
          TextField(
              autofocus: false,
              focusNode: _pubkeyFocus,
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
          if (_historyProvider.pubkey != '')
            historyQuery(context, _historyProvider),
        ]));
  }

  Widget historyQuery(context, _historyProvider) {
    _pubkeyFocus.unfocus();
    // HistoryProvider _historyProvider = Provider.of<HistoryProvider>(context);
    CesiumPlusProvider _cesiumPlusProvider =
        Provider.of<CesiumPlusProvider>(context);
    print("I'M HERE 1");
    bool _isFirstExec = true;
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
          builder: (QueryResult result, {fetchMore, refetch}) {
            print("I'M HERE 2 ! $_isFirstExec");
            // print(result.source.isEager);

            if (result.isLoading && result.data == null) {
              print("I'M HERE 3 !");
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

            final num balance = _historyProvider
                .removeDecimalZero(result.data['balance']['amount'] / 100);

            opts = _historyProvider.checkQueryResult(
                result, opts, _outputPubkey.text);

            // _historyProvider.transBC = null;

            // Build history list
            return NotificationListener(
                child: Expanded(
                    child: ListView(
                  controller: scrollController,
                  children: <Widget>[
                    SizedBox(height: 15),
                    if (_historyProvider.pubkey != '')
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (_isFirstExec)
                              Container(
                                  padding: const EdgeInsets.only(left: 30),
                                  child: FutureBuilder(
                                      future: _cesiumPlusProvider
                                          .getAvatar(_historyProvider.pubkey),
                                      initialData: [
                                        File(appPath.path +
                                            '/default_avatar.png')
                                      ],
                                      builder: (BuildContext context,
                                          AsyncSnapshot<List> _avatar) {
                                        cesiumData = _avatar.data;
                                        // _cesiumPlusProvider.isComplete = true;
                                        if (_avatar.connectionState !=
                                            ConnectionState.done) {
                                          return Image.file(
                                              File(appPath.path +
                                                  '/default_avatar.png'),
                                              height: 65);
                                        }
                                        if (_avatar.hasError) {
                                          return Image.file(
                                              File(appPath.path +
                                                  '/default_avatar.png'),
                                              height: 65);
                                        }
                                        if (_avatar.hasData) {
                                          return SingleChildScrollView(
                                              padding: EdgeInsets.all(0.0),
                                              child: Image.file(_avatar.data[0],
                                                  height: 65));
                                        }
                                        return Image.file(
                                            File(appPath.path +
                                                '/default_avatar.png'),
                                            height: 65);
                                      })),
                            if (_isFirstExec)
                              Text(balance.toString() + ' Ğ1',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 30.0)),
                            Container(
                                padding: const EdgeInsets.fromLTRB(
                                    30, 0, 15, 0), // .only(right: 15),
                                child: IconButton(
                                    icon: Icon(Icons.payments),
                                    onPressed: () {
                                      showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return paymentPopup(context);
                                          });
                                    },
                                    iconSize: 30,
                                    color: Color(0xFFB16E16)))
                          ]),
                    SizedBox(height: 10),
                    if (_isFirstExec)
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                                // padding: const EdgeInsets.,
                                child: FutureBuilder(
                                    future: _cesiumPlusProvider
                                        .getName(_historyProvider.pubkey),
                                    initialData: '',
                                    builder: (context, snapshot) {
                                      return Text(snapshot.data);
                                    }))
                          ]),
                    SizedBox(height: 20),
                    const Divider(
                      color: Colors.grey,
                      height: 5,
                      thickness: 0.5,
                      indent: 0,
                      endIndent: 0,
                    ),
                    _historyProvider.transBC == null
                        ? Text('Aucune transaction à afficher.')
                        : loopTransactions(context, result),
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

  Widget loopTransactions(context, result) {
    HistoryProvider _historyProvider = Provider.of<HistoryProvider>(context);

    return Column(children: <Widget>[
      for (var repository in _historyProvider.transBC)
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
                        omission: "...", position: TruncatePosition.end),
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
      // if (_historyProvider.isTheEnd) // What I did before ...
      if (!_historyProvider.pageInfo['hasPreviousPage'])
        Column(children: <Widget>[
          SizedBox(height: 15),
          Text("Début de l'historique.",
              textAlign: TextAlign.center, style: TextStyle(fontSize: 20)),
          SizedBox(height: 15)
        ])
    ]);
  }

  Widget paymentPopup(context) {
    return AlertDialog(
      content: Stack(
        overflow: Overflow.visible,
        children: <Widget>[
          Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('À:'),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(this._outputPubkey.text,
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                ),
                SizedBox(height: 20),
                Text('Montant (Ğ1):'),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: TextFormField(
                    textAlign: TextAlign.center,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'(^\d*\.?\d*)'))
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: RaisedButton(
                    child: Text("Payer"),
                    color: Color(0xffFFD68E),
                    onPressed: () {
                      if (_formKey.currentState.validate()) {
                        _formKey.currentState.save();
                      }
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
