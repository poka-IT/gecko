import 'dart:io';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/cesiumPlus.dart';
import 'package:gecko/models/home.dart';
import 'package:gecko/models/queries.dart';
import 'package:gecko/models/history.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:gecko/screens/myWallets/unlockingWallet.dart';
import 'dart:ui';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ignore: must_be_immutable
class HistoryScreen extends StatelessWidget with ChangeNotifier {
  final TextEditingController _outputPubkey = TextEditingController();
  ScrollController scrollController = ScrollController();
  final nRepositories = 20;
  // HistoryProvider _historyProvider;
  final _formKey = GlobalKey<FormState>();
  FocusNode _pubkeyFocus = FocusNode();
  List cesiumData;
  final double avatarsSize = 80;

  FetchMore fetchMore;
  FetchMoreOptions opts;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    HistoryProvider _historyProvider = Provider.of<HistoryProvider>(context);
    HomeProvider _homeProvider = Provider.of<HomeProvider>(context);
    this._outputPubkey.text = _historyProvider.pubkey;
    log.i('Build pubkey : ' + _historyProvider.pubkey);
    WidgetsBinding.instance.addPostFrameCallback((_) {});

    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: _homeProvider.appBarExplorer,
          actions: [
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: IconButton(
                    icon: _homeProvider.searchIcon,
                    color: Colors.grey[850],
                    onPressed: () {
                      if (_homeProvider.searchIcon.icon == Icons.search) {
                        _homeProvider.searchIcon = Icon(
                          Icons.close,
                          color: Colors.grey[850],
                        );
                        _homeProvider.appBarExplorer = TextField(
                          autofocus: true,
                          controller: _homeProvider.searchQuery,
                          onChanged: (text) {
                            log.d("Clé tappé: $text");
                            final String searchResult =
                                _historyProvider.isPubkey(context, text);
                            if (searchResult != '') {
                              _homeProvider.currentIndex = 0;
                            }
                          },
                          style: TextStyle(
                            color: Colors.grey[850],
                          ),
                          decoration: InputDecoration(
                              prefixIcon:
                                  Icon(Icons.search, color: Colors.grey[850]),
                              hintText: "Rechercher ...",
                              hintStyle: TextStyle(color: Colors.grey[850])),
                        );
                        _homeProvider.handleSearchStart();
                      } else {
                        _homeProvider.handleSearchEnd();
                      }
                    }))
          ],
          backgroundColor: Color(0xffFFD58D),
        ),
        floatingActionButton: Container(
          height: 80.0,
          width: 80.0,
          child: FittedBox(
            child: FloatingActionButton(
              heroTag: "buttonScan",
              onPressed: () async {
                await _historyProvider.scan(context);
              },
              child: Container(
                  height: 40.0,
                  width: 40.0,
                  child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3),
                      child: Image.asset('assets/qrcode-scan.png'))),
              backgroundColor: Color(
                  0xffEFEFBF), //Color(0xffFFD68E), //Color.fromARGB(500, 204, 255, 255),
            ),
          ),
        ),
        body: Column(children: <Widget>[
          SizedBox(height: 0),
          if (_historyProvider.pubkey != '')
            historyQuery(context, _historyProvider),
        ]));
  }

  Widget historyQuery(context, HistoryProvider _historyProvider) {
    _pubkeyFocus.unfocus();
    // HistoryProvider _historyProvider = Provider.of<HistoryProvider>(context);
    CesiumPlusProvider _cesiumPlusProvider =
        Provider.of<CesiumPlusProvider>(context);
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
            if (result.isLoading && result.data == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (result.hasException) {
              log.e('Error GVA: ' + result.exception.toString());
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

            num balance;

            if (result.data['balance'] == null) {
              balance = 0.0;
            } else {
              balance = _historyProvider
                  .removeDecimalZero(result.data['balance']['amount'] / 100);
            }

            opts = _historyProvider.checkQueryResult(
                result, opts, _outputPubkey.text);

            // _historyProvider.transBC = null;

            // Build history list
            return NotificationListener(
                child: Builder(
                    builder: (context) => Expanded(
                            child: ListView(
                          key: Key('listTransactions'),
                          controller: scrollController,
                          children: <Widget>[
                            SizedBox(height: 20),
                            if (_historyProvider.pubkey != '')
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (_isFirstExec)
                                      Container(
                                          padding: const EdgeInsets.fromLTRB(
                                              20, 0, 30, 0),
                                          child: FutureBuilder(
                                              future:
                                                  _cesiumPlusProvider.getAvatar(
                                                      _historyProvider.pubkey),
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
                                                      padding:
                                                          EdgeInsets.all(0.0),
                                                      child: Image.file(
                                                          _avatar.data[0],
                                                          height: avatarsSize));
                                                }
                                                return Image.file(
                                                    File(appPath.path +
                                                        '/default_avatar.png'),
                                                    height: avatarsSize);
                                              })),
                                    GestureDetector(
                                      key: Key('copyPubkey'),
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(
                                            text: _historyProvider.pubkey));
                                        _historyProvider.snackCopyKey(context);
                                      },
                                      child: Text(
                                          _historyProvider.getShortPubkey(
                                              _historyProvider.pubkey),
                                          style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              fontFamily: 'Monospace')),
                                    ),
                                    Container(
                                        padding: const EdgeInsets.fromLTRB(
                                            30, 0, 5, 0), // .only(right: 15),
                                        child: Card(
                                          child: Column(
                                            children: <Widget>[
                                              SvgPicture.string(
                                                _historyProvider
                                                    .generateIdenticon(
                                                        _historyProvider
                                                            .pubkey),
                                                fit: BoxFit.contain,
                                                height: 64,
                                                width: 64,
                                              ),
                                            ],
                                          ),
                                        )),
                                    SizedBox(width: 0)
                                  ]),
                            if (_isFirstExec)
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                        padding: const EdgeInsets.fromLTRB(
                                            0, 0, 0, 0),
                                        // padding: const EdgeInsets.,
                                        child: FutureBuilder(
                                            future: _cesiumPlusProvider.getName(
                                                _historyProvider.pubkey),
                                            initialData: '...',
                                            builder: (context, snapshot) {
                                              return Text(
                                                  snapshot.data != null
                                                      ? snapshot.data
                                                      : '-',
                                                  style:
                                                      TextStyle(fontSize: 20));
                                            }))
                                  ]),
                            SizedBox(height: 18),
                            if (_isFirstExec)
                              Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 0, 0),
                                  child: Text(balance.toString() + ' Ğ1',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 18.0))),
                            SizedBox(height: 20),
                            ElevatedButton(
                                key: Key('switchPayHistory'),
                                style: ElevatedButton.styleFrom(
                                  elevation: 1,
                                  primary: Colors.grey[50], // background
                                  onPrimary: Colors.black, // foreground
                                ),
                                onPressed: () {
                                  _historyProvider.switchProfileView();
                                },
                                child: Text(
                                    _historyProvider.historySwitchButtun,
                                    style: TextStyle(
                                        fontSize: 15,
                                        color: Color(0xffD28928)))),
                            // const Divider(
                            //   color: Colors.grey,
                            //   height: 5,
                            //   thickness: 0.5,
                            //   indent: 0,
                            //   endIndent: 0,
                            // ),
                            _historyProvider.isHistoryScreen
                                ? historyView(context, result)
                                : payView(context, _historyProvider),
                          ],
                        ))),
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

  Widget payView(context, HistoryProvider _historyProvider) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: <Widget>[
        Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(height: 20),
              Text('Commentaire:', style: TextStyle(fontSize: 20.0)),
              Padding(
                  padding: EdgeInsets.all(8.0),
                  child: TextField(
                      controller: _historyProvider.payComment,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(),
                      style: TextStyle(
                          fontSize: 22,
                          color: Colors.black,
                          fontWeight: FontWeight.bold))),
              SizedBox(height: 20),
              Text('Montant (DU/Ğ1):', style: TextStyle(fontSize: 20.0)),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: TextFormField(
                  style: TextStyle(fontSize: 22),
                  controller: _historyProvider.payAmount,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 25.0, horizontal: 10.0),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0)),
                  ),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'(^\d*\.?\d*)'))
                  ],
                ),
              ),
              Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(width: 2, color: Color(0xffD28928))),
                    onPressed: () {
                      // if (_formKey.currentState.validate()) {
                      //   _formKey.currentState.save();
                      // }
                      // _historyProvider.pay(payAmount.text, payComment.text);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return UnlockingWallet(
                            wallet: defaultWallet, action: "pay");
                      }));
                    },
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text("PAYER",
                            style: TextStyle(
                                fontSize: 25, color: Colors.grey[850]))),
                  ))
            ],
          ),
        ),
      ],
    );
  }

  Widget historyView(context, result) {
    HistoryProvider _historyProvider = Provider.of<HistoryProvider>(context);
    int keyID = 0;

    return _historyProvider.transBC == null
        ? Text('Aucune transaction à afficher.')
        : Column(children: <Widget>[
            for (var repository in _historyProvider.transBC)
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: ListTile(
                      key: Key('transaction${keyID++}'),
                      contentPadding: const EdgeInsets.all(5.0),
                      leading: Text(repository[1].toString(),
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center),
                      title: Text(repository[3],
                          style: TextStyle(
                              fontSize: 15.0, fontFamily: 'Monospace'),
                          textAlign: TextAlign.center),
                      subtitle: Text(repository[6] != '' ? repository[6] : '-',
                          style: TextStyle(fontSize: 12.0),
                          textAlign: TextAlign.center),
                      trailing: Text("${repository[4]} Ğ1",
                          style: TextStyle(fontSize: 14.0),
                          textAlign: TextAlign.justify),
                      dense: true,
                      isThreeLine: false,
                      onTap: () {
                        // this._outputPubkey.text = repository[2];
                        _historyProvider.isPubkey(context, repository[2]);
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
              Column(
                children: <Widget>[
                  SizedBox(height: 15),
                  Text("Début de l'historique.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20)),
                  SizedBox(height: 15)
                ],
              )
          ]);
  }
}
