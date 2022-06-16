import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/queries_indexer.dart';
import 'package:gecko/providers/cesium_plus.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:flutter/material.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class ActivityScreen extends StatelessWidget with ChangeNotifier {
  ActivityScreen({required this.address, this.avatar, this.username, Key? key})
      : super(key: key);
  final ScrollController scrollController = ScrollController();
  final double avatarsSize = 80;
  final String? address;
  final String? username;
  final Image? avatar;

  FetchMore? fetchMore;
  FetchMoreOptions? opts;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          elevation: 0,
          toolbarHeight: 60 * ratio,
          title: const SizedBox(
            height: 22,
            child: Text('Activité du compte'),
          ),
        ),
        body: Column(children: <Widget>[
          headerProfileView(context),
          historyQuery(context),
        ]));
  }

  Widget historyQuery(context) {
    DuniterIndexer _duniterIndexer =
        Provider.of<DuniterIndexer>(context, listen: false);

    if (indexerEndpoint == '') {
      Column(children: const <Widget>[
        SizedBox(height: 50),
        Text(
          "L'état du réseau ne permet pas\nd'afficher l'historique du compte",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        )
      ]);
    }

    final _httpLink = HttpLink(
      '$indexerEndpoint/v1beta1/relay',
    );

    final _client = ValueNotifier(
      GraphQLClient(
        cache: GraphQLCache(),
        link: _httpLink,
      ),
    );

    return GraphQLProvider(
      client: _client,
      child: Expanded(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Query(
            options: QueryOptions(
              document: gql(getHistoryByAddressQ3),
              variables: <String, dynamic>{
                'address': address,
                'number': 20,
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
                log.e('Error Indexer: ' + result.exception.toString());
                return Column(children: const <Widget>[
                  SizedBox(height: 50),
                  Text(
                    "L'état du réseau ne permet pas\nd'afficher l'historique du compte",
                    textAlign: TextAlign.center,
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

              if (result.isNotLoading) {
                // log.d(result.data);
                opts = _duniterIndexer.checkQueryResult(result, opts, address!);
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
                        _duniterIndexer.pageInfo!['hasNextPage'] &&
                        result.isNotLoading) {
                      fetchMore!(opts!);
                    }
                    return true;
                  });
            },
          ),
        ],
      )),
    );
  }

  Widget historyView(context, result) {
    DuniterIndexer _duniterIndexer =
        Provider.of<DuniterIndexer>(context, listen: false);

    return _duniterIndexer.transBC == null
        ? Column(children: const <Widget>[
            SizedBox(height: 50),
            Text(
              "Aucune transaction à afficher.",
              style: TextStyle(fontSize: 18),
            )
          ])
        : Column(children: <Widget>[
            getTransactionTile(context, _duniterIndexer),
            if (result.isLoading &&
                _duniterIndexer.pageInfo!['hasPreviousPage'])
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const <Widget>[
                  CircularProgressIndicator(),
                ],
              ),
            if (!_duniterIndexer.pageInfo!['hasNextPage'])
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
      BuildContext context, DuniterIndexer _duniterIndexer) {
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
        children: _duniterIndexer.transBC!.map((repository) {
      // log.d('bbbbbbbbbbbbbbbbbbbbbb: ' + repository.toString());

      DateTime now = DateTime.now();
      DateTime date = repository[0];

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
                  leading: ClipOval(
                    child: _cesiumPlusProvider.defaultAvatar(_avatarSize),
                  ),
                  title: Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(getShortPubkey(repository[1]),
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
                        if (repository[2] != '')
                          TextSpan(
                            text: '  ·  ',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.grey[550],
                            ),
                          ),
                        TextSpan(
                          text: repository[2],
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Text("${repository[3]} $currencyName",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.justify),
                  dense: false,
                  isThreeLine: false,
                  onTap: () {
                    _duniterIndexer.nPage = 1;
                    // _cesiumPlusProvider.avatarCancelToken.cancel('cancelled');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) {
                        return WalletViewScreen(pubkey: repository[1]);
                      }),
                    );
                    // Navigator.pop(context);
                  }),
        ),
      ]);
    }).toList());
  }

  Widget headerProfileView(BuildContext context) {
    DuniterIndexer _duniterIndexer =
        Provider.of<DuniterIndexer>(context, listen: false);

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
                              Clipboard.setData(ClipboardData(text: address));
                              snackCopyKey(context);
                            },
                            child: Text(
                              getShortPubkey(address!),
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        if (username == null)
                          _duniterIndexer.getNameByAddress(
                              context,
                              address!,
                              null,
                              27,
                              false,
                              Colors.black,
                              FontWeight.w400,
                              FontStyle.normal),
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
                  balance(context, address!, 21),
                  const SizedBox(height: 30),
                ]),
            const Spacer(),
            Column(children: <Widget>[
              Image.asset(('assets/icon_user.png'), height: 50),
              const SizedBox(height: 25),
            ]),
          ]),
        ),
      ),
    ]);
  }
}
