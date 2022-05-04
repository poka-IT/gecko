import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/cesium_plus.dart';
import 'package:gecko/models/queries.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:flutter/material.dart';
import 'package:gecko/screens/avatar_fullscreen.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class HistoryScreen extends StatelessWidget with ChangeNotifier {
  HistoryScreen({required this.pubkey, this.avatar, this.username, Key? key})
      : super(key: key);
  final ScrollController scrollController = ScrollController();
  final double avatarsSize = 80;
  final String? pubkey;
  final String? username;
  final Image? avatar;

  FetchMore? fetchMore;
  FetchMoreOptions? opts;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    WalletsProfilesProvider _historyProvider =
        Provider.of<WalletsProfilesProvider>(context, listen: false);
    CesiumPlusProvider _cesiumPlusProvider =
        Provider.of<CesiumPlusProvider>(context, listen: false);
    log.i('Build pubkey : ' + pubkey!);
    WidgetsBinding.instance?.addPostFrameCallback((_) {});

    _historyProvider.balance = _historyProvider.transBC = null;

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
          historyQuery(context, _cesiumPlusProvider),
        ]));
  }

  Widget historyQuery(context, CesiumPlusProvider _cesiumPlusProvider) {
    WalletsProfilesProvider _historyProvider =
        Provider.of<WalletsProfilesProvider>(context, listen: true);

    return Expanded(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Query(
          options: QueryOptions(
            document: gql(getHistory),
            variables: <String, dynamic>{
              'pubkey': pubkey,
              'number': 10,
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
                  style: TextStyle(fontSize: 18),
                )
              ]);
            } else if (result.data == null) {
              return Column(children: const <Widget>[
                SizedBox(height: 50),
                Text(
                  "Aucune donnée à afficher.",
                  style: TextStyle(fontSize: 18),
                )
              ]);
            }

            if (result.data!['balance'] == null) {
              _historyProvider.balance = 0.0;
            } else {
              _historyProvider.balance = _historyProvider
                  .removeDecimalZero(result.data!['balance']['amount'] / 100);
            }

            if (result.isNotLoading) {
              // log.d(result.data);
              opts = _historyProvider.checkQueryResult(result, opts, pubkey);
            }

            // Build history list
            return NotificationListener(
                child: Builder(
                  builder: (context) => Expanded(
                    child: ListView(
                      key: const Key('listTransactions'),
                      controller: scrollController,
                      children: <Widget>[historyView(context, result)],
                    ),
                  ),
                ),
                onNotification: (dynamic t) {
                  if (t is ScrollEndNotification &&
                      scrollController.position.pixels >=
                          scrollController.position.maxScrollExtent * 0.7 &&
                      _historyProvider.pageInfo!['hasPreviousPage'] &&
                      result.isNotLoading) {
                    fetchMore!(opts!);
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
        ? Column(children: const <Widget>[
            SizedBox(height: 50),
            Text(
              "Aucune transaction à afficher.",
              style: TextStyle(fontSize: 18),
            )
          ])
        : Column(children: <Widget>[
            getTransactionTile(context, _historyProvider),
            if (result.isLoading &&
                _historyProvider.pageInfo!['hasPreviousPage'])
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const <Widget>[
                  CircularProgressIndicator(),
                ],
              ),
            if (!_historyProvider.pageInfo!['hasPreviousPage'])
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
    CesiumPlusProvider _cesiumPlusProvider =
        Provider.of<CesiumPlusProvider>(context, listen: false);
    int keyID = 0;
    String? dateDelimiter;
    String? lastDateDelimiter;
    const double _avatarSize = 200;

    bool isTody = false;
    bool isYesterday = false;
    bool isThisWeek = false;

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
        children: _historyProvider.transBC!.map((repository) {
      DateTime now = DateTime.now();
      DateTime date = DateTime.fromMillisecondsSinceEpoch(repository[0] * 1000);

      String dateForm;
      if ({4, 10, 11, 12}.contains(date.month)) {
        dateForm = "${date.day} ${monthsInYear[date.month]!.substring(0, 3)}.";
      } else if ({1, 2, 7, 9}.contains(date.month)) {
        dateForm = "${date.day} ${monthsInYear[date.month]!.substring(0, 4)}.";
      } else {
        dateForm = "${date.day} ${monthsInYear[date.month]}";
      }

      int weekNumber(DateTime date) {
        int dayOfYear = int.parse(DateFormat("D").format(date));
        return ((dayOfYear - date.weekday + 10) / 7).floor();
      }

      final transactionDate = DateTime(date.year, date.month, date.day);
      final todayDate = DateTime(now.year, now.month, now.day);
      final yesterdayDate = DateTime(now.year, now.month, now.day - 1);

      if (transactionDate == todayDate && !isTody) {
        dateDelimiter = lastDateDelimiter = "Aujourd'hui";
        isTody = true;
      } else if (transactionDate == yesterdayDate && !isYesterday) {
        dateDelimiter = lastDateDelimiter = "Hier";
        isYesterday = true;
      } else if (weekNumber(date) == weekNumber(now) &&
          date.year == now.year &&
          lastDateDelimiter != "Cette semaine" &&
          transactionDate != yesterdayDate &&
          transactionDate != todayDate &&
          !isThisWeek) {
        dateDelimiter = lastDateDelimiter = "Cette semaine";
        isThisWeek = true;
      } else if (lastDateDelimiter != monthsInYear[date.month] &&
          lastDateDelimiter != "${monthsInYear[date.month]} ${date.year}" &&
          transactionDate != todayDate &&
          transactionDate != yesterdayDate &&
          !(weekNumber(date) == weekNumber(now) && date.year == now.year)) {
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
              dateDelimiter!,
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
                              AsyncSnapshot<Image?> _avatar) {
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
                              g1WalletsBox.get(repository[2])?.avatar =
                                  _avatar.data;
                              return ClipOval(child: _avatar.data);
                            } else {
                              g1WalletsBox.get(repository[2])?.avatar =
                                  _cesiumPlusProvider
                                      .defaultAvatar(repository[2]);
                              return _cesiumPlusProvider
                                  .defaultAvatar(_avatarSize);
                            }
                          })
                      : ClipOval(
                          child: Image(
                            image:
                                g1WalletsBox.get(repository[2])!.avatar!.image,
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
                    _historyProvider.nPage = 1;
                    // _cesiumPlusProvider.avatarCancelToken.cancel('cancelled');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) {
                        return WalletViewScreen(pubkey: repository[2]);
                      }),
                    );
                    // Navigator.pop(context);
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
                              Clipboard.setData(ClipboardData(text: pubkey));
                              _historyProvider.snackCopyKey(context);
                            },
                            child: Text(
                              _historyProvider.getShortPubkey(pubkey!),
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
                                'pubkey': pubkey,
                              },
                            ),
                            builder: (QueryResult result,
                                {VoidCallback? refetch, FetchMore? fetchMore}) {
                              if (result.isLoading || result.hasException) {
                                return const Text('...');
                              } else if (result.data!['idty'] == null ||
                                  result.data!['idty']['username'] == null) {
                                return const Text('');
                              } else {
                                return SizedBox(
                                  width: 230,
                                  child: Text(
                                    result.data!['idty']['username'] ?? '',
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
                          SizedBox(
                            width: 230,
                            child: Text(
                              username!,
                              style: const TextStyle(
                                fontSize: 27,
                                color: Color(0xff814C00),
                              ),
                            ),
                          ),
                        const SizedBox(height: 25),
                      ]),
                  FutureBuilder(
                      future: _historyProvider.getBalance(pubkey),
                      builder:
                          (BuildContext context, AsyncSnapshot<num?> _balance) {
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
                    future: _cesiumPlusProvider.getAvatar(pubkey, _avatarSize),
                    builder:
                        (BuildContext context, AsyncSnapshot<Image?> _avatar) {
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
                              image: _avatar.data!.image,
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
                      image: avatar!.image,
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
