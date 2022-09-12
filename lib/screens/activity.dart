// ignore_for_file: must_be_immutable

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/queries_indexer.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/cesium_plus.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/home.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:flutter/material.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';

class ActivityScreen extends StatelessWidget with ChangeNotifier {
  ActivityScreen({required this.address, required this.avatar, this.username})
      : super(key: keyActivityScreen);
  final ScrollController scrollController = ScrollController();
  final double avatarsSize = 80;
  final String address;
  final String? username;
  final Image avatar;

  FetchMore? fetchMore;
  FetchMoreOptions? opts;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    WalletsProfilesProvider walletProfile =
        Provider.of<WalletsProfilesProvider>(context, listen: false);
    HomeProvider homeProvider =
        Provider.of<HomeProvider>(context, listen: false);

    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          elevation: 0,
          toolbarHeight: 60 * ratio,
          title: SizedBox(
            height: 22,
            child: Text('accountActivity'.tr()),
          ),
        ),
        bottomNavigationBar: homeProvider.bottomAppBar(context),
        body: Column(children: <Widget>[
          walletProfile.headerProfileView(context, address, username),
          historyQuery(context),
        ]));
  }

  Widget historyQuery(context) {
    DuniterIndexer duniterIndexer =
        Provider.of<DuniterIndexer>(context, listen: false);

    if (indexerEndpoint == '') {
      Column(children: <Widget>[
        const SizedBox(height: 50),
        Text(
          "noNetworkNoHistory".tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        )
      ]);
    }

    final httpLink = HttpLink(
      '$indexerEndpoint/v1beta1/relay',
    );

    final client = ValueNotifier(
      GraphQLClient(
        cache: GraphQLCache(),
        link: httpLink,
      ),
    );

    return GraphQLProvider(
      client: client,
      child: Expanded(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Query(
            options: QueryOptions(
              document: gql(getHistoryByAddressQ),
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
                log.e('Error Indexer: ${result.exception}');
                return Column(children: <Widget>[
                  const SizedBox(height: 50),
                  Text(
                    "noNetworkNoHistory".tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  )
                ]);
              } else if (result
                  .data?['transaction_connection']?['edges'].isEmpty) {
                return Column(children: <Widget>[
                  const SizedBox(height: 50),
                  Text(
                    "noDataToDisplay".tr(),
                    style: const TextStyle(fontSize: 18),
                  )
                ]);
              }

              if (result.isNotLoading) {
                // log.d(result.data);
                opts = duniterIndexer.checkQueryResult(result, opts, address);
              }

              // Build history list
              return NotificationListener(
                  child: Builder(
                    builder: (context) => Expanded(
                      child: ListView(
                        key: keyListTransactions,
                        controller: scrollController,
                        children: <Widget>[historyView(context, result)],
                      ),
                    ),
                  ),
                  onNotification: (dynamic t) {
                    if (t is ScrollEndNotification &&
                        scrollController.position.pixels >=
                            scrollController.position.maxScrollExtent * 0.7 &&
                        duniterIndexer.pageInfo!['hasNextPage'] &&
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
    DuniterIndexer duniterIndexer =
        Provider.of<DuniterIndexer>(context, listen: false);

    return duniterIndexer.transBC == null
        ? Column(children: <Widget>[
            const SizedBox(height: 50),
            Text(
              "noTransactionToDisplay".tr(),
              style: const TextStyle(fontSize: 18),
            )
          ])
        : Column(children: <Widget>[
            getTransactionTile(context, duniterIndexer),
            if (result.isLoading && duniterIndexer.pageInfo!['hasPreviousPage'])
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const <Widget>[
                  CircularProgressIndicator(),
                ],
              ),
            if (!duniterIndexer.pageInfo!['hasNextPage'])
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
      BuildContext context, DuniterIndexer duniterIndexer) {
    CesiumPlusProvider cesiumPlusProvider =
        Provider.of<CesiumPlusProvider>(context, listen: false);
    SubstrateSdk sub = Provider.of<SubstrateSdk>(context, listen: false);

    int keyID = 0;
    String? dateDelimiter;
    String? lastDateDelimiter;
    const double avatarSize = 200;

    bool isTody = false;
    bool isYesterday = false;
    bool isThisWeek = false;

    final Map<int, String> monthsInYear = {
      1: "month1".tr(),
      2: "month2".tr(),
      3: "month3".tr(),
      4: "month4".tr(),
      5: "month5".tr(),
      6: "month6".tr(),
      7: "month7".tr(),
      8: "month8".tr(),
      9: "month9".tr(),
      10: "month10".tr(),
      11: "month11".tr(),
      12: "month12".tr()
    };

    return Column(
        children: duniterIndexer.transBC!.map((repository) {
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
        dateDelimiter = lastDateDelimiter = "today".tr();
        isTody = true;
      } else if (transactionDate == yesterdayDate && !isYesterday) {
        dateDelimiter = lastDateDelimiter = "yesterday".tr();
        isYesterday = true;
      } else if (weekNumber(date) == weekNumber(now) &&
          date.year == now.year &&
          lastDateDelimiter != "thisWeek".tr() &&
          transactionDate != yesterdayDate &&
          transactionDate != todayDate &&
          !isThisWeek) {
        dateDelimiter = lastDateDelimiter = "thisWeek".tr();
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

      final bool isUdUnit = configBox.get('isUdUnit') ?? false;
      late double amount;
      late String finalAmount;
      amount = repository[4] == 'RECEIVED' ? repository[3] : repository[3] * -1;

      if (isUdUnit) {
        amount = round(amount / balanceRatio);
        finalAmount = 'ud'.tr(args: ['$amount ']);
      } else {
        finalAmount = '$amount $currencyName';
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
                  key: keyTransaction(keyID++),
                  contentPadding: const EdgeInsets.only(
                      left: 20, right: 30, top: 15, bottom: 15),
                  leading: ClipOval(
                    child: cesiumPlusProvider.defaultAvatar(avatarSize),
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
                  trailing: Text(finalAmount,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.justify),
                  dense: false,
                  isThreeLine: false,
                  onTap: () {
                    duniterIndexer.nPage = 1;
                    // _cesiumPlusProvider.avatarCancelToken.cancel('cancelled');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) {
                        return WalletViewScreen(address: repository[1]);
                      }),
                    );
                    // Navigator.pop(context);
                  }),
        ),
      ]);
    }).toList());
  }
}
