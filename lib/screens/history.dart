import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/cesium_plus.dart';
import 'package:gecko/models/home.dart';
import 'package:gecko/models/queries.dart';
import 'package:gecko/models/wallets_profiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:gecko/screens/avatar_fullscreen.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'dart:ui';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

// ignore: must_be_immutable
class HistoryScreen extends StatelessWidget with ChangeNotifier {
  HistoryScreen({@required this.pubkey, this.avatar, this.username, Key key})
      : super(key: key);
  final ScrollController scrollController = ScrollController();
  final nRepositories = 20;
  final double avatarsSize = 80;
  final String pubkey;
  final String username;
  final Image avatar;

  FetchMore fetchMore;
  FetchMoreOptions opts;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    WalletsProfilesProvider _historyProvider =
        Provider.of<WalletsProfilesProvider>(context, listen: false);
    CesiumPlusProvider _cesiumPlusProvider =
        Provider.of<CesiumPlusProvider>(context, listen: false);
    log.i('Build pubkey : ' + _historyProvider.pubkey);
    WidgetsBinding.instance.addPostFrameCallback((_) {});

    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          elevation: 0,
          toolbarHeight: 60 * ratio,
          title: const SizedBox(
            height: 22,
            child: Text('Historique des transactions'),
          ),
        ),
        body: Column(children: <Widget>[
          headerProfileView(context, _historyProvider, _cesiumPlusProvider),
          if (_historyProvider.pubkey != '')
            historyQuery(context, _historyProvider, _cesiumPlusProvider),
        ]));
  }

  Widget historyQuery(context, WalletsProfilesProvider _historyProvider2,
      CesiumPlusProvider _cesiumPlusProvider) {
    WalletsProfilesProvider _historyProvider =
        Provider.of<WalletsProfilesProvider>(context, listen: true);
    RefreshController _refreshController =
        RefreshController(initialRefresh: false);
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
              return Column(children: const <Widget>[
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

            opts = _historyProvider.checkQueryResult(result, opts, pubkey);

            // Build history list
            return NotificationListener(
                child: Builder(
                  builder: (context) => Expanded(
                    child: SmartRefresher(
                      enablePullUp: false,
                      controller: _refreshController,
                      onRefresh: () {
                        _historyProvider.resetdHistory();
                        _refreshController.refreshCompleted();
                      },
                      child: ListView(
                        key: const Key('listTransactions'),
                        controller: scrollController,
                        children: <Widget>[historyView(context, result)],
                      ),
                    ),
                  ),
                ),
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

  Widget historyView(context, result) {
    WalletsProfilesProvider _historyProvider =
        Provider.of<WalletsProfilesProvider>(context, listen: false);

    return _historyProvider.transBC == null
        ? const Text('Aucune transaction à afficher.')
        : Column(children: <Widget>[
            getTransactionTile(context, _historyProvider),
            // for (var repository in _historyProvider.transBC)
            // if (repository[1].toString().split(' ')[0] == '22-11-21')
            //   const Text("Aujourd'hui"),
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 5.0),
            //   child: ListTile(
            //       key: Key('transaction${keyID++}'),
            //       contentPadding: const EdgeInsets.all(5.0),
            //       leading: Text(repository[1],
            //           style: TextStyle(
            //               fontSize: 12,
            //               color: Colors.grey[800],
            //               fontWeight: FontWeight.w700),
            //           textAlign: TextAlign.center),
            //       title: Text(repository[3],
            //           style: const TextStyle(
            //               fontSize: 15.0, fontFamily: 'Monospace'),
            //           textAlign: TextAlign.center),
            //       subtitle: Text(repository[6] != '' ? repository[6] : '-',
            //           style: const TextStyle(fontSize: 12.0),
            //           textAlign: TextAlign.center),
            //       trailing: Text("${repository[4]} Ğ1",
            //           style: const TextStyle(fontSize: 14.0),
            //           textAlign: TextAlign.justify),
            //       dense: true,
            //       isThreeLine: false,
            //       onTap: () {
            //         if (_historyProvider.isPubkey(context, repository[2])) {
            //           _homeProvider.currentIndex = 0;
            //           Navigator.push(
            //             context,
            //             MaterialPageRoute(builder: (context) {
            //               return const WalletViewScreen();
            //             }),
            //           );
            //         }
            //         Navigator.pop(context);
            //       }),
            // ),
            if (result.isLoading &&
                _historyProvider.pageInfo['hasPreviousPage'])
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const <Widget>[
                  CircularProgressIndicator(),
                ],
              ),
            // if (_historyProvider.isTheEnd) // What I did before ...
            if (!_historyProvider.pageInfo['hasPreviousPage'])
              Column(
                children: const <Widget>[
                  SizedBox(height: 15),
                  Text("Début de l'historique.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20)),
                  SizedBox(height: 15)
                ],
              )
          ]);
  }

  Widget getTransactionTile(
      BuildContext context, WalletsProfilesProvider _historyProvider) {
    HomeProvider _homeProvider =
        Provider.of<HomeProvider>(context, listen: false);
    CesiumPlusProvider _cesiumPlusProvider =
        Provider.of<CesiumPlusProvider>(context, listen: false);
    int keyID = 0;
    String dateDelimiter;
    String lastDateDelimiter;
    const double _avatarSize = 200;

    const Map<int, String> monthsInYear = {
      1: "Janvier",
      2: "Février",
      3: "Mars",
      4: "Avril",
      5: "Mai",
      6: "Juin",
      7: "Juillet",
      8: "Aout",
      9: "Septembre",
      10: "Octobre",
      11: "Novembre",
      12: "Décembre"
    };

    return Column(
        children: _historyProvider.transBC.map((repository) {
      DateTime now = DateTime.now();
      DateTime date = DateTime.fromMillisecondsSinceEpoch(repository[0] * 1000);

      String dateForm;
      if ({4, 10, 11, 12}.contains(date.month)) {
        dateForm = "${date.day} ${monthsInYear[date.month].substring(0, 3)}.";
      } else if ({1, 2, 7, 9}.contains(date.month)) {
        dateForm = "${date.day} ${monthsInYear[date.month].substring(0, 4)}.";
      } else {
        dateForm = "${date.day} ${monthsInYear[date.month]}";
      }
      log.d(dateForm);

      int weekNumber(DateTime date) {
        int dayOfYear = int.parse(DateFormat("D").format(date));
        return ((dayOfYear - date.weekday + 10) / 7).floor();
      }

      if (DateTime(date.year, date.month, date.day) ==
          DateTime(now.year, now.month, now.day)) {
        dateDelimiter = lastDateDelimiter = "Aujourd'hui";
      } else if (DateTime(date.year, date.month, date.day) ==
          DateTime(now.year, now.month, now.day - 1)) {
        dateDelimiter = lastDateDelimiter = "Hier";
      } else if (weekNumber(date) == weekNumber(now) &&
          date.year == now.year &&
          lastDateDelimiter != "Cette semaine") {
        dateDelimiter = lastDateDelimiter = "Cette semaine";
      } else if (lastDateDelimiter != monthsInYear[date.month] &&
          lastDateDelimiter != "${monthsInYear[date.month]} ${date.year}") {
        if (date.year == now.year) {
          dateDelimiter = lastDateDelimiter = monthsInYear[date.month];
        } else {
          dateDelimiter =
              lastDateDelimiter = "${monthsInYear[date.month]} ${date.year}";
        }
      } else {
        dateDelimiter = null;
      }

      return Column(children: <Widget>[
        if (dateDelimiter != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Text(
              dateDelimiter,
              style: TextStyle(
                  fontSize: 23, color: orangeC, fontWeight: FontWeight.w300),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(right: 0),
          child:
              // Row(children: [Column(children: [],)],)
              ListTile(
                  key: Key('transaction${keyID++}'),
                  contentPadding: const EdgeInsets.only(
                      left: 20, right: 30, top: 15, bottom: 15),
                  leading: g1WalletsBox.get(repository[2])?.avatar == null
                      ? FutureBuilder(
                          future: _cesiumPlusProvider.getAvatar(
                              repository[2], _avatarSize),
                          builder: (BuildContext context,
                              AsyncSnapshot<Image> _avatar) {
                            if (_avatar.connectionState !=
                                    ConnectionState.done ||
                                _avatar.hasError) {
                              return Stack(children: [
                                _cesiumPlusProvider.defaultAvatar(_avatarSize),
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
                              g1WalletsBox.get(repository[2]).avatar =
                                  _avatar.data;
                              return ClipOval(child: _avatar.data);
                            } else {
                              g1WalletsBox.get(repository[2]).avatar =
                                  _cesiumPlusProvider
                                      .defaultAvatar(repository[2]);
                              return _cesiumPlusProvider
                                  .defaultAvatar(_avatarSize);
                            }
                          })
                      : ClipOval(
                          child: Image(
                            image: g1WalletsBox.get(repository[2]).avatar.image,
                            height: _avatarSize,
                          ),
                        ),
                  title: Padding(
                    padding: EdgeInsets.only(
                        bottom: 5, top: repository[6] != '' ? 0 : 0),
                    child: Text(repository[3],
                        style: const TextStyle(
                            fontSize: 18, fontFamily: 'Monospace')),
                  ),
                  subtitle: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: dateForm,
                        ),
                        if (repository[6] != '')
                          TextSpan(
                            text: '  ·  ',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.grey[550],
                            ),
                          ),
                        TextSpan(
                          text: repository[6],
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Text("${repository[4]} Ğ1",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.justify),
                  dense: false,
                  isThreeLine: false,
                  onTap: () {
                    if (_historyProvider.isPubkey(context, repository[2])) {
                      _homeProvider.currentIndex = 0;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) {
                          return const WalletViewScreen();
                        }),
                      );
                    }
                    Navigator.pop(context);
                  }),
        ),
      ]);
    }).toList());
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
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
                      ]),
                  FutureBuilder(
                      future: _historyProvider.getBalance(pubkey),
                      builder:
                          (BuildContext context, AsyncSnapshot<num> _balance) {
                        if (_balance.connectionState != ConnectionState.done ||
                            _balance.hasError) {
                          return const Text('...');
                        }
                        return Text(
                          "${_balance.data.toString()} Ğ1",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w500),
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
                    builder:
                        (BuildContext context, AsyncSnapshot<Image> _avatar) {
                      if (_avatar.connectionState != ConnectionState.done ||
                          _avatar.hasError) {
                        return Stack(children: [
                          ClipOval(
                            child:
                                _cesiumPlusProvider.defaultAvatar(_avatarSize),
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
